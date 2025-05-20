#import "../import.typ": matlab_linux_csv_file, matlab_win_csv_file, cpp_csv_file, cetz-color-palette, cetz-color-palette-8

#import "../packages.typ": unify, cetz, cetz-plot

#import "../macros.typ": *

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

La memoria virtuale era possibile averla solo su un solo disco, quindi è stata scelta (per mancanza di spazio) quella dell'HDD esterno.

Specifiche del sistema per MacOS:

- *Processore*: Apple M1 Pro
- *Architettura*: ARM64 (10 core)
- *RAM installata*: 16 GB
- *Archiviazione*: 1 TB SSD
- *Scheda grafica*: Apple M1 Pro GPU (16 core)
- *Memoria Virtuale*: 56 GB su SSD
- *Sistema operativo*: MacOS Sonoma 15.4

== Matrici analizzate

Ordinate in base al numero di elementi non zero, le matrici analizzate sono:

#let cpp_memory = filter_by_os_blas(cpp_csv_file, blas: "OpenBLAS", os: "Linux")

#figure(
  caption: [Matrici analizzate],
  table(
    columns: (auto,) * 3,
    table.header[*Nome Matrice*][*Righe & Colonne*][*Valori non zero*],
    ..cpp_memory
      .map(m => (
        [#m.matrixName],
        [#m.rows],
        [#m.nonZeros],
      ))
      .flatten()
  ),
)

Tutte queste matrici sono sparse, simmetriche e positive definite.
Sono state scaricate dal repository #link("https://sparse.tamu.edu/").

== Considerazioni Iniziali

Dato che sia MATLAB che C++ utilizzano la stessa libreria CHOLMOD, ci si aspetta che i risultati siano simili. Tuttavia, potrebbero emergere delle differenze, soprattutto a causa della versione obsoleta di MATLAB, meno aggiornata rispetto a quella di C++. Inoltre, l'uso differente delle librerie BLAS potrebbe influenzare ulteriormente i risultati.

== Risultati MATLAB

#let plotMATLABMatrix(data, data2, key: none, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let matrices = () // matrixName: none
  let osValues = (:) // data: values

  osValues.insert("Windows", ())
  osValues.insert("Linux", ())

  for (win, lnx) in data.zip(data2) {
    matrices.push(win.matrixName)

    let valLnx = getValFromDictCSV(lnx, key)
    let valWin = getValFromDictCSV(win, key)

    min = calc.min(min, valWin, valLnx)
    max = calc.max(max, valWin, valLnx)

    osValues.at("Windows").push(valWin)
    osValues.at("Linux").push(valLnx)
  }

  createMatricesLinePlot(
    key,
    matrices,
    osValues,
    min,
    max,
  )
}

#let plotMATLABMemMatrix(data, data2, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let matrices = () // matrixName: none
  let osValues = (:) // data: values

  osValues.insert("Windows", ("loadMem": (), "decompMem": (), "solveMem": ()))
  osValues.insert("Linux", ("loadMem": (), "decompMem": (), "solveMem": ()))

  for (win, lnx) in data.zip(data2) {
    matrices.push(win.matrixName)

    let loadMemWin = log10(float(win.loadMem))
    let decompMemWin = log10(float(win.decompMem))
    let solveMemWin = log10(float(win.solveMem))
    let loadMemLnx = log10(float(lnx.loadMem))
    let decompMemLnx = log10(float(lnx.decompMem))
    let solveMemLnx = log10(float(lnx.solveMem))

    min = calc.min(min, loadMemWin, decompMemWin, solveMemWin, loadMemLnx, decompMemLnx, solveMemLnx)
    max = calc.max(max, loadMemWin, decompMemWin, solveMemWin, loadMemLnx, decompMemLnx, solveMemLnx)

    osValues.at("Windows").at("loadMem").push(loadMemWin)
    osValues.at("Windows").at("decompMem").push(decompMemWin)
    osValues.at("Windows").at("solveMem").push(solveMemWin)

    osValues.at("Linux").at("loadMem").push(loadMemLnx)
    osValues.at("Linux").at("decompMem").push(decompMemLnx)
    osValues.at("Linux").at("solveMem").push(solveMemLnx)
  }

  createMatricesLinePlot(
    csv_keys.allTime,
    matrices,
    osValues,
    min,
    max,
  )
}

Durante l'esecuzione, due matrici hanno causato un errore interno della libreria CHOLMOD in Windows, mentre in Linux hanno provocato la terminazione forzata del processo. Di conseguenza, non sono state incluse nei risultati. Le matrici problematiche sono:
- Flan_1565
- StocF-1465

=== Memoria

#figure(
  caption: [Confronto utilizzo memoria tra sistemi operativi su MATLAB],
  table(
    columns: (2fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: center,
    table.header(
      repeat: true,
      table.cell(rowspan: 2, align: center + horizon, [*Matrix*]),
      table.cell(colspan: 3, [*Uso Memoria Windows (MB)*]),
      table.cell(colspan: 3, [*Uso Memoria Linux (MB)*]),
      [*load*],
      [*decomp*],
      [*solve*],
      [*load*],
      [*decomp*],
      [*solve*],
    ),
    ..matlab_win_csv_file
      .zip(matlab_linux_csv_file)
      .map(((win, lnx)) => {
        return (
          win.matrixName,
          [#format_bytes_to_mb(win.loadMem)],
          [#format_bytes_to_mb(win.decompMem)],
          [#format_bytes_to_mb(win.solveMem)],
          [#format_bytes_to_mb(lnx.loadMem)],
          [#format_bytes_to_mb(lnx.decompMem)],
          [#format_bytes_to_mb(lnx.solveMem)],
        )
      })
      .flatten()
  ),
) <matlab_memory_usage>

Dalla tabella emerge chiaramente che il profiler di memoria di MATLAB potrebbe non essere completamente affidabile, poiché riporta valori pari a zero per il caricamento della matrice. Questo fenomeno è probabilmente dovuto al coinvolgimento della libreria esterna CHOLMOD, che MATLAB non traccia direttamente attraverso il suo profiler.

Di conseguenza, la memoria riportata sembra riflettere solo quella utilizzata da MATLAB durante la chiamata alla libreria esterna, senza considerare la memoria effettivamente impiegata per l'operazione in sé.

=== Tempi

#let data = {
  matlab_win_csv_file
    .zip(matlab_linux_csv_file)
    .sorted(key: ((win, lnx)) => int(win.nonZeros))
    .map(((win, lnx)) => (
      win.matrixName,
      log10(win.loadTime),
      log10(lnx.loadTime),
      log10(win.decompTime),
      log10(lnx.decompTime),
      log10(win.solveTime),
      log10(lnx.solveTime),
    ))
}

#figure(
  caption: [Confronto tempi tra sistemi operativi su MATLAB],
  gap: 0.9em,
  cetz.canvas({
    import cetz.draw: *
    import cetz-plot.chart: *
    import cetz: *
    set-style(
      legend: (fill: white, anchor: "north-west"),
      barchart: (column-width: .8, cluster-gap: 0),
      axes: (
        bottom: (
          tick: (label: (angle: 45deg, offset: 15pt, anchor: "east")),
        ),
      ),
    )
    columnchart(
      data,
      size: (14, 9),
      bar-style: cetz-color-palette.with(stroke: false, fill: true),
      mode: "clustered",
      label-key: 0,
      value-key: (..range(1, data.at(0).len()),),
      y-label: "Tempo in ms (Scala logaritmica)",
      y-tick-step: none,
      y-ticks: range(0, 10).map(i => (i, $10^#i$)),
      // y-max: 6,
      labels: (
        [loadTime (Win)],
        [loadTime (Lnx)],
        [decompTime (Win)],
        [decompTime (Lnx)],
        [solveTime (Win)],
        [solveTime (Lnx)],
      ),
      legend: "north-east",
    )
  }),
)

#figure(
  caption: [Confronto tempo complessivo tra sistemi operativi su MATLAB],
  gap: 0.9em,
  plotMATLABMatrix(matlab_win_csv_file, matlab_linux_csv_file, key: csv_keys.allTime, line-padding: 0.25)
)

Osservando prima il column chart e poi il line chart, notiamo che i tempi di decomposizione e risoluzione non sembrano presentare grandi differenze. Tuttavia, il tempo di caricamento risulta significativamente più alto in Linux rispetto a Windows. Questo è probabilmente dovuto al fatto che, per Linux, utilizziamo WSL2, il quale non ha accesso diretto all'hardware e deve quindi operare attraverso un layer di virtualizzazione.

#figure(
  caption: [Confronto errore relativo tra sistemi operativi su MATLAB],
  gap: 0.9em,
  plotMATLABMatrix(matlab_win_csv_file, matlab_linux_csv_file, key: csv_keys.relErr, line-padding: 0.5)
)

Osservando l'errore, notiamo che è identico su entrambe le piattaforme, quindi in MATLAB non si riscontra alcuna differenza tra i due sistemi operativi.

== Risultati C++

// Matrix nelle x, error e tempo complessivo,
#let plotCPPMatrix(data, os: "Windows", key: csv_keys.allTime, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let matrices = (:) // matrixName: none
  let blasSeparated = (:) // blas: values

  for it in filter_by_os_blas(data, os: os) {
    if (not it.matrixName in matrices) {
      matrices.insert(it.matrixName, none)
    }

    if (not it.blas in blasSeparated) {
      blasSeparated.insert(it.blas, ())
    }

    let val = getValFromDictCSV(it, key)

    min = calc.min(min, val)
    max = calc.max(max, val)

    blasSeparated.at(it.blas).push(val)
  }

  createMatricesLinePlot(
    key,
    matrices,
    blasSeparated,
    min,
    max,
  )
}

// Matrix nelle x, error e tempo complessivo,
#let plotCPPLoadMatrix(data, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let matrices = () // matrixName: none
  let osSeparated = (:) // os: values
  let osSeparatedFinal = (:) // os: values

  for it in data {
    if (not it.matrixName in matrices) {
      matrices.push(it.matrixName)
    }

    if (not (it.os) in osSeparated) {
      osSeparated.insert(it.os, (:))
      osSeparatedFinal.insert(it.os, ())
    }

    if (not it.matrixName in osSeparated.at(it.os)) {
      osSeparated.at(it.os).insert(it.matrixName, ())
    }

    let val = getValFromDictCSV(it, csv_keys.loadTime)

    min = calc.min(min, val)
    max = calc.max(max, val)

    osSeparated.at(it.os).at(it.matrixName).push(val)
  }

  for (key, values) in osSeparated {
      for (m, value) in values {
        let sum = value.fold(0, (acc, x) => acc + x)
        osSeparatedFinal.at(key).push(sum / value.len())
      }
  }

  createMatricesLinePlot(
    csv_keys.loadTime,
    matrices,
    osSeparatedFinal,
    min,
    max,
  )
}

// Matrix nelle x, error e tempo complessivo,
#let plotCPP2Matrix(data, key: csv_keys.allTime, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let matrices = () // matrixName: none
  let osBlasSeparated = (:) // blas: values

  for it in data {
    if (not it.matrixName in matrices) {
      matrices.push(it.matrixName)
    }

    let osBlas = it.os + " - " + it.blas

    if (not (osBlas) in osBlasSeparated) {
      osBlasSeparated.insert(osBlas, ())
    }

    let val = getValFromDictCSV(it, key)

    min = calc.min(min, val)
    max = calc.max(max, val)

    osBlasSeparated.at(osBlas).push(val)
  }

  createMatricesLinePlot(
    key,
    matrices,
    osBlasSeparated,
    min,
    max,
  )
}

A differenza di MATLAB, C++ è riuscito a completare tutte le matrici.

=== Memoria

La memoria è identica tra i tre sistemi operativi, quindi non è necessario ripeterla per ciascuno. Questo dipende dal modo in cui viene ottenuta, ovvero dalle allocazioni interne di CHOLMOD, e ha senso, dato che la memoria è determinata principalmente dall'architettura del sistema piuttosto che dal sistema operativo.

#figure(
  caption: [Confronto utilizzo memoria tra sistemi operativi su C++],
  table(
    align: center,
    columns: (auto,) * 6,
    table.header[*Nome Matrice*][*Mem Load (MB)*][*Mem Decomp (MB)*][*Picco Mem Decomp (MB)*][*Mem Risoluzione (MB)*][*Picco Mem Risoluzione (MB)*],
    ..cpp_memory
      .map(m => (
        m.matrixName,
        $#format_bytes_to_mb(m.loadMem)$,
        $#format_bytes_to_mb(m.decompMem)$,
        $#format_bytes_to_mb(m.decompPeakMem)$,
        $#format_bytes_to_mb(m.solveMem)$,
        $#format_bytes_to_mb(m.solvePeakMem)$,
      ))
      .flatten()
  ),
) <cpp_memory_usage>

Analizzando brevemente i dati si vede una grande differenza rispetto a MATLAB, questo è perchè in C++ siamo molto piu precisi dato che andiamo a ottenere la memoria direttamente da CHOLMOD, mentre in MATLAB non possiamo sapere esattamente quanta memoria viene utilizzata da CHOLMOD.

=== Tempi

#figure(
  caption: [Confronto tempo di caricamento tra sistemi operativi su C++],
  gap: 0.9em,
  plotCPPLoadMatrix(cpp_csv_file, line-padding: 0.5)
)

#figure(
  caption: [Confronto tempo di decomposizione tra sistemi operativi e BLAS su C++],
  gap: 0.9em,
  plotCPP2Matrix(cpp_csv_file, key: csv_keys.decompTime, line-padding: 0.5)
)

#figure(
  caption: [Confronto tempo di risoluzione tra sistemi operativi e BLAS su C++],
  gap: 0.9em,
  plotCPP2Matrix(cpp_csv_file, key: csv_keys.solveTime, line-padding: 0.5)
)

==== Riepilogo dei Tempi Compessivi

#let plotAllMatrix(data, key: none, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let matrices = () // matrixName: none
  let osBlasSeparated = (:)

  for it in data {
    if (not it.matrixName in matrices) {
      matrices.push(it.matrixName)
    }

    let osBlas = it.os + " - " + it.blas

    if (not (osBlas) in osBlasSeparated) {
      osBlasSeparated.insert(osBlas, ())
    }

    let val = getValFromDictCSV(it, key)

    min = calc.min(min, val)
    max = calc.max(max, val)

    osBlasSeparated.at(osBlas).push(val)
  }

  createMatricesLinePlot(
    key,
    matrices,
    osBlasSeparated,
    min,
    max,
  )
}

#figure(
  caption: [Confronto tempo complessivo tra sistemi operativi e BLAS su C++],
  gap: 0.9em,
  plotAllMatrix(cpp_csv_file, key: csv_keys.allTime, line-padding: 0.25)
)

Guardando i tempi notiamo che in generale linux sembra essere piu lento di tutti gli altri sistemi operativi, questo è dovuto al fatto che per linux usiamo WSL2. Mentre macOS sembra essere il piu veloce di tutti, ma non troppo rispetto a Windows, questo è dovuto all'hardware migliore rispetto a quello per Windows e Linux.

=== Errore Relativo

#figure(
  caption: [Confronto errore relativo tra sistemi operativi e BLAS su C++],
  gap: 0.9em,
  plotAllMatrix(cpp_csv_file, key: csv_keys.relErr, line-padding: 0.5)
)

Invece guardando l'errore notiamo che ci sono delle piccole differenze tra i sistemi operativi e i blas, ma non sono significative. Questo è un buon risultato, poiché significa che la libreria CHOLMOD funziona in modo simile su entrambe le piattaforme e con diversi BLAS.
E probabilemnte la differenza è dovuta ai diversi compilatori e alle loro ottimizzazioni.

== Confronto MATLAB e C++

Inanzitutto è importante notare come in MATLAB le due matrici più grandi non siano state completate, questo dovuto probabilmente alla versione obsoleta di CHOLMOD in MATLAB, che non ha dei miglioramenti negli algoritmi di riordinamento e anche correzzione di errori.

=== Memoria

Dato che la memoria in MATLAB non è affidabile, invece di fare un confronto abbiamo deciso di analizzare l'uso in memoria di C++, aspettandoci che l'uso di memoria sia equiparabile a quella di MATLAB, dato l'utilizzo di CHOLMOD.

L'analisi dell'uso della memoria basandoci sulla @cpp_memory_usage mostra i seguenti punti salienti:

1. *Carico di memoria iniziale:* Osserviamo che le matrici più piccole, come ex15 e shallow_water1, hanno un consumo ridotto di memoria, inferiore ai 10 MB. Questo è prevedibile, poiché la loro complessità computazionale è limitata. Tuttavia, quando esaminiamo matrici molto più grandi, come Flan_1565, notiamo un incremento drastico del carico di memoria, che supera i 1.8 GB. Questo indica che l'allocazione della memoria iniziale cresce proporzionalmente alla dimensione e alla complessità della matrice.

2. *Memoria richiesta per la decomposizione:* Il processo di decomposizione delle matrici rappresenta il momento più intensivo in termini di memoria. Ad esempio, la decomposizione della matrice Flan_1565 richiede oltre 21 GB di memoria. Questo suggerisce che, per strutture di grande dimensione, l'algoritmo utilizzato deve gestire un enorme quantitativo di dati e operazioni, generando un picco di utilizzo. Matrici di media grandezza come apache2 e G3_circuit richiedono invece circa 1.7-1.8 GB, evidenziando una crescita meno drastica ma comunque consistente. Questo è dovuto al fenomeno del fill-in che anche se ridotto dato l'utilizzo di algoritmi di riordinamento, è comunque presente e richiede una certa quantità di memoria.

3. *Picco di memoria di decomposizione:* In diversi casi, il picco di memoria durante la fase di decomposizione è inferiore al valore totale della memoria richiesta. Questo può significare che l'allocazione della memoria varia nel tempo e viene gestita dinamicamente, evitando sprechi di risorse. In pratica, la memoria viene allocata progressivamente secondo necessità, ottimizzando l'uso delle risorse disponibili.

4. *Memoria richiesta per la risoluzione:* Un aspetto interessante è che, rispetto alla decomposizione, la fase di risoluzione della matrice ha un impatto molto più contenuto sull'utilizzo della memoria. Questo accade perché la risoluzione si basa sui risultati ottenuti in fase di decomposizione e non richiede un'elaborazione intensiva sugli stessi dati. Di conseguenza, il consumo di memoria rimane relativamente basso.

=== Tempi

#let plotCompareMATLABCPP(mat_win_csv, mat_lnx_csv, cpp_csv, key: csv_keys.allTime, line-padding: 0.5) = {
  let min = calc.inf;
  let max = -calc.inf;

  let matrices = () // matrixName: none
  let osValues = (:) // data: values

  osValues.insert("MATLAB - Windows", ())
  osValues.insert("MATLAB - Linux", ())

  for (win, lnx) in mat_win_csv.zip(mat_lnx_csv) {
    let valWin = getValFromDictCSV(win, key)
    let valLnx = getValFromDictCSV(lnx, key)

    min = calc.min(min, valWin, valLnx)
    max = calc.max(max, valWin, valLnx)

    osValues.at("MATLAB - Windows").push(valWin)
    osValues.at("MATLAB - Linux").push(valLnx)
  }

  let osBlasSeparated = (:)

  for it in cpp_csv {
    if (not it.matrixName in matrices) {
      matrices.push(it.matrixName)
    }

    let osBlas = it.os + " - " + it.blas

    if (not (osBlas) in osBlasSeparated) {
      osBlasSeparated.insert(osBlas, ())
    }

    let val = getValFromDictCSV(it, key)

    min = calc.min(min, val)
    max = calc.max(max, val)

    osBlasSeparated.at(osBlas).push(val)
  }

  let data = osValues + osBlasSeparated

  createMatricesLinePlot(
    key,
    matrices,
    data,
    min,
    max,
    plotStyle: cetz-color-palette-8.with(stroke: true),
    markStyle: cetz-color-palette-8.with(stroke: true, fill: true),
  )
}

#figure(
  caption: [Confronto tempo caricamento tra MATLAB e C++],
  gap: 0.9em,
  plotCompareMATLABCPP(matlab_win_csv_file, matlab_linux_csv_file, cpp_csv_file, key: csv_keys.loadTime, line-padding: 0.25)
)

#figure(
  caption: [Confronto tempo decomposizione e risoluzione tra MATLAB e C++],
  gap: 0.9em,
  plotCompareMATLABCPP(matlab_win_csv_file, matlab_linux_csv_file, cpp_csv_file,
  key: csv_keys.allNoLoadTime, line-padding: 0.25)
)

#figure(
  caption: [Confronto errore relativo tra MATLAB e C++],
  gap: 0.9em,
  plotCompareMATLABCPP(matlab_win_csv_file, matlab_linux_csv_file, cpp_csv_file, key: csv_keys.relErr, line-padding: 0.25)
)