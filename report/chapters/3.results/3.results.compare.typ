#import "../../import.typ": matlab_linux_csv_file, matlab_win_csv_file, cpp_csv_file, matrices_cpp, cetz-color-palette, cetz-color-palette-8, cetz-color-palette-9

#import "../../macros.typ": *

== Confronto MATLAB e C++

Innanzitutto, è importante notare che, in MATLAB, le due matrici più grandi non sono state completate. Questo è probabilmente dovuto alla versione obsoleta di CHOLMOD presente in MATLAB, che non include miglioramenti negli algoritmi di riordinamento né correzioni degli errori nel codice.

=== Memoria

#figure(
  caption: [Confronto utilizzo memoria tra MATLAB e C++],
  {
  let key = csv_keys.allMem
  let min = calc.inf;
  let max = -calc.inf;

  let osValues = (:) // data: values

  osValues.insert("loadMem (MATLAB)(Win)", ())
  osValues.insert("decompMem (MATLAB)(Win)", ())
  osValues.insert("solveMem (MATLAB)(Win)", ())
  osValues.insert("loadMem (MATLAB)(Lnx)", ())
  osValues.insert("decompMem (MATLAB)(Lnx)", ())
  osValues.insert("solveMem (MATLAB)(Lnx)", ())
  osValues.insert("loadMem (C++)", ())
  osValues.insert("decompMem (C++)", ())
  osValues.insert("solveMem (C++)", ())

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

      osValues.at(key +  " (MATLAB)(Win)").push(valWin)
      osValues.at(key +  " (MATLAB)(Lnx)").push(valLnx)
    }
  }

  let cpp_memory = filter_by_os_blas(cpp_csv_file, blas: "OpenBLAS", os: "Linux")

  for it in cpp_memory {
    for key in (
      csv_keys.loadMem,
      csv_keys.decompMem,
      csv_keys.solveMem,
    ) {
      let val = getValFromDictCSV(it, key)

      min = calc.min(min, val)
      max = calc.max(max, val)

      osValues.at(key +  " (C++)").push(val)
    }
  }

  createMatricesLinePlot(
    none,
    matrices_cpp,
    osValues,
    min,
    max,
    customLabel: [Memoria caricamento, decomposizione e risoluzione \[$log_(10)(s)$\]],
    anchorOffset: (1em, -0.5em),
    legend: "inner-north-west",
    anchor: "north-west",
    plotStyle: cetz-color-palette-9.with(stroke: true),
    markStyle: cetz-color-palette-9.with(stroke: true, fill: true),
  )
}) <memory_usage_compare_plot>

Inanziutto dato che sono presenti due anomalie nelle matrici _apache2_ e _G3_circuit_ in MATLAB Linux, e quindi quindi non sono state considerate nell'analisi essendo sicuri che siano anomalie evidenti.

L'analisi dell'uso della memoria basandoci sulla @memory_usage_compare_plot mostra i seguenti punti salienti:

1. *Carico di memoria iniziale:* Osserviamo che le matrici più piccole, come _ex15_ e _shallow\_water1_, hanno un consumo ridotto di memoria, inferiore ai 10 MB. Questo è prevedibile, poiché la loro complessità computazionale è limitata. Tuttavia, quando esaminiamo matrici molto più grandi, come _Flan\_1565_, notiamo un incremento drastico del carico di memoria, che supera i 1.8 GB. Questo indica che l'allocazione della memoria iniziale cresce proporzionalmente alla dimensione e alla complessità della matrice.

2. *Memoria richiesta per la decomposizione:* Il processo di decomposizione delle matrici rappresenta il momento più intensivo in termini di memoria. Ad esempio, la decomposizione della matrice _Flan\_1565_ richiede oltre 21 GB di memoria. Questo suggerisce che, per strutture di grande dimensione, l'algoritmo utilizzato deve gestire un enorme quantitativo di dati e operazioni, generando un picco di utilizzo. Matrici di media grandezza come _apache2_ e _G3\_circuit_ richiedono invece circa 1.7-1.8 GB, evidenziando una crescita meno drastica ma comunque consistente. Questo è dovuto al fenomeno del fill-in che anche se ridotto dato l'utilizzo di algoritmi di riordinamento, è comunque presente e richiede una certa quantità di memoria.

3. *Picco di memoria di decomposizione:* In diversi casi, il picco di memoria durante la fase di decomposizione è inferiore al valore totale della memoria richiesta. Questo può significare che l'allocazione della memoria varia nel tempo e viene gestita dinamicamente, evitando sprechi di risorse. In pratica, la memoria viene allocata progressivamente secondo necessità, ottimizzando l'uso delle risorse disponibili.

4. *Memoria richiesta per la risoluzione:* Un aspetto interessante è che, rispetto alla decomposizione, la fase di risoluzione della matrice ha un impatto molto più contenuto sull'utilizzo della memoria. Questo accade perché la risoluzione si basa sui risultati ottenuti in fase di decomposizione e non richiede un'elaborazione intensiva sugli stessi dati. Di conseguenza, il consumo di memoria rimane relativamente basso.

5. *Confronto memoria MATLAB e C++:* In generale, l'uso della memoria in MATLAB e C++ è simile, con piccole variazioni. Tuttavia, MATLAB tende a utilizzare una quantità leggermente maggiore di memoria per la decomposizione rispetto a C++, probabilmente a causa della gestione interna delle strutture dati e dell'overhead associato all'ambiente di esecuzione.

=== Tempi

#let plotCompareMATLABCPP(mat_win_csv, mat_lnx_csv, cpp_csv, key: csv_keys.allTime, line-padding: 0.5, legend: "inner-south-east", anchor: "south-east", anchorOffset: (0, 0.75em)) = {
  let min = calc.inf;
  let max = -calc.inf;

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
    matrices_cpp,
    data,
    min,
    max,
    plotStyle: cetz-color-palette-8.with(stroke: true),
    markStyle: cetz-color-palette-8.with(stroke: true, fill: true),
    legend: legend,
    anchor: anchor,
    anchorOffset: anchorOffset,
  )
}

#figure(
  caption: [Confronto tempo caricamento tra MATLAB e C++],
  gap: 0.9em,
  plotCompareMATLABCPP(matlab_win_csv_file, matlab_linux_csv_file, cpp_csv_file, key: csv_keys.loadTime, line-padding: 0.25, anchorOffset: (0, 0.25em))
) <load_time_compare_plot>

#figure(
  caption: [Confronto tempo decomposizione tra MATLAB e C++],
  gap: 0.9em,
  plotCompareMATLABCPP(matlab_win_csv_file, matlab_linux_csv_file, cpp_csv_file,
  key: csv_keys.decompTime, line-padding: 0.25)
) <decomp_time_compare_plot>

#figure(
  caption: [Confronto tempo risoluzione tra MATLAB e C++],
  gap: 0.9em,
  plotCompareMATLABCPP(matlab_win_csv_file, matlab_linux_csv_file, cpp_csv_file,
  key: csv_keys.solveTime, line-padding: 0.25, legend: "inner-north-west", anchor: "north-west", anchorOffset: (0.75em, 0) )
) <solve_time_compare_plot>

#figure(
  caption: [Confronto tempo complessivo tra MATLAB e C++],
  gap: 0.9em,
  plotCompareMATLABCPP(matlab_win_csv_file, matlab_linux_csv_file, cpp_csv_file,
  key: csv_keys.allTime, line-padding: 0.25)
) <total_time_compare_plot>

L'analisi del tempo di esecuzione basandoci su @load_time_compare_plot, @decomp_time_compare_plot, @solve_time_compare_plot e @total_time_compare_plot evidenzia alcuni aspetti chiave:

1. *Tempo di caricamento:* Le matrici più piccole, come _ex15_ e _shallow\_water1_, hanno tempi di caricamento molto ridotti, inferiori al millisecondo. Man mano che la dimensione cresce, il tempo aumenta significativamente. Per le matrici più grandi, come _Flan\_1565_, il caricamento può richiedere diversi secondi. Non è presente una differenza significativa tra C++ e MATLAB tranner per MATLAB - Linux, dove il caricamento è più lento.

2. *Tempo di decomposizione:* Questa fase è la più dispendiosa in termini di tempo. Per matrici grandi come _Flan\_1565_, la decomposizione richiede oltre 100 secondi, evidenziando la complessità del processo. Però si può notare che in generale tra i diversi sistemi operativi e le librerie BLAS non ci sono differenze significative.

3. *Tempo di risoluzione:* Diversamente dalla decomposizione, la fase di risoluzione è generalmente molto più veloce. Questo avviene perché la risoluzione sfrutta la struttura fattorizzata della matrice, riducendo il numero di operazioni necessarie. Per la maggior parte delle matrici, il tempo di risoluzione è inferiore a 1 secondo, a riprova dell'efficacia dei metodi numerici impiegati, e anche qua non si nota una grossa differenza tra MATLAB e C++.

4. *Tempo complessivo:* Sommando le tre fasi, emerge chiaramente che la decomposizione è il passaggio dominante in termini di costo computazionale. Ottimizzare questo processo tramite migliori algoritmi o librerie specializzate potrebbe portare a una riduzione significativa dei tempi di esecuzione, specialmente per matrici di grandi dimensioni.

5. *Confronto MATLAB e C++:* In generale, i tempi di esecuzione tra MATLAB e C++ sono comparabili, con piccole variazioni. Tuttavia, MATLAB tende a essere leggermente più lento, soprattutto nella fase di caricamento e decomposizione. Questo potrebbe essere dovuto all'overhead dell'ambiente MATLAB e alla sua gestione delle strutture dati.

=== Errore Relativo

#figure(
  caption: [Confronto errore relativo tra MATLAB e C++],
  gap: 0.9em,
  plotCompareMATLABCPP(matlab_win_csv_file, matlab_linux_csv_file, cpp_csv_file, key: csv_keys.relErr, line-padding: 0.25,
  legend: "inner-north-west", anchor: "north-west", anchorOffset: (6.5em, 0))
) <rel_err_compare_plot>

L'analisi dell'errore relativo riportata in @rel_err_compare_plot mostra come la precisione numerica vari a seconda delle librerie e dell'ambiente di esecuzione:

1. *Ordine di grandezza dell'errore:* In generale, l'errore relativo oscilla tra $10^{-6}$ e $10^{-16}$ ma apparte per macOS - Accelerate nella matrice "Flan_1565" che ha un errore un pò piu altro rispetto alle altre implementazioni non sembrano esserci differenze significative tra i vari sistemi operativi e le librerie BLAS.

2. *Variazione tra le matrici:* Notiamo come non è la dimensione della matrice a influenzare l'errore, ma piuttosto la struttura e le proprietà intrinseche della matrice stessa. Ad esempio, matrici con una maggiore densità di zeri o con una struttura particolare possono portare a errori più elevati. E nel nostro caso notiamo come è la matriche "ex15" che è la piu piccola a generare un errore piu alto rispetto alle altre.

== Considerazioni Finali sul Confronto

In conclusione, notiamo come ci aspettavamo dato l'utilizzo della stessa libreria CHOLMOD, che le prestazioni di MATLAB e C++ sono comparabili, con piccole variazioni dovute all'overhead di MATLAB. Tuttavia, C++ mostra una maggiore flessibilità e potenziale per ottimizzazioni future, grazie alla possibilità di utilizzare diverse librerie BLAS e di personalizzare l'implementazione.
Però bisogna anche considera che MATLAB non è riuscito a completare le due matrici più grandi, il che potrebbe indicare limitazioni nella versione di CHOLMOD utilizzata o nella gestione della memoria. Questo rappresenta un punto a favore di C++, che ha gestito con successo tutte le matrici testate.

Però è anche interessante notare che non ci siano grandi differenze rispetto all'utilizzo della libreria Intel MKL o OpenBLAS, il che suggerisce che CHOLMOD è ben ottimizzata per lavorare con entrambe le librerie BLAS. E che le librerie BLAS siano ben ottimizzate e che la scelta con full open source di OpenBLAS non abbia impatti significativi sulle prestazioni rispetto a Intel MKL, che è una libreria proprietaria.

Inoltre l'analisi dell'uso della memoria fa capire quanto sia importante avere abbastanza memoria disponibile per gestire matrici di grandi dimensioni, specialmente durante la fase di decomposizione. Questo è un aspetto cruciale da considerare quando si lavora con applicazioni che richiedono l'elaborazione di grandi dataset o matrici sparse. Possibile grazie all'uso della memoria virtuale e della gestione dinamica della memoria, che permette di allocare risorse in modo efficiente e ridurre il rischio di esaurimento della memoria fisica.
