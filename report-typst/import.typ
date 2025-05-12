#let matlab_win_csv_file = csv("../matlab/bench_win64.csv", row-type: dictionary).filter(m => m.rows != "0")

#let matlab_linux_csv_file = csv("../matlab/bench_glnxa64.csv", row-type: dictionary)

#let cpp_csv_file = csv("../bench.csv", row-type: dictionary)
