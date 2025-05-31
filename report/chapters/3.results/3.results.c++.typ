#import "../../import.typ": matlab_linux_csv_file, matlab_win_csv_file, cpp_csv_file, cetz-color-palette, cetz-color-palette-8, matrices_cpp

#import "../../macros.typ": *

== Risultati C++

// Matrix nelle x, error e tempo complessivo,
#let plotCPPLoadMatrix(data, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let osSeparated = (:) // os: values
  let osSeparatedFinal = (:) // os: values

  for it in data {
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
    matrices_cpp,
    osSeparatedFinal,
    min,
    max,
  )
}

// Matrix nelle x, error e tempo complessivo,
#let plotCPPMatrix(data, key: csv_keys.allTime, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let osBlasSeparated = (:) // blas: values

  for it in data {
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
    matrices_cpp,
    osBlasSeparated,
    min,
    max,
  )
}

A differenza di MATLAB, C++ è riuscito a completare tutte le matrici, inoltre avendo accesso a più informazioni, siamo andati a vedere quanti thread in esecuzione parallela venissero utilizzati dalle varie librerie BLAS.

=== Threads

- Windows/Linux - MKL - 4 threads
- Windows/Linux - OpenBLAS - 8 threads
- macOS - Accelerate - (-1) threads (numero di thread scelti dinamicamente)
- macOS - OpenBLAS - 10 threads

Da questi dati, si nota che è l'architettura del sistema a determinare il numero di thread utilizzati, e non il sistema operativo. Inoltre, ci aspettiamo che macOS ottenga risultati leggermente migliori grazie alla possibilità di utilizzare più thread, con un impatto più evidente sulle matrici di dimensioni maggiori.

=== Memoria

La memoria è identica nei tre sistemi operativi, pertanto non è necessario ripeterla nella tabella sottostante per ciascuno. Tale uniformità è dovuta al metodo di allocazione interna di CHOLMOD e risulta logica, poiché la memoria è determinata principalmente dall'architettura del sistema piuttosto che dal sistema operativo.

#let cpp_memory = filter_by_os_blas(cpp_csv_file, blas: "OpenBLAS", os: "Linux")

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
) <cpp_memory_usage_table>

#figure(
  caption: [Confronto utilizzo memoria tra sistemi operativi su C++],
  {
  let key = csv_keys.allMem
  let min = calc.inf;
  let max = -calc.inf;

  let osValues = (:) // data: values

  osValues.insert("loadMem", ())
  osValues.insert("decompMem", ())
  osValues.insert("solveMem", ())

  for it in cpp_memory {
    for key in (
      csv_keys.loadMem,
      csv_keys.decompMem,
      csv_keys.solveMem,
    ) {
      let val = getValFromDictCSV(it, key)

      min = calc.min(min, val)
      max = calc.max(max, val)

      osValues.at(key).push(val)
    }
  }

  createMatricesLinePlot(
    none,
    matrices_cpp,
    osValues,
    min,
    max,
    customLabel: [Memoria caricamento, decomposizione e risoluzione \[$log_(10)("MB")$\]]
  )
})

Dall'analisi della memoria, emerge che l'utilizzo maggiore si verifica durante la fase di decomposizione e di caricamento della matrice. Tale dato è prevedibile, considerando che il processo di risoluzione si basa sui risultati della decomposizione. Si osserva inoltre un incremento dell'utilizzo della memoria in proporzione alla dimensione della matrice.

=== Tempi

#figure(
  caption: [Confronto tempo di caricamento tra sistemi operativi su C++],
  gap: 0.9em,
  plotCPPLoadMatrix(cpp_csv_file, line-padding: 0.5)
)

#figure(
  caption: [Confronto tempo di decomposizione tra sistemi operativi e BLAS su C++],
  gap: 0.9em,
  plotCPPMatrix(cpp_csv_file, key: csv_keys.decompTime, line-padding: 0.5)
)

#figure(
  caption: [Confronto tempo di risoluzione tra sistemi operativi e BLAS su C++],
  gap: 0.9em,
  plotCPPMatrix(cpp_csv_file, key: csv_keys.solveTime, line-padding: 0.5)
)

Dall'analisi dei tempi invece, emerge che Linux presenta una velocità inferiore rispetto agli altri sistemi operativi, principalmente a causa dell'utilizzo di WSL2. MacOS, al contrario, risulta essere il più performante, sebbene la differenza rispetto a Windows non sia significativa. Tale risultato è probabilmente attribuibile a un hardware di livello superiore rispetto a quello disponibile per Windows e Linux. Si segnala inoltre un valore anomalo nel tempo di caricamento della matrice _parabolic_fem_ su Linux che persiste su varie run del programma.

=== Riepilogo dei Tempi Compessivi

#let plotAllMatrix(data, key: none, line-padding: 0) = {
  let min = calc.inf;
  let max = -calc.inf;

  let osBlasSeparated = (:)

  for it in data {
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
    matrices_cpp,
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

In conclusione, l'analisi dei tempi complessivi conferma le aspettative: Linux su WSL2 risulta essere il sistema operativo più lento, mentre macOS si dimostra il più veloce. Tuttavia, la differenza temporale tra i tre sistemi operativi non appare significativa, il che rappresenta un risultato positivo in quanto indica che la libreria CHOLMOD opera in modo analogo su tutte le piattaforme e nonostante le diverse implementazioni di BLAS.

=== Errore Relativo

#figure(
  caption: [Confronto errore relativo tra sistemi operativi e BLAS su C++],
  gap: 0.9em,
  plotAllMatrix(cpp_csv_file, key: csv_keys.relErr, line-padding: 0.5)
)

Osservando l'errore, si evidenziano lievi discrepanze tra i sistemi operativi e le librerie BLAS, sebbene non rilevanti. Questo risultato è positivo, in quanto suggerisce che la libreria CHOLMOD mantenga un comportamento uniforme su diverse piattaforme e con differenti implementazioni BLAS. È plausibile che tali differenze siano attribuibili ai vari compilatori e alle loro ottimizzazioni, fatta eccezione per un valore anomalo nella matrice _Flan_1565_ su macOS Accelerate, dove l'errore risulta maggiore rispetto agli altri sistemi operativi e librerie BLAS, errore dovuto probabilmente ad arrotondamenti o troncamenti inaspettati.
