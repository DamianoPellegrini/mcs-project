#let matlab_win_csv_file = csv("../matlab/bench_win64.csv", row-type: dictionary).filter(m => m.exception == "").sorted(key: (mat) => int(mat.nonZeros))

#let matlab_linux_csv_file = csv("../matlab/bench_glnxa64.csv", row-type: dictionary).sorted(key: (mat) => int(mat.nonZeros))

#let cpp_csv_file = csv("../bench.csv", row-type: dictionary).sorted(key: (mat) => int(mat.nonZeros))

#let matrices_matlab = matlab_linux_csv_file.map(m => m.matrixName)

#let matrices_cpp = cpp_csv_file.map(m => m.matrixName).dedup()

#import "packages.typ": cetz

#let cetz-color-palette = cetz.palette.new(colors: (
  oklch(47%, 0.2904, 260.96deg),
  oklch(60%, 40%, 270deg),
  oklch(100%, 100%, 30deg),
  oklch(80%, 40%, 30deg),
  oklch(87%, 0.33, 140deg),
  oklch(75%, .1455, 140deg),
))

#let cetz-color-palette-8 = cetz.palette.new(colors: (
  oklch(47%, 0.2904, 260.96deg),
  oklch(60%, 40%, 270deg),
  oklch(100%, 100%, 30deg),
  oklch(80%, 40%, 30deg),
  oklch(87%, 0.33, 140deg),
  oklch(75%, .1455, 140deg),
  oklch(74.05%, 0.167, 63.8deg),
  oklch(33.58%, 0.071, 69.02deg),
))

#let cetz-color-palette-9 = cetz.palette.new(colors: (
  oklch(47%, 0.2904, 260.96deg),
  oklch(60%, 40%, 270deg),
  oklch(80%, 60%, 280deg),
  oklch(100%, 100%, 30deg),
  oklch(80%, 40%, 30deg),
  oklch(60%, 20%, 30deg),
  oklch(87%, 0.33, 140deg),
  oklch(75%, .1455, 140deg),
  oklch(55%, 0.14, 140deg),
))
