#import "../import.typ": matlab_linux_csv_file, matlab_win_csv_file, cpp_csv_file

#import "../packages.typ": unit, cetz, cetz-plot

// Function to load and filter C++ data
#let load_cpp_data(data, matrix_name: none, blas: none, os: none) = {
  // Filter based on provided parameters
  let filtered = data.filter(row => {
    let match = true
    if matrix_name != none { match = match and row.matrix == matrix_name }
    if blas != none { match = match and row.blas == blas }
    if os != none { match = match and row.os == os }
    return match
  })

  return filtered
}

// Function to load MATLAB data for a specific OS
#let load_matlab_data(os: "windows") = {
  let filename = "data/matlab_" + os + "_memory.csv"
  return csv(filename)
}

// Function to format bytes to MB for display
#let format_bytes_to_mb(bytes) = {
  let size = int(bytes)
  let mb = calc.round(size / 1048576, digits: 2) // 1 MB = 1024 * 1024 bytes
  mb
}

= Risultati

== Specifiche del sistema

Specifiche del sistema per Windows:

- *Processore*: Intel(R) Core(TM) i7-7700HQ CPU \@ 2.80GHz 2.81 GHz
- *Architettura*: Sistema operativo a 64 bit, processore basato su x64
- *RAM installata*: 16 GB
- *Archiviazione*: 238 GB SSD e 1 TB HDD Esterno
- *Scheda grafica*: NVIDIA GeForce GTX 1060 with Max-Q Design (6 GB)
- *Memoria Virtuale*: 7680 MB su SSD e 32768 MB su HDD Esterno
- *Sistema operativo Windows*: Windows 10 Home

Specifiche del sistema per Linux:

Processore, Architettura, RAM, Archiviazione e Scheda Grafica sono gli stessi del sistema Windows.

- *Memoria Virtuale*: 40448 MB su HDD Esterno
- *Sistema operativo Linux*: WSL 2 con Ubuntu 25.04

La memoria virtuale era possibili averla solo su un solo disco, quindi è stata scelta (per mancanza di spazio) quella dell'HDD esterno.

Specifiche del sistema per MacOS:

- *Processore*: Apple M1 Pro
- *Architettura*: ARM64
- *RAM installata*: 16 GB
- *Archiviazione*: 512 GB SSD
- *Scheda grafica*: Apple M1 Pro GPU (16 core)
- *Memoria Virtuale*: 7680 MB su SSD
- *Sistema operativo*: MacOS Ventura 13.4

== Matrici analizzate

Ordinate in base alla dimensione, le matrici analizzate sono:

#let matrices = (
  matlab_win_csv_file
    .map(m => (
      m.matrixName,
    ))
    .flatten()
)

#let rows = (
  "1564794",
  "1585478",
  "1465137",
  "715176",
  "70656",
  "123440",
  "6867",
  "525825",
  "81920",
)

#let nonZeros = (
  "114165372",
  "7660826",
  "21005389",
  "4817870",
  "1825580",
  "3085406",
  "98671",
  "3674625",
  "327680",
)

// Combine the data into a list of dictionaries for sorting
#let combined_data = ()
#for i in range(matrices.len()) {
  combined_data.push((
    matrixName: matrices.at(i),
    rows: rows.at(i),
    nonZeros: int(nonZeros.at(i)), // Convert to int for numerical sorting
  ))
}

// Sort the data by nonZeros (descending)
#let sorted_data = combined_data.sorted(key: m => -m.nonZeros)


#table(
  columns: (auto, auto, auto),
  table.header[*Matrix Name*][*Righe & Colonne*][*Valori non zero*],
  ..sorted_data
    .map(m => (
      [#m.matrixName],
      [#m.rows],
      [#m.nonZeros],
    ))
    .flatten()
)

Tutte queste matrici sono sparse, simmetriche e positive definite.
Sono state scaricate dal repository #link("https://sparse.tamu.edu/").

== Risultati MATLAB

=== Considerazioni Comuni

#figure(
  caption: [Confronto utilizzo memoria tra sistemi operativi su MATLAB],
  table(
  columns: 7,
  align: center,
  table.header(
    repeat: true,
    table.cell(rowspan: 2, align: center + horizon, [*Matrix*]),
    table.cell(colspan: 3, [*Windows*]),
    table.cell(colspan: 3, [*Linux*]),
    [*loadMem*],
    [*decompMem*],
    [*solveMem*],
    [*loadMem*],
    [*decompMem*],
    [*solveMem*],
  ),
  ..matlab_win_csv_file
    .zip(matlab_linux_csv_file)
    .map(((win, lnx)) => {
      return (
        win.matrixName,
        [#format_bytes_to_mb(int(win.loadMem))],
        [#format_bytes_to_mb(int(win.decompMem))],
        [#format_bytes_to_mb(int(win.solveMem))],
        [#format_bytes_to_mb(int(lnx.loadMem))],
        [#format_bytes_to_mb(int(lnx.decompMem))],
        [#format_bytes_to_mb(int(lnx.solveMem))],
      )
    })
    .flatten()
)
)

=== Windows

Durante l'esecuzione due matrici hanno causato un errore interno della libreria di CHOLMOD, quindi non sono state incluse nei risultati. Le matrici che hanno causato l'errore sono:
- Flan_1565
- StocF-1465

#let data2 = (
  ([15-24], 18.0, 20.1, 23.0, 17.0),
  ([25-29], 16.3, 17.6, 19.4, 15.3),
  ([30-34], 14.0, 15.3, 13.9, 18.7),
  ([35-44], 35.5, 26.5, 29.4, 25.8),
  ([45-54], 25.0, 20.6, 22.4, 22.0),
  ([55+], 19.9, 18.2, 19.2, 16.4),
)

#cetz.canvas({
  import cetz.draw: *
  import cetz-plot.chart: *
  set-style(legend: (fill: white), barchart: (bar-width: .8, cluster-gap: 0))
  barchart(
    data2,
    mode: "clustered",
    size: (9, auto),
    label-key: 0,
    value-key: (..range(1, 5),),
    x-tick-step: 2.5,
    labels: ([Low], [Medium], [High], [Very high]),
    legend: "inner-north-east",
  )
})

=== Linux

Durante l'esecuzione due matrici hanno causato il kill del processo MATLAB, quindi non sono state incluse nei risultati. Le matrici che hanno causato il crash sono:
- Flan_1565
- StocF-1465

// Figure conversions skipped as requested

== Risultati C++

=== Considerazioni Comuni

La memoria è la stessa tra i tre sistemi operativi, quindi non è necessario ripeterla per ogni sistema operativo.

#let cpp_memory = load_cpp_data(cpp_csv_file, blas: "OpenBLAS", os: "Linux")

#table(
  columns: (auto, auto, auto, auto),
  table.header[*Matrix Name*][*Load Memory (MB)*][*Decomp Memory (MB)*][*Solve Memory (MB)*],
  ..cpp_memory
    .map(m => (
      [#m.matrixName],
      [#format_bytes_to_mb(int(m.loadMem))],
      [#format_bytes_to_mb(int(m.decompMem))],
      [#format_bytes_to_mb(int(m.solveMem))],
    ))
    .flatten()
)

=== Windows

// Figure conversions skipped as requested

=== Linux

// Figure conversions skipped as requested

=== MacOS

// Figure conversions skipped as requested

=== Riepilogo dei risultati

// Figure conversions skipped as requested
