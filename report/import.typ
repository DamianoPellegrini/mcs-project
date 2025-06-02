#let matlab_win_csv_file = (
  csv("../matlab/bench_win64.csv", row-type: dictionary)
    .filter(m => m.exception == "")
    .sorted(key: mat => int(mat.nonZeros))
)

#let matlab_linux_csv_file = csv("../matlab/bench_glnxa64.csv", row-type: dictionary).sorted(
  key: mat => int(mat.nonZeros),
)

#let cpp_csv_file = csv("../bench.csv", row-type: dictionary).sorted(key: mat => int(mat.nonZeros))

#let matrices_matlab = matlab_linux_csv_file.map(m => m.matrixName)

#let matrices_cpp = cpp_csv_file.map(m => m.matrixName).dedup()

#import "packages.typ": cetz

#let make-rainbow-color(lightness: 80%, chroma: 60%, division: 1, offset: 0deg) = {
  assert(division > 0, message: "division must be positive")
  range(0, division).map(i => oklch(lightness, chroma, (360deg * i / division) + offset))
}

// #{
//   let test = make-rainbow-color(lightness: 80%, chroma: 100%,  division: 3, offset: 30deg).zip(make-rainbow-color(division: 3, offset: 50deg), make-rainbow-color(lightness: 70%, chroma: 40%, division: 3, offset: 70deg)).flatten()

//   for color in test {
//     box(fill: color, width: 10pt, height: 10pt)
//   }
// }

#let cetz-color-palette = cetz.palette.new(
  // colors: (
  //   oklch(47%, 70%, 260.96deg),
  //   oklch(60%, 40%, 270deg),
  //   oklch(100%, 100%, 30deg),
  //   oklch(80%, 40%, 30deg),
  //   oklch(87%, 0.33, 140deg),
  //   oklch(75%, .1455, 140deg),
  // ),
  colors: make-rainbow-color(chroma: 100%, lightness: 80%, division: 3, offset: 30deg)
    .zip(make-rainbow-color(division: 3, offset: 40deg))
    .flatten(),
)

#let cetz-color-palette-8 = cetz.palette.new(
  // colors: (
  //   oklch(47%, 70%, 260.96deg),
  //   oklch(60%, 40%, 270deg),
  //   oklch(100%, 100%, 30deg),
  //   oklch(80%, 40%, 30deg),
  //   oklch(87%, 0.33, 140deg),
  //   oklch(75%, .1455, 140deg),
  //   oklch(74.05%, 0.167, 63.8deg),
  //   oklch(64%, 0.087, 63.8deg),
  // ),
  colors: make-rainbow-color(chroma: 100%, lightness: 80%, division: 4, offset: 30deg)
    .zip(make-rainbow-color(division: 4, offset: 50deg))
    .flatten(),
)

#let cetz-color-palette-9 = cetz.palette.new(
  // colors: (
  //   oklch(47%, 70%, 260.96deg),
  //   oklch(60%, 40%, 270deg),
  //   oklch(80%, 60%, 280deg),
  //   oklch(100%, 100%, 30deg),
  //   oklch(80%, 40%, 30deg),
  //   oklch(80%, 40%, 60deg),
  //   oklch(87%, 0.33, 140deg),
  //   oklch(75%, .14, 140deg),
  //   oklch(75%, 0.14, 170deg),
  // ),
  colors: make-rainbow-color(lightness: 80%, chroma: 100%, division: 3, offset: 30deg)
    .zip(
      make-rainbow-color(division: 3, offset: 50deg),
      make-rainbow-color(lightness: 70%, chroma: 40%, division: 3, offset: 70deg),
    )
    .flatten(),
  // colors: make-rainbow-color(lightness: 70%, chroma: 70%, division: 9, offset: 190deg)
)
