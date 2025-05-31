#import "../../import.typ": matlab_linux_csv_file, matlab_win_csv_file, matrices_matlab

#import "../../macros.typ": *

== Risultati MATLAB

#let plotMATLABMatrix(data, data2, key: none, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let osValues = (:) // data: values

  osValues.insert("Windows", ())
  osValues.insert("Linux", ())

  for (win, lnx) in data.zip(data2) {

    let valLnx = getValFromDictCSV(lnx, key)
    let valWin = getValFromDictCSV(win, key)

    min = calc.min(min, valWin, valLnx)
    max = calc.max(max, valWin, valLnx)

    osValues.at("Windows").push(valWin)
    osValues.at("Linux").push(valLnx)
  }

  createMatricesLinePlot(
    key,
    matrices_matlab,
    osValues,
    min,
    max,
  )
}

Durante l'esecuzione, due matrici hanno causato un errore interno della libreria CHOLMOD in Windows, mentre in Linux hanno provocato la terminazione forzata del processo. Di conseguenza, non sono state incluse nei risultati. Le matrici problematiche sono:
- _Flan\_1565_
- _StocF-1465_

=== Memoria

#figure(
  caption: [Memoria utilizzata dai sistemi operativi su MATLAB],
  table(
    columns: (2fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: center,
    table.header(
      repeat: true,
      table.cell(rowspan: 2, align: center + horizon, [*Matrice*]),
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
          if (float(lnx.decompMem) > 1e10) {
            let megabytes = calc.round(float(lnx.decompMem) / 1048576, digits: 2)
            [#format-scientific(megabytes)]
          } else {
            [#format_bytes_to_mb(lnx.decompMem)]
          },
          [#format_bytes_to_mb(lnx.solveMem)],
        )
      })
      .flatten()
  ),
) <matlab_memory_usage>


#figure(
  caption: [Confronto utilizzo memoria tra sistemi operativi su MATLAB],
  {
    let key = csv_keys.allMem
    let min = calc.inf;
    let max = -calc.inf;

    let osValues = (:) // data: values

    osValues.insert("loadMem (Win)", ())
    osValues.insert("loadMem (Lnx)", ())
    osValues.insert("decompMem (Win)", ())
    osValues.insert("decompMem (Lnx)", ())
    osValues.insert("solveMem (Win)", ())
    osValues.insert("solveMem (Lnx)", ())

    for (win, lnx) in matlab_win_csv_file.zip(matlab_linux_csv_file) {

      for key in (
        csv_keys.loadMem,
        csv_keys.decompMem,
        csv_keys.solveMem,
      ) {
        let valWin = getValFromDictCSV(win, key)
        let valLnx = getValFromDictCSV(lnx, key)

        min = calc.min(min, valWin, valLnx)
        max = calc.max(max, valWin, valLnx)

        osValues.at(key + " (Win)").push(valWin)
        osValues.at(key + " (Lnx)").push(valLnx)
      }
    }

    createMatricesLinePlot(
      csv_keys.allMem,
      matrices_matlab,
      osValues,
      min,
      max,
      legend: "inner-north-west",
      anchor: "north-west",
      anchorOffset: (0.75em, -0.5em),
    )
  }
)

Dalla tabella emerge chiaramente che il profiler di memoria di MATLAB potrebbe non essere completamente affidabile, poiché riporta valori pari a zero per il caricamento di alcune matrici e valori anomali per la decomposizione delle matrici Apache e _G3\_Circuit_ su Linux. Questo fenomeno dei valori anomali è probabilmente dovuto alla presenza di WSL2 e all'utilizzo della libreria esterna CHOLMOD, ma dipende anche dal metodo con cui MATLAB registra l'uso della memoria. Se il profiler utilizza un approccio basato sul campionamento, allora i valori pari a zero sarebbero comprensibili.

In generale, l'uso della memoria sembra aumentare con la dimensione della matrice e risulta maggiore per la decomposizione rispetto al caricamento e alla risoluzione.

=== Tempi

#figure(
  caption: [Confronto tempi tra sistemi operativi su MATLAB],
  gap: 0.9em,
  {
    let min = calc.inf;
    let max = -calc.inf;

    let osValues = (:) // data: values

    osValues.insert("loadTime (Win)", ())
    osValues.insert("loadTime (Lnx)", ())
    osValues.insert("decompTime (Win)", ())
    osValues.insert("decompTime (Lnx)", ())
    osValues.insert("solveTime (Win)", ())
    osValues.insert("solveTime (Lnx)", ())

    for (win, lnx) in matlab_win_csv_file.zip(matlab_linux_csv_file) {

      for key in (
        csv_keys.loadTime,
        csv_keys.decompTime,
        csv_keys.solveTime,
      ) {
        let valWin = getValFromDictCSV(win, key)
        let valLnx = getValFromDictCSV(lnx, key)

        min = calc.min(min, valWin, valLnx)
        max = calc.max(max, valWin, valLnx)

        osValues.at(key + " (Win)").push(valWin)
        osValues.at(key + " (Lnx)").push(valLnx)
      }
    }

    createMatricesLinePlot(
      none,
      matrices_matlab,
      osValues,
      min,
      max,
      legend: "inner-north-west",
      anchor: "north-west",
      anchorOffset: (0.75em, -0.5em),
      customLabel: [Tempo caricamento, decomposizione e risoluzione \[$log_(10)(s)$\]],
    )
  }
)

Analizzando i tempi separatamente, notiamo che l'unica grande differenza tra i due sistemi operativi riguarda il tempo di caricamento, significativamente più elevato in Linux. Questo è probabilmente dovuto al fatto che, su Linux, utilizziamo WSL2, il quale non ha accesso diretto all'hardware e deve operare attraverso un layer di virtualizzazione.

#figure(
  caption: [Confronto tempo complessivo tra sistemi operativi su MATLAB],
  gap: 0.9em,
  plotMATLABMatrix(matlab_win_csv_file, matlab_linux_csv_file, key: csv_keys.allTime, line-padding: 0.25)
)

Se osserviamo i tempi complessivi, non si nota una grande differenza tra i due sistemi operativi. Windows sembra più veloce, ma è importante considerare che il tempo di caricamento è significativamente più alto in Linux, il che contribuisce a un tempo complessivo maggiore.

=== Errore Relativo

#figure(
  caption: [Confronto errore relativo tra sistemi operativi su MATLAB],
  gap: 0.9em,
  plotMATLABMatrix(matlab_win_csv_file, matlab_linux_csv_file, key: csv_keys.relErr, line-padding: 0.5)
)

Osservando l'errore, notiamo che è identico su entrambe le piattaforme, quindi in MATLAB non si riscontra alcuna differenza tra i due sistemi operativi. Questo è comprensibile, dato che vengono utilizzate la stessa libreria CHOLMOD e la stessa libreria BLAS.
