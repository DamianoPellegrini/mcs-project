// This Typst file contains macros for generating a report with various calculations and formatting.

// #import "utils/plotmacros.typ": *

#import "packages.typ": unify

// Function to load and filter C++ data
#let filter_by_os_blas(data, matrix_name: none, blas: none, os: none) = {
  assert(type(data) == array, message: "Data must be an array")

  return data.filter(row => (
    (matrix_name == none or matrix_name == row.matrix)
      and (blas == none or blas == row.blas)
      and (os == none or os == row.os)
  ))
}

// Function to calculate the logarithm of a number
#let log10 = x => {
  if float(x) in (0, 0.0) {
    return 0
  }
  calc.log(float(x))
}

// Function to format bytes to MB for display
#let format_bytes_to_mb(bytes) = {
  calc.round(float(bytes) / 1048576, digits: 2) // 1 MB = 1024 * 1024 bytes
}

// Function to format a number in scientific notation
#let format-scientific = x => {
  let exponent = calc.floor(log10(calc.abs(x)))
  let mantissa = calc.round(x / (calc.pow(10, exponent)), digits: 2)
  if (exponent == 0) {
    return unify.num(mantissa)
  }
  str(mantissa) + "e" + str(exponent)
}

// Enum used to access these values from CSV
#let csv_keys = (
  allTime: "allTime",
  allNoLoadTime: "allTimeNoLoad",
  loadTime: "loadTime",
  decompTime: "decompTime",
  solveTime: "solveTime",
  allMem: "allMem",
  allNoLoadMem: "allNoLoadMem",
  loadMem: "loadMem",
  decompMem: "decompMem",
  solveMem: "solveMem",
  relErr: "relativeError",
)

// Label for plots based on CSV enum values
#let ylabels = (
  allTime: [Tempo complessivo (caricamento + decomposizione + risoluzione) \[$log_(10)(s)$\]],
  allTimeNoLoad: [Tempo complessivo (decomposizione + risoluzione) \[$log_(10)(s)$\]],
  loadTime: [Tempo di caricamento \[$log_(10)(s)$\]],
  decompTime: [Tempo di decomposizione \[$log_(10)(s)$\]],
  solveTime: [Tempo di risoluzione \[$log_(10)(s)$\]],
  allMem: [Memoria totale (caricamento + decomposizione + risoluzione) \[$log_(10)("MB")$\]],
  allNoLoadMem: [Memoria totale (decomposizione + risoluzione) \[$log_(10)("MB")$\]],
  loadMem: [Memoria di caricamento \[$log_(10)("MB")$\]],
  decompMem: [Memoria di decomposizione \[$log_(10)("MB")$\]],
  solveMem: [Memoria di risoluzione \[$log_(10)("MB")$\]],
  relativeError: [Errore relativo ($log_10$)],
)

// Data extractor functions from dicts based on CSV enum values
#let dictExtractorCSV = (
  allTime: dict => log10((float(dict.loadTime) + float(dict.decompTime) + float(dict.solveTime)) / 1000),
  allTimeNoLoad: dict => log10((float(dict.decompTime) + float(dict.solveTime)) / 1000),
  loadTime: dict => log10(float(dict.loadTime) / 1000),
  decompTime: dict => log10(float(dict.decompTime) / 1000),
  solveTime: dict => log10(float(dict.solveTime) / 1000),
  allMem: dict => log10(format_bytes_to_mb(int(dict.loadMem) + int(dict.decompMem) + int(dict.solveMem))),
  allNoLoadMem: dict => log10(format_bytes_to_mb(int(dict.decompMem) + int(dict.solveMem))),
  loadMem: dict => log10(format_bytes_to_mb(dict.loadMem)),
  decompMem: dict => log10(format_bytes_to_mb(dict.decompMem)),
  solveMem: dict => log10(format_bytes_to_mb(dict.solveMem)),
  relativeError: dict => log10(float(dict.relativeError)),
)

// Function to retrieve a value from a dictionary based on a CSV enum value
#let getValFromDictCSV = (dict, key) => {
  assert(key in dictExtractorCSV, message: ("Invalid key in getValFromDictCSV:", key).join(" "))
  let extractor = dictExtractorCSV.at(key)
  extractor(dict)
}

#let createMatricesLinePlot(
  key,
  matrices,
  data,
  min,
  max,
  sizeX: 14,
  sizeY: 8,
  line-padding: 0.5,
  plotStyle: none,
  markStyle: none,
  legend: "inner-south-east",
  anchor: "south-east",
  anchorOffset: (0, 0.75em),
  customLabel: none,
) = {
  import "packages.typ": cetz-plot, cetz
  import cetz-plot: plot
  import "import.typ": cetz-color-palette

  if plotStyle == none {
    plotStyle = cetz-color-palette.with(stroke: true)
  }

  if markStyle == none {
    markStyle = cetz-color-palette.with(stroke: true, fill: true)
  }

  let min = calc.floor(min)
  let max = calc.ceil(max)

  let ylabel = if customLabel != none {
    customLabel
  } else {
    assert(
      key in ylabels,
      message: ("Invalid key in createMatricesLinePlot:", key, "and customlabel not set").join(" "),
    )
    ylabels.at(key)
  }

  return cetz.canvas({
    import cetz.draw: set-style, translate, scale, content
    set-style(
      legend: (fill: white.transparentize(15%), anchor: anchor, offset: anchorOffset),
      axes: (
        x: (
          tick: (label: (angle: 45deg, offset: 1.25em, anchor: "east")),
          grid: (stoke: 1pt + black.transparentize(90%)),
        ),
        y: (
          label: (angle: 90deg, anchor: "east", offset: 3.5em),
          grid: (stoke: 1pt + black.transparentize(99%)),
        ),
      ),
    )
    plot.plot(
      size: (sizeX, sizeY),
      plot-style: plotStyle,
      mark-style: markStyle,
      legend: legend,
      x-label: none,
      y-label: ylabel,
      y-max: max + line-padding,
      y-min: min - line-padding,
      y-tick-step: none,
      y-ticks: range(min, max + 1).map(i => (i, $10^#i$)),
      x-min: -1,
      x-max: matrices.len(),
      x-tick-step: none,
      x-ticks: matrices.enumerate().map(((idx, name)) => (idx, name)),
      axis-style: "left",
      x-grid: true,
      y-grid: true,
      {
        for (label, values) in data {
          plot.add(values.enumerate(), mark: "o", label: label)
        }
      },
    )
  })
}
