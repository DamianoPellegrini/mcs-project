#include <iostream>
#include <fstream>
#include <chrono>
#include <fast_matrix_market/app/Eigen.hpp>
#include <Eigen/SparseCore>
#include <filesystem>
// #include <Eigen/SparseCholesky>
#include <Eigen/CholmodSupport>
#ifdef EIGEN_USE_MKL_ALL
#include <mkl.h>
#endif

typedef Eigen::SparseMatrix<double, Eigen::ColMajor, SuiteSparse_long> SparseMatrix;
//typedef Eigen::SparseMatrix<double> SparseMatrix;

constexpr auto HEADER_CSV = "timestamp,matrixname,rows,cols,nonZeros,loadTime,loadMem,decompTime,decompMem,solveTime,solveMem,error"; 
constexpr auto OUT_FILE = "bench.csv";

using namespace std::string_view_literals;

int solveMatrixMarket(const std::filesystem::path& path);

int main(int argc, char* argv[], char** envp) {

#ifdef EIGEN_VECTORIZE
  std::cerr << "Eigen CPU vectorization is enabled." << std::endl;
#endif
  std::cerr << "Eigen Num of Threads: " << Eigen::nbThreads() << std::endl;
#ifdef EIGEN_USE_MKL_ALL
  std::cerr << "MKL max threads: " << mkl_get_max_threads() << std::endl;
#endif

  const std::filesystem::path matrices_dir = "matrices";

  // Loop through all files in the directory
  for (const auto& entry : std::filesystem::directory_iterator(matrices_dir)) {
    if (entry.is_regular_file() && entry.path().extension() == ".mtx") {
      const auto matrixName { entry.path().stem().string() };
      
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

  csv_file << std::format("{}, {}, {}, {}, {}, ", timestamp, path.stem().string(), A.rows(), A.cols(), A.nonZeros());

  const auto loadTime = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  const auto loadMem = 0;

  std::cerr << std::format("Matrix read took {} ms and {} bytes", loadTime, loadMem) << std::endl;
  csv_file << std::format("{}, {}, ", loadTime, loadMem);

  Eigen::CholmodDecomposition<SparseMatrix> solver;

  // Make sure the matrix is in compressed column form
  //A.makeCompressed();

  std::cerr << std::format("Decomposing matrix...") << std::endl;
  start = std::chrono::high_resolution_clock::now();
  solver.compute(A);
  end = std::chrono::high_resolution_clock::now();
  
  if (solver.info() != Eigen::Success) {
    std::cerr << "Decomposition failed." << std::endl;
    csv_file << std::format("{}, {}, {}", "N/A", "N/A", "Decomposition failed.") << std::endl;
    csv_file.close();
    return -1;
  }

  const auto decompTime = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  const auto decompMem = solver.cholmod().memory_usage;
  
  std::cerr << std::format("Decomposition succeeded with in {} ms", decompTime) << std::endl;
  csv_file << std::format("{}, {}, ", decompTime, decompMem);  

  Eigen::VectorXd b(A.rows()), x(A.rows()), xe(A.rows());
  x.setOnes();
  b = A * x;

  std::cerr << std::format("Solving matrix...") << std::endl;
  start = std::chrono::high_resolution_clock::now();
  xe = solver.solve(b);
  end = std::chrono::high_resolution_clock::now();

  const auto solveTime = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  const auto solveMem = 0;

  std::cerr << std::format("Solve took {} ms and {} bytes", solveTime, solveMem) << std::endl;
  csv_file << std::format("{}, {}, ", solveTime, solveMem);

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
