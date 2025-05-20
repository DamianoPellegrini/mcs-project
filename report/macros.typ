// This Typst file contains macros for generating a report with various calculations and formatting.

// #import "utils/plotmacros.typ": *

#import "packages.typ": unify

// Function to load and filter C++ data
#let filter_by_os_blas(data, matrix_name: none, blas: none, os: none) = {
  assert(type(data) == array, message: "Data must be an array")

  return data.filter(row => ((matrix_name == none or matrix_name == row.matrix)
    and (blas == none or blas == row.blas)
    and (os == none or os == row.os)))
}

// Function to calculate the logarithm of a number
#let log10 = x => {
  if x == 0 {
    return 0
  }
  calc.log(float(x))
}

// Function to format bytes to MB for display
#let format_bytes_to_mb(bytes) = {
  calc.round(int(bytes) / 1048576, digits: 2) // 1 MB = 1024 * 1024 bytes
}

// Function to format a number in scientific notation
#let format-scientific = x => {
  let exponent = calc.floor(log10(calc.abs(x)))
  let mantissa = calc.round(x / (calc.pow(10,exponent)), digits: 2)
  if (exponent == 0) {
    return unify.num(mantissa)
  }
  unify.num(str(mantissa) + "e" + str(exponent))
}

#let csv_keys = (
  allTime: "allTime",
  allNoLoadTime: "allTimeNoLoad",
  loadTime: "loadTime",
  decompTime: "decompTime",
  solveTime: "solveTime",
  relErr: "relativeError",
)

// Function to retrieve a value from a dictionary based on a key
#let getValFromDictCSV = (dict, key) => {
    let val = if key == csv_keys.allTime {
      log10((float(dict.loadTime) + float(dict.decompTime) + float(dict.solveTime)) / 1000)
    } else if key == csv_keys.allNoLoadTime {
      log10((float(dict.decompTime) + float(dict.solveTime)) / 1000)
    } else if key == csv_keys.loadTime {
      log10(float(dict.loadTime) / 1000)
    } else if key == csv_keys.decompTime{
      log10(float(dict.decompTime) / 1000)
    } else if key == csv_keys.solveTime {
      log10(float(dict.solveTime) / 1000)
    } else if key == csv_keys.relErr {
      log10(float(dict.relativeError))
    } else {
      assert(false, message: "Invalid key in getValFromDictCSV: " + key)
    }
    return val
}


#let createMatricesLinePlot(
    key,
    matrices,
    data,
    min,
    max,
    sizeX: 14,
    sizeY: 9,
    line-padding: 0.5,
    plotStyle: none,
    markStyle: none,
  ) = {
  import "packages.typ": cetz-plot, cetz
  import cetz-plot: *
  import "import.typ": cetz-color-palette

  if plotStyle == none {
    plotStyle = cetz-color-palette.with(stroke: true)
  }

  if markStyle == none {
    markStyle = cetz-color-palette.with(stroke: true, fill: true)
  }

  let min = calc.floor(min)
  let max = calc.ceil(max)

  let ylabel = if key == csv_keys.allTime {
    [Tempo complessivo (caricamento + decomposizione + risoluzione) \[$log_(10)(s)$\]]
  } else if key == csv_keys.allNoLoadTime {
    [Tempo complessivo (decomposizione + risoluzione) \[$log_(10)(s)$\]]
  } else if key == csv_keys.loadTime {
    [Tempo di caricamento \[$log_(10)(s)$\]]
  } else if key == csv_keys.decompTime {
    [Tempo di decomposizione \[$log_(10)(s)$\]]
  } else if key == csv_keys.solveTime {
    [Tempo di risoluzione \[$log_(10)(s)$\]]
  } else if key == csv_keys.relErr {
    [Errore relativo ($log_10$)]
  }

  return cetz.canvas({
    import cetz.draw: set-style, translate, scale, content
    import cetz.draw: set-style, translate, scale, content
    set-style(
      legend: (fill: white, anchor: "north-west"),
      axes: (
        x: (
          tick: (label: (angle: 45deg, offset: 1.25em, anchor: "east")),
          label: (anchor: "east", offset: 7em),
          label-anchor: "mid",
        ),
        y: (
          label: (angle: 90deg, anchor: "south-east", offset: 2.5em),
        ),
      ),
    )
    plot.plot(
      size: (sizeX, sizeY),
      plot-style: plotStyle,
      mark-style: markStyle,
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
      {
        plot.add-vline(..range(0, matrices.len()), style: (stroke: (paint: black.transparentize(90%))))
        plot.add-hline(..range(min + 1, max), style: (stroke: (paint: black.transparentize(90%))))

        for (label, values) in data {
          plot.add(values.enumerate(), mark: "o", label: label)
        }
      },
    )
  })
}
