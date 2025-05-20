#include <iostream>
#include <fstream>
#include <chrono>
#include <thread>
#include <fast_matrix_market/app/Eigen.hpp>
#include <Eigen/SparseCore>
#include <filesystem>
#include <format>
#include <Eigen/CholmodSupport>
#ifdef EIGEN_USE_MKL_ALL
#include <mkl.h>
#endif
#ifdef OPEN_BLAS
#include <cblas.h>
#endif
#ifdef USING_ACCEL
#include <Accelerate/Accelerate.h>
#endif

typedef Eigen::SparseMatrix<double, Eigen::ColMajor, int64_t> SparseMatrix;

#ifdef EIGEN_USE_MKL_ALL
constexpr auto BLAS = "MKL";
#elif defined(OPEN_BLAS)
constexpr auto BLAS = "OpenBLAS";
#elif defined(USING_ACCEL)
constexpr auto BLAS = "Accelerate";
#else
constexpr auto BLAS = "Unknown";
#endif

constexpr auto HEADER_CSV = "os,blas,numThreads,timestamp,matrixName,rows,cols,nonZeros,loadTime,loadMem,decompTime,decompMem,decompPeakMem,solveTime,solveMem,solvePeakMem,relativeError"; 
constexpr auto OUT_FILE = "bench.csv";

#ifndef NO_SLEEP
constexpr std::chrono::seconds SLEEP_TIME{5};
#endif

const std::string getOSName();

const int getNumThreads();

int solveMatrixMarket(const std::filesystem::path& path);

int main(int argc, char* argv[], char** envp) {

#ifdef EIGEN_VECTORIZE
  std::cerr << "Eigen CPU vectorization is enabled." << std::endl;
#endif
  std::cerr << BLAS << " Num of threads: " << getNumThreads() << std::endl;

  const std::filesystem::path matrices_dir = (argc > 1) ? argv[1] : "matrices";

  // Check if directory exists before iterating
  if (!std::filesystem::exists(matrices_dir) || !std::filesystem::is_directory(matrices_dir)) {
      std::cerr << "Error: Directory '" << matrices_dir.string() << "' does not exist or is not a directory." << std::endl;
      return 1;
  }

  // Loop through all files in the directory
  for (const auto& entry : std::filesystem::directory_iterator(matrices_dir)) {
    if (entry.is_regular_file() && entry.path().extension() == ".mtx") {
      const auto matrixName { entry.path().stem().string() };

      // Sleep for 10 seconds before processing the next file
      #ifndef NO_SLEEP
      std::cerr << std::format("Sleeping for {} seconds...", SLEEP_TIME) << std::endl;
      std::this_thread::sleep_for(SLEEP_TIME);
      #endif

      int result = solveMatrixMarket(entry.path());
      if (result == 0) {
        std::cerr << "Processed " << matrixName << std::endl;
      } else {
        std::cerr << "Error " << matrixName << std::endl;
      }
    }
  }

  return 0;
}

const std::string getOSName() {
  #if defined(_WIN32)
      return "Windows";
  #elif defined(__APPLE__)
      return "macOS";
  #elif defined(__linux__)
      return "Linux";
  #elif defined(__unix__)
      return "Unix";
  #else
      return "Unknown";
  #endif
}

const int getNumThreads() {
  #ifdef EIGEN_USE_MKL_ALL
    return mkl_get_max_threads();
  #elif defined(OPEN_BLAS)
    return openblas_get_num_threads();
  #elif defined(USING_ACCEL)
    return BLASGetThreading() == BLAS_THREADING_SINGLE_THREADED ? 1 : -1;
  #else
    return -1;
  #endif
}

int solveMatrixMarket(const std::filesystem::path& path) {
  const auto timestamp = std::chrono::system_clock::now();

  std::cerr << std::format("{} - Processing {}...", timestamp, path.stem().string()) << std::endl;

  std::ifstream matrix_file(path, std::ios::in);
  std::ofstream csv_file(OUT_FILE, std::ios::ate | std::ios::app);

  if (std::filesystem::is_empty(OUT_FILE)) {
    std::cerr << std::format("Writing headers to {}...", OUT_FILE) << std::endl;
    csv_file << HEADER_CSV << std::endl;
    csv_file.flush();
  }

  SparseMatrix A;

  std::cerr << std::format("Reading matrix...") << std::endl;

  auto start{ std::chrono::high_resolution_clock::now() };
  fast_matrix_market::read_matrix_market_eigen(matrix_file, A);
  auto end{ std::chrono::high_resolution_clock::now() };
  matrix_file.close();

  csv_file << std::format("{},{},{},{},{},{},{},{},", getOSName(), BLAS, getNumThreads(), timestamp, path.stem().string(), A.rows(), A.cols(), A.nonZeros());

  const size_t valuesSize = A.nonZeros() * sizeof(double);
    
  // Size of inner indices array (nonzeros * sizeof(index type))
  const size_t innerIndicesSize = A.nonZeros() * sizeof(SuiteSparse_long);
  
  // Size of outer indices array ((outerSize+1) * sizeof(index type))
  const size_t outerIndicesSize = (A.outerSize() + 1) * sizeof(SuiteSparse_long);

  const auto loadTime = std::chrono::duration_cast<std::chrono::duration<long double, std::milli>>(end - start).count();
  const auto loadMem = valuesSize + innerIndicesSize + outerIndicesSize;

  std::cerr << std::format("Matrix read took {} ms and {} bytes", loadTime, loadMem) << std::endl;
  csv_file << std::format("{},{},", loadTime, loadMem);

  Eigen::CholmodDecomposition<SparseMatrix> solver;

  // Make sure the matrix is in compressed column form
  A.makeCompressed();

  solver.cholmod().memory_allocated = 0;
  solver.cholmod().memory_inuse = 0;
  solver.cholmod().memory_usage = 0;
  std::cerr << std::format("Decomposing matrix...") << std::endl;
  start = std::chrono::high_resolution_clock::now();
  solver.compute(A);
  end = std::chrono::high_resolution_clock::now();
  
  if (solver.info() != Eigen::Success) {
    std::cerr << "Decomposition failed." << std::endl;
    csv_file << std::format("{},{},{},{}", "N/A", "N/A", "N/A", "Decomposition failed.") << std::endl;
    csv_file.close();
    return -1;
  }

  const auto decompTime = std::chrono::duration_cast<std::chrono::duration<long double, std::milli>>(end - start).count();
  const auto decompMem = solver.cholmod().memory_allocated;
  const auto decompPeakMem = solver.cholmod().memory_usage;
  
  std::cerr << std::format("Decomposition succeeded with in {} ms and {} bytes", decompTime, decompMem) << std::endl;
  csv_file << std::format("{},{},{},", decompTime, decompMem, decompPeakMem);  

  Eigen::VectorXd b(A.rows()), x(A.rows()), xe(A.rows());
  x.setOnes();
  b = A * x;

  solver.cholmod().memory_allocated = 0;
  solver.cholmod().memory_inuse = 0;
  solver.cholmod().memory_usage = 0;
  std::cerr << std::format("Solving matrix...") << std::endl;
  start = std::chrono::high_resolution_clock::now();
  xe = solver.solve(b);
  end = std::chrono::high_resolution_clock::now();

  const auto solveTime = std::chrono::duration_cast<std::chrono::duration<long double, std::milli>>(end - start).count();
  const auto solveMem = solver.cholmod().memory_allocated;
  const auto solvePeakMem = solver.cholmod().memory_usage;

  std::cerr << std::format("Solve took {} ms and {} bytes", solveTime, solveMem) << std::endl;
  csv_file << std::format("{},{},{},", solveTime, solveMem, solvePeakMem);

  if (solver.info() != Eigen::Success) {
    std::cerr << "Solving failed." << std::endl;
    csv_file << std::format("{}", "Solving failed.") << std::endl;
    csv_file.close();
    return -1;
  }

  // Valutazione dell'errore
  auto err = sqrt((x - xe).squaredNorm() / x.squaredNorm());
  csv_file << std::format("{}", err) << std::endl;

  std::cerr << std::format("Error: {}", err) << std::endl;

  csv_file.close();

  return 0;
}
