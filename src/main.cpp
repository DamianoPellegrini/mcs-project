#include <iostream>
#include <fstream>
#include <chrono>
#include <fast_matrix_market/app/Eigen.hpp>
#include <Eigen/SparseCore>
// #include <Eigen/SparseCholesky>
#include <Eigen/CholmodSupport>

constexpr auto HEADER_CSV = "timestamp,matrixname,rows,cols,nonZeros,loadTime,loadMem,decompTime,decompMem,solveTime,solveMem,error"; 
constexpr auto OUT_FILE = "bench.csv";

using namespace std::string_view_literals;

int solveMatrixMarket(const std::string_view&);

int main(int argc, char* argv[], char** envp) {

#ifdef EIGEN_VECTORIZE
  std::cerr << "Eigen CPU vectorization is enabled." << std::endl;
#endif

  return solveMatrixMarket("matrices/Flan_1565.mtx"sv);
}

int solveMatrixMarket(const std::string_view& path) {
  const auto timestamp = std::chrono::system_clock::now();

  std::ifstream matrix_file(path.data(), std::ios::in);
  std::ofstream csv_file(OUT_FILE, std::ios::ate | std::ios::app);

  if (std::filesystem::is_empty(OUT_FILE)) {
    std::cerr << std::format("Writing headers to {}...", OUT_FILE) << std::endl;
    csv_file << HEADER_CSV << std::endl;
    csv_file.flush();
  }

  Eigen::SparseMatrix<double> A;

  auto start{ std::chrono::high_resolution_clock::now() };
  fast_matrix_market::read_matrix_market_eigen(matrix_file, A);
  auto end{ std::chrono::high_resolution_clock::now() };
  matrix_file.close();

  csv_file << std::format("{},{},{},{},{},", timestamp, path, A.rows(), A.cols(), A.nonZeros());

  const auto loadTime = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  const auto loadMem = 0;

  csv_file << std::format("{}, {},", loadTime, loadMem);

  Eigen::CholmodSimplicialLLT<Eigen::SparseMatrix<double>> solver;

  start = std::chrono::high_resolution_clock::now();
  solver.compute(A);
  end = std::chrono::high_resolution_clock::now();

  const auto decompTime = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  const auto decompMem = 0;
  csv_file << std::format("{}, {},", decompTime, decompMem);

  if (solver.info() != Eigen::Success) {
    std::cerr << "Decomposition failed." << std::endl;
    csv_file << std::format("{}, {}, {}", "N/A", "N/A", "Decomposition failed.") << std::endl;
    csv_file.close();
    return -1;
  }

  Eigen::VectorXd b(A.rows()), x(A.rows()), xe(A.rows());
  x.setOnes();
  b = A * x;

  start = std::chrono::high_resolution_clock::now();
  xe = solver.solve(b);
  end = std::chrono::high_resolution_clock::now();

  const auto solveTime = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  const auto solveMem = 0;
  csv_file << std::format("{}, {},", solveTime, solveMem);

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
