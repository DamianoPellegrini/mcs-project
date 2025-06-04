#import "../packages.typ": unify.unit, codly, codly-languages

#show: codly.codly-init
#codly.codly(languages: codly-languages.codly-languages, breakable: true)

= C++

== Introduzione a C++

C++ rappresenta una scelta ottimale per l'implementazione di algoritmi di algebra lineare grazie alle sue caratteristiche di efficienza, controllo di basso livello e supporto per la programmazione orientata agli oggetti.

Nel contesto della fattorizzazione di Cholesky, C++ ci permette di:
- Integrare librerie specializzate per l'algebra lineare
- Controllare precisamente l'allocazione della memoria
- Accesso al codice sorgente delle librerie per ottimizzazioni specifiche

== Tentativo iniziale con Rust

Prima di procedere con l'implementazione in C++, abbiamo esplorato la possibilità di utilizzare Rust, un linguaggio moderno che offre garanzie di sicurezza della memoria senza compromettere le prestazioni. Tuttavia, questa strada è stata abbandonata per diverse ragioni tecniche.

=== Limitazioni delle librerie Rust per algebra lineare

L'ecosistema Rust per il calcolo scientifico, sebbene in rapida evoluzione, ha mostrato significative carenze:

- *Librerie immature*: significative carenze:
I crate come `nalgebra` e `sprs` offrono funzionalità di base per l'algebra lineare, ma mancano di implementazioni ottimizzate per operazioni su matrici sparse di grandi dimensioni.
  
- *Mancanza di algoritmi avanzati*: In particolare, non abbiamo trovato implementazioni robuste della fattorizzazione di Cholesky per matrici sparse che includessero tecniche di riduzione del fill-in.

La mancanza di algoritmi per la riduzione del fill-in è risultata particolarmente critica, poiché questo aspetto è fondamentale per l'efficienza della fattorizzazione di Cholesky su matrici sparse. Senza tali ottimizzazioni, l'utilizzo di memoria e i tempi di calcolo sarebbero stati proibitivi per le matrici di test più grandi.

Questa esperienza ha evidenziato come, nonostante i vantaggi in termini di sicurezza offerti da Rust, l'ecosistema C++ rimanga ancora dominante per applicazioni di calcolo scientifico avanzato che richiedono algoritmi specializzati e altamente ottimizzati.

L'unica eccezione è russell, una libreria di binding di SuiteSparse per Rust, che però non abbiamo esplorato perché non pubblicizzata e scoperta troppo tardi.

== Tool Chain C++

Per lo sviluppo del nostro progetto abbiamo utilizzato diversi strumenti in base all'ambiente operativo:

In comune è stato utilizzato:

- *CMake*: Sistema cross-platform per la gestione del processo di build, permettendo di generare progetti
  Visual Studio nativi mantenendo la portabilità del codice. La configurazione CMake ha facilitato l'integrazione delle diverse
  librerie utilizzate nel progetto.

=== Ambiente Windows
In ambiente Windows, la nostra implementazione si è basata su:

- *Microsoft Visual C++ (MSVC)*: Il compilatore ufficiale di Microsoft che offre ottimizzazioni specifiche per
  architetture Intel/AMD.

- *Intel Fortran Compiler (IFX)*: Compilatore Intel per Fortran che abbiamo utilizzato per compilare alcune componenti di SuiteSparse.

=== Ambiente Linux
Per garantire la portabilità del codice e per effettuare test comparativi, abbiamo anche utilizzato:

- *GNU Compiler Collection (GCC)*: Compilatore C++ standard in ambienti Linux, utilizzato nella versione 11.3 con pieno supporto per C++17.

- *GNU Fortran (GFortran)*: Necessario per compilare alcune componenti delle librerie BLAS e LAPACK utilizzate dal progetto.

=== Ambiente MacOS
Per testare un ambiente più professionale ed utilizzare una libreria proprietaria differente, ci siamo forniti di:

- *Apple clang (clang)*: Compilatore C++ standard in ambienti Apple MacOS, utilizzato nella versione 17.0.0 con pieno supporto per C++17.

- *GNU Fortran (GFortran)*: Necessario per compilare alcune componenti delle librerie BLAS e LAPACK utilizzate dal progetto.

== Librerie C++ per la fattorizzazione di Cholesky

=== SuiteSparse
SuiteSparse fornisce algoritmi altamente ottimizzati per matrici sparse. In particolare, abbiamo integrato CHOLMOD (con le sue dipendenze),
la componente specializzata per la fattorizzazione di Cholesky di matrici sparse simmetriche definite positive, con licenza GNU LGPL.

CHOLMOD offre prestazioni superiori rispetto altre implementazioni per matrici di grandi dimensioni grazie a:

- Algoritmi di ordinamento avanzati (AMD, COLAMD, METIS) che riducono il fill-in durante la fattorizzazione
- Decomposizione supernodale che sfrutta operazioni BLAS di livello 3
- Supporto per calcoli multithreaded che sfruttano processori multi-core
- Gestione ottimizzata della memoria che riduce il sovraccarico per matrici molto sparse

Inoltre, un aspetto che non abbiamo esplorato è la disponibilità di diversi binding di questa libreria per altri linguaggi di programmazione, come Python, Julia, Rust e JavaScript, che ne facilitano l'integrazione. È inoltre possibile compilare la libreria per poi utilizzarla in MATLAB.

=== Eigen
Eigen è una libreria C++ header-only di algebra lineare ad alte prestazioni, completamente sviluppata in template
per massimizzare l'ottimizzazione in fase di compilazione, con licenza MPL2. @eigen

Una caratteristica distintiva di Eigen è la sua architettura estensibile che permette
l'integrazione con diverse librerie esterne specializzate. Nel nostro progetto,
abbiamo scelto di utilizzare l'interfaccia con CHOLMOD di SuiteSparse:

- *Interfaccia CHOLMOD*: Abbiamo sfruttato principalmente il modulo `CholmodSupport` di Eigen che
  permette di utilizzare gli algoritmi avanzati di CHOLMOD mantenendo la sintassi familiare di Eigen.

- *Alternative considerate*: Sarebbe stato possibile utilizzare l'implementazione nativa di Eigen
  (`SimplicialLLT`) con o senza supporto BLAS/LAPACK, che risulta adeguata per matrici di dimensioni moderate,
  ma dato che volevamo basarci sull'implementazione di MATLAB abbiamo optato per l'altra strada.

- *Alternative proprietarie*: Eigen supporta anche interfacce verso librerie proprietarie come Pardiso di Intel oneAPI e
  Accelerate di Apple, che offrono implementazioni altamente ottimizzate ma non open-source.

Per la fattorizzazione di Cholesky, il nostro approccio primario è stato:
`CholmodSupport::CholmodDecomposition` che delega il calcolo effettivo a CHOLMOD, beneficiando degli algoritmi di ordinamento
avanzati e dell'ottimizzazione per sistemi multi-core e scegliendo in automatico che algoritmo di ordinamento usare e che tipo di fattorizzazione
(supermodal vs simplicial).

La flessibilità di Eigen ci ha permesso di integrare efficacemente la potenza di CHOLMOD mantenendo un'interfaccia coerente e familiare nel codice principale, senza compromettere l'approccio open-source del progetto.

=== Fast Matrix Market
Per la lettura delle matrici sparse dal formato Matrix Market (MTX), abbiamo integrato la libreria Fast Matrix Market, con licenza BSD-2.
Questa libreria ha consentito di importare efficientemente dataset di test di grandi dimensioni.

Fast Matrix Market si distingue per:
- Lettura parallelizzata che sfrutta tutti i core disponibili
- Parsing efficiente che riduce significativamente i tempi di caricamento
- Integrazione diretta con Eigen senza necessità di conversioni intermedie
- Supporto per diverse precisioni numeriche (float, double, complex)

== Librerie BLAS e LAPACK

Le librerie BLAS (Basic Linear Algebra Subprograms) e LAPACK (Linear Algebra PACKage) rappresentano fondamenti essenziali per l'algebra
lineare computazionale. Queste librerie standardizzate forniscono implementazioni ottimizzate di operazioni matriciali e vettoriali
di base che costituiscono i blocchi fondamentali per algoritmi più complessi, inclusa la fattorizzazione di Cholesky.

=== Intel MKL

Intel Math Kernel Library (MKL) rappresenta l'implementazione commerciale di riferimento per BLAS e LAPACK, sviluppata e ottimizzata
specificamente per processori Intel. Questa libreria offre prestazioni eccezionali su architetture x86 e x86-64 grazie a:

- Ottimizzazioni a livello di microarchitettura che sfruttano set di istruzioni specifici (AVX, AVX2, AVX-512)
- Parallelizzazione automatica che utilizza efficacemente processori multi-core
- Gestione intelligente della cache e della memoria per massimizzare il throughput
- Routine specializzate per matrici sparse che riducono significativamente il tempo di calcolo

=== OpenBLAS

OpenBLAS rappresenta l'alternativa open source più matura a Intel MKL, offrendo prestazioni competitive su diverse architetture hardware.
Questa libreria deriva dal progetto GotoBLAS2 e si distingue per:

- Ottimizzazioni specifiche per diverse architetture (Intel, AMD, ARM, POWER)
- Supporto per parallelismo multi-thread attraverso implementazione OpenMP
- Compatibilità con l'interfaccia CBLAS standard
- Prestazioni scalabili fino a 256 core

=== Apple Accelerate

Accelerate è il framework di calcolo numerico sviluppato da Apple e integrato nativamente nei sistemi operativi macOS e iOS.
Include implementazioni ottimizzate di BLAS e LAPACK specificamente progettate per l'hardware Apple, inclusi i processori M-Series basati su architettura Apple Silicon (ARM).

Caratteristiche distintive di Accelerate includono:

- Ottimizzazioni specifiche per chip Apple Silicon
- Integrazione profonda con l'ecosistema di librerie Apple e supporto per tecnologie come Grand Central Dispatch
- Supporto per calcoli vettoriali SIMD attraverso il framework vDSP
- Bilanciamento automatico tra prestazioni ed efficienza energetica

== Implementazione in C++

=== Considerazioni generali

Avendo accesso al codice sorgente volendo è possibile adattare il codice alla risoluzione di un problema specifico,
nel nostro caso abbiamo mantenuto un implementazione piuttosto generica, date le diverse matrici da trattare.

=== Parametri analizzati

A differenza di MATLAB, andiamo a ottenere anche il tipo di BLAS e il numero di thread utilizzati per l'esecuzione,
nello specifico abbiamo misurato:

Tempo di esecuzione:
- *loadTime:* tempo necessario per caricare la matrice dal file in formato Matrix Market (MTX) (#unit("ms"))
- *decompTime:* tempo per eseguire la fattorizzazione di Cholesky (#unit("ms"))
- *solveTime:* tempo per risolvere un sistema lineare usando i fattori (#unit("ms"))

Per misurare il tempo con precisione, abbiamo utilizzato le funzionalità della libreria standard C++:

```cpp
auto start = std::chrono::high_resolution_clock::now();
// Operazione da misurare
auto end = std::chrono::high_resolution_clock::now();
auto duration =
    std::chrono::duration_cast<std::chrono::milliseconds>(
        end - start
    ).count();
```

Utilizzo di memoria:

- *loadMem:* memoria utilizzata per caricare la matrice (Bytes)
- *decompMem:* memoria utilizzata per la fattorizzazione (Bytes)
- *solveMem:* memoria utilizzata per trovare la soluzione (Bytes)

Il calcolo della memoria per le operazioni di caricamento della matrice è stato implementato manualmente, considerando:

```cpp
size_t valuesSize = A.nonZeros() * sizeof(double);
size_t innerIndicesSize = A.nonZeros() * sizeof(int64_t);
size_t outerIndicesSize = (A.outerSize() + 1) * sizeof(int64_t);
auto loadMem = valuesSize + innerIndicesSize + outerIndicesSize;
```

Invece per il calcolo della memoria per le operazioni di fattorizzazione e risoluzione, abbiamo modificato parte del codice di CHOLMOD, aggiungendo un contatore per la memoria allocata. Questo contatore viene resettato prima di ogni operazione e aggiornato durante l'allocazione della memoria.

```cpp
solver.cholmod().memory_allocated = 0;  // Reset contatore
// Operazione da misurare
auto operationMem = solver.cholmod().memory_allocated;
```

Accuratezza:

- *Errore Relativo:* errore relativo della soluzione calcolata rispetto alla soluzione attesa

Per ridurre l'errore nel calcolo dell'errore evitando il calcolo una delle due radici, abbiamo ricavato la seguente formula: $ sqrt((norm(x - x_e)^2) / (norm(x_e)^2)) = (norm(x - x_e)_2) / (norm(x_e)_2) $

Dove dato $ (norm(x - x_e)_2) / (norm(x_e)_2) = (sqrt((x - x_e) dot (x - x_e))) / (sqrt(x_e dot x_e)) $ con $dot$ prodotto scalare tra vettori, ho che $ (norm(x - x_e)^2) / (norm(x_e)^2) = ((x - x_e) dot (x - x_e)) / (x_e dot x_e) $ ovvero le somme delle componenti del vettore al quadrato.

=== Metodologia

La metodologia è la stessa di MATLAB, con l'unica differenza che il caricamento della matrice avviene non in formato MATLAB, ma in formato Matrix Market (MTX) tramite la libreria Fast Matrix Market.

=== Implementazione della fattorizzazione di Cholesky

In linea con l'approccio MATLAB, abbiamo implementato la fattorizzazione di Cholesky utilizzando la libreria CHOLMOD attraverso l'interfaccia fornita da Eigen:

```cpp
Eigen::CholmodDecomposition<SparseMatrix> solver;
solver.compute(A); // Fattorizzazione della matrice A
xe = solver.solve(b); // Risoluzione del sistema Ax = b
```

Questa interfaccia consente di sfruttare le ottimizzazioni avanzate di CHOLMOD, inclusi gli algoritmi di ordinamento e la decomposizione supernodale, mantenendo al contempo la sintassi familiare di Eigen. La libreria CHOLMOD gestisce automaticamente la scelta dell'algoritmo di ordinamento e del tipo di composizione più adatto in base alla struttura della matrice, ottimizzando così le prestazioni della fattorizzazione.

== Documentazione e Integrazione Librerie C++

Per integrare efficacemente le librerie C++ nel nostro progetto, abbiamo dovuto affrontare diverse sfide legate alla documentazione e alla configurazione.

=== Eigen

La documentazione di Eigen rappresenta un eccellente esempio di riferimento tecnico per progetti open-source:

*Completezza:* Tutorial dettagliati, guida per le classi e documentazione delle API generata con Doxygen.
Esempi: Numerosi esempi di codice che coprono tutti i moduli principali.
*Integrazione:* Essendo header-only, l'integrazione richiede solo l'inclusione dei file header senza necessità di linking. Tuttavia, è necessario effettuare il linking di eventuali librerie esterne utilizzate in Eigen (nel nostro caso SuiteSparse).
*Moduli esterni:* La documentazione sul modulo CholmodSupport è più limitata rispetto ai moduli principali, richiedendo talvolta la consultazione del codice sorgente.

L'integrazione di Eigen nel progetto è stata generalmente agevole grazie alla semplicità del modello header-only e ai chiari esempi disponibili nella documentazione ufficiale.

=== SuiteSparse

La documentazione di SuiteSparse, e in particolare di CHOLMOD, presenta caratteristiche distintive:

*Documentazione scientifica:* Articoli accademici dettagliati che descrivono gli algoritmi implementati.
*Documentazione tecnica:* File README e documentazione interna al codice che descrivono l'API C.
*Limitazioni:* Minore enfasi sugli esempi di integrazione in progetti C++ moderni.
*Build system:* Documentazione limitata sull'integrazione con sistemi di build.

Nonostante l'eccellente documentazione degli algoritmi sottostanti, l'integrazione di SuiteSparse ha richiesto maggiore impegno, specialmente per configurare correttamente le dipendenze tra i vari componenti. @SuiteSparse

=== Fast Matrix Market

La libreria Fast Matrix Market offre una documentazione concisa ma efficace:

*GitHub README:* Documenta chiaramente l'API principale e i casi d'uso comuni.
*Esempi:* Include esempi di integrazione con Eigen che hanno facilitato significativamente l'adozione.
*Integrazione CMake:* Fornisce configurazioni CMake moderne con supporto per find_package.

L'integrazione di Fast Matrix Market è stata notevolmente semplice grazie alla documentazione mirata e agli esempi pratici, permettendo una rapida implementazione della lettura di matrici sparse in formato MTX.

=== Librerie BLAS e LAPACK

Le sfide più significative nel progetto sono emerse dall'integrazione delle implementazioni BLAS e LAPACK:

*Documentazione frammentata:* Ogni implementazione (Intel MKL, OpenBLAS, Accelerate) presenta una propria documentazione con convenzioni e approcci di configurazione diversi, ma questo non ha rappresentato il problema principale.

*Difficoltà CMake:* Abbiamo riscontrato notevoli difficoltà nell'integrazione attraverso CMake:

- Mancanza di moduli CMake aggiornati per il rilevamento delle diverse implementazioni, rendendo inefficaci i moduli standard come FindBLAS e FindLAPACK.
- Necessità di linkare manualmente le librerie specificando esattamente i percorsi e i componenti richiesti, invece di poter utilizzare i meccanismi automatizzati di CMake.
- Configurazioni diverse richieste per Windows (MKL/MSVC) e Linux (OpenBLAS/GCC).

*Conflitti di simboli:* In alcuni casi, quali l'utilizzo dell'interfaccia standard ILP64 LAPACK 3.11.0 dell'implementazione di Apple Accelerate ha causato conflitti di simboli difficili da risolvere. Di conseguenza,  è stati necessario adottare la versione LP64 sia per OpenBLAS che per Accelerate in MacOS.

=== Conclusioni

Dall'esperienza di integrazione delle diverse librerie, abbiamo tratto importanti conclusioni:

Le librerie con documentazione orientata agli esempi (Eigen, Fast Matrix Market) hanno richiesto tempi di integrazione significativamente minori.

Le dipendenze transitive non documentate tra librerie C/C++ rappresentano una sfida significativa per l'integrazione tramite CMake.

L'approccio più efficace è risultato essere lo sviluppo di configurazioni CMake modulari che isolano le complessità di ogni libreria.

La documentazione delle librerie di algebra lineare spesso privilegia la descrizione matematica degli algoritmi a scapito dei dettagli di integrazione tecnica.

Queste sfide di integrazione, sebbene impegnative, hanno permesso di sviluppare un sistema robusto e flessibile che può adattarsi a diverse implementazioni BLAS/LAPACK mantenendo un'interfaccia coerente attraverso Eigen.

== Commenti

Il nostro progetto ha dimostrato con successo l'integrazione di librerie specializzate per l'algebra lineare in un ecosistema C++ moderno. Utilizzando Eigen come interfaccia ad alto livello e SuiteSparse (in particolare CHOLMOD) come motore di calcolo per la fattorizzazione di Cholesky, siamo riusciti a costruire un sistema flessibile e performante, capace di gestire matrici sparse di grandi dimensioni.

Un aspetto distintivo della nostra implementazione è stata la capacità di sfruttare diverse implementazioni di BLAS e LAPACK (Intel MKL, OpenBLAS, Accelerate), permettendoci di confrontare direttamente le prestazioni di soluzioni commerciali e open-source. Questa flessibilità ci ha consentito di simulare efficacemente il comportamento di MATLAB, che utilizza internamente CHOLMOD con implementazioni BLAS ottimizzate.

L'obiettivo principale dell'esperimento era verificare se un'alternativa completamente open-source potesse offrire prestazioni paragonabili alla soluzione commerciale di MATLAB.

Per quanto l'ideazione di una soluzione artigianale possa sembrare complicato, lo sviluppo del codice in se è stata forse la parte meno impegnativa. Maggiori difficoltà invece, le abbiamo incontrate nell'integrazione delle diverse librerie, specialmente quelle legate a BLAS e LAPACK, hanno rivelato la necessità di migliorare gli strumenti di build e la documentazione per questi componenti fondamentali dell'ecosistema di calcolo scientifico.

Nonostante queste sfide, il nostro progetto dimostra che è possibile costruire una piattaforma di calcolo numerico avanzata basata interamente su tecnologie open-source, offrendo un'alternativa valida a soluzioni commerciali come MATLAB per applicazioni che richiedono la fattorizzazione di Cholesky su matrici sparse di grandi dimensioni.
