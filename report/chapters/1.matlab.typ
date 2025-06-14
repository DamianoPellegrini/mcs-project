#import "../packages.typ": unify.unit, codly, codly-languages

#show: codly.codly-init
#codly.codly(languages: codly-languages.codly-languages, breakable: true)

= Matlab

== Introduzione a MATLAB

MATLAB (acronimo di "MATrix LABoratory") è un ambiente di calcolo numerico avanzato e un linguaggio di programmazione di alto livello sviluppato da MathWorks. Concepito originariamente negli anni '70 dal matematico Cleve Moler come interfaccia user-friendly per le librerie numeriche LINPACK ed EISPACK, MATLAB si è evoluto in un ecosistema completo per il calcolo scientifico e l'analisi numerica, diventando uno strumento fondamentale in svariati campi scientifici e ingegneristici.

Le caratteristiche distintive che hanno contribuito al suo successo includono:

- Gestione nativa ed efficiente delle operazioni matriciali
- Vasta collezione di funzioni matematiche ottimizzate per diverse applicazioni computazionali
- Strumenti avanzati di visualizzazione scientifica e generazione di grafici interattivi
- Ambiente di sviluppo integrato (IDE) con funzionalità complete di debug e profiling
- Architettura estensibile attraverso toolbox specializzati per domini specifici (elaborazione segnali, ottimizzazione, machine learning, statistica, ecc.)
- Interfacce per l'integrazione con altri linguaggi di programmazione come C, C++ e Python

La sintassi di MATLAB è intuitiva e orientata alla risoluzione di problemi matematici, rendendo relativamente semplice l'implementazione di algoritmi complessi con poche righe di codice.

== Fattorizzazione di Cholesky in MATLAB

MATLAB implementa la fattorizzazione di Cholesky attraverso la funzione built-in $"chol"$, specificamente progettata per determinare la decomposizione di Cholesky di una matrice simmetrica definita positiva. La funzione $"chol"$ offre diverse varianti sintattiche per adattarsi a esigenze computazionali specifiche, di cui la principale è:

```matlab
R = chol(A)
```

Dove:
- $A$ è una matrice simmetrica definita positiva (ovvero una matrice per cui tutti gli autovalori sono positivi)
- $R$ è una matrice triangolare superiore tale che $A = R^T R$

Questa funzione realizza la fattorizzazione di Cholesky di una matrice simmetrica definita positiva A.
Nel caso in cui A non sia simmetrica, MATLAB la tratta come se fosse simmetrica utilizzando solo la parte triangolare superiore.
Se A non è definita positiva, MATLAB restituisce un errore.

Poiché il nostro caso si concentra su matrici sparse di dimensioni variabili, utilizzeremo la seguente sintassi:

```matlab
[R, flag, p] = chol(A, 'vector')
```

Dove:
- $A$ è una matrice simmetrica definita positiva
- $R$ è una matrice triangolare superiore risultante dalla fattorizzazione
- $"flag"$ è un indicatore che assume valore 0 se la matrice è definita positiva, diverso da 0 altrimenti
- $p$ è un vettore di permutazione che ottimizza l'ordinamento delle righe e colonne di A

Per le matrici sparse di grandi dimensioni, un aspetto cruciale è la gestione del _fill-in_ — fenomeno per cui elementi inizialmente nulli diventano non-zero durante la fattorizzazione, aumentando significativamente la complessità computazionale e l'utilizzo di memoria.

MATLAB affronta questo problema utilizzando l'algoritmo AMD (Approximate Minimum Degree), una strategia di riordinamento che analizza la struttura di sparsità della matrice e approssima una permutazione ottimale delle righe e colonne. Questa permutazione minimizza il fill-in atteso durante la fattorizzazione, riducendo notevolmente sia i requisiti di memoria che il tempo di calcolo.

La relazione matematica che esprime questa permutazione è:

$ R^T R = A(p,p) $

dove $p$ rappresenta il vettore di permutazione e $A(p,p)$ indica la matrice $A$ con righe e colonne riordinate secondo $p$. Questo approccio produce una fattorizzazione matematicamente equivalente ma computazionalmente molto più efficiente, con un fattore sparso $R$ che preserva maggiormente la struttura di sparsità originale.

Questa implementazione consente di ridurre la complessità algoritmica. Questa complessità ottimizzata è ottenibile in casi favorevoli e dipende fortemente dall'efficacia del riordinamento e dalla struttura specifica della matrice. Ulteriori informazioni sono disponibili nella documentazione di @matlab_chol.

=== Funzione chol in MATLAB

Per rendere più completo il confronto ed avere una base di partenza, abbiamo deciso di analizzare la struttura interna dell'implementazione di $"chol"$ in MATLAB. Dall'analisi è emerso che questa funzione utilizza internamente il pacchetto CHOLMOD (CHOLesky MODification), un componente della libreria SuiteSparse @SuiteSparse. SuiteSparse rappresenta una raccolta completa e altamente ottimizzata di algoritmi per l'algebra lineare sparsa, sviluppata principalmente sotto la guida di Timothy A. Davis e disponibile come software open source su #link("https://github.com/DrTimothyAldenDavis/SuiteSparse")[GitHub] @SuiteSparse.

Per verificare empiricamente l'utilizzo di SuiteSparse in MATLAB, abbiamo applicato, con piccole modifiche, uno script diagnostico che identifica le librerie matematiche sottostanti e le relative versioni tramite funzioni di debug non documentate. Lo script di partenza è disponibile presso #link("https://undocumentedmatlab.com/articles/sparse-data-math-info")[undocumentedmatlab.com].

I risultati dello script confermano che MATLAB si affida effettivamente a molteplici componenti della libreria SuiteSparse per le operazioni su matrici sparse. @matlab_sparse_2013

L'output generato dallo script ha evidenziato le seguenti librerie:
- Found: CHOLMOD version 1.7.0, Sept 20, 2008:#sym.space.third: status: OK
- Found: colamd version 2.5, May 5, 2006: OK.
- Found: CHOLMOD version 1.7.0, Sept 20, 2008:#sym.space.third: status: OK
- Found: UMFPACK V5.4.0 (May 20, 2009), Control:
- Found: UMFPACK V5.4.0 (May 20, 2009), Control:
- Found: CHOLMOD version 1.7.0, Sept 20, 2008:#sym.space.third: status: OK
- Found: SuiteSparseQR, version 1.1.0 (Sept 20, 2008)

=== Analisi di CHOLMOD

Approfondendo l'architettura del pacchetto CHOLMOD, abbiamo scoperto che questo si basa essenzialmente sulle librerie BLAS (Basic Linear Algebra Subprograms) e LAPACK (Linear Algebra PACKage) per eseguire operazioni di algebra lineare ad alte prestazioni. Ulteriori dettagli sul funzionamento di queste librerie sono consultabili presso #link("https://netlib.org/blas/")[netlib.org/blas] @netlib_blas e #link("https://netlib.org/lapack/")[netlib.org/lapack] @netlib_lapack.

Queste librerie esistono in diverse implementazioni, ciascuna ottimizzata per architetture hardware specifiche. Le implementazioni più diffuse includono OpenBLAS (ottimizzata per molteplici architetture), Apple Accelerate (Implementazione per sistemi operativi MacOS) e Intel MKL (oneAPI Math Kernel Library), quest'ultima particolarmente performante su processori Intel.

Nel caso specifico di MATLAB su Windows e Linux, l'implementazione utilizzata è Intel MKL, che garantisce prestazioni ottimali su architetture x86 e x86-64.

È possibile verificare questa configurazione attraverso i seguenti comandi MATLAB:

```matlab
version('-blas')
version('-lapack')
```

I risultati ottenuti sono i seguenti (la versione potrebbe variare a seconda della release di MATLAB):

ans = 'Intel(R) oneAPI Math Kernel Library Version 2024.1-Product Build 20240215\ for Intel(R) 64 architecture applications (CNR branch AVX2)'

ans = 'Intel(R) oneAPI Math Kernel Library Version 2024.1-Product Build 20240215\ for Intel(R) 64 architecture applications (CNR branch AVX2) supporting Linear Algebra PACKage (LAPACK 3.11.0)'


Dato che Intel MKL e Apple Accelerate sono librerie commerciali, abbiamo deciso di fare non solo un confronto tra MATLAB e Open Source, ma anche di analizzare le differenze tra le varie implementazioni di BLAS e LAPACK.

== Implementazione in MATLAB

=== Parametri analizzati

Tempo di esecuzione:
- *loadTime:* tempo necessario per caricare la matrice dal file in formato MATLAB (MAT) (#unit("ms"))
- *decompTime:* tempo per eseguire la fattorizzazione di Cholesky (#unit("ms"))
- *solveTime:* tempo per risolvere un sistema lineare usando i fattori (#unit("ms"))

Per il calcolo del tempo, abbiamo utilizzato il profiler di MATLAB attraverso $"profile"$, che misurano il tempo di esecuzione assieme ad altre informazioni di un blocco di codice.

Utilizzo di memoria:
- *loadMem:* memoria utilizzata per caricare la matrice (Bytes)
- *decompMem:* memoria utilizzata per la fattorizzazione (Bytes)
- *solveMem:* memoria utilizzata per trovare la soluzione (Bytes)

Per il calcolo della memoria, abbiamo utilizzato una funzionalità del profiler di MATLAB non documentata, che permette di calcolare la memoria utilizzata in una porzione di codice. Ovviamente, essendo non documentata, non è garantita la sua stabilità e correttezza, ma l'abbiamo ritenuto il metodo migliore per il calcolo la memoria utilizzata.

Per utilizzare questa funzionalità, abbiamo usato il comando $"profile -memory on"$ che avvisa il profiler di tenere traccia della memoria utilizzata. @matlab_undocumented_2009

Accuratezza:
- *Errore Relativo:* errore relativo della soluzione calcolata rispetto alla soluzione attesa

=== Metodologia

Per ogni matrice, abbiamo eseguito i seguenti passaggi:

- Caricamento della matrice in memoria da file in formato MATLAB
- Esecuzione della fattorizzazione di Cholesky sulla matrice
- Risoluzione del sistema lineare $upright(A)x = b$
- Calcolo dell'errore relativo tra la soluzione calcolata e quella attesa

Per risolvere il sistema lineare $upright(A) x = b$ dove il termine $b$ è noto ed è scelto in modo che la soluzione esatta
sia il vettore $x_e = [1, 1, 1, 1, 1, 1, ...]$, cioè $b = upright(A) x_e$.

I risultati vengono poi esportati in un file CSV per successiva analisi e confronto con altre implementazioni.

== Documentazione di MATLAB

MATLAB, in quanto software commerciale, presenta una documentazione eccellente: ben strutturata, dettagliata e arricchita da numerosi esempi applicativi. L'ecosistema integrato di funzioni predefinite e toolbox specializzati consente agli utenti di implementare rapidamente soluzioni a problemi complessi con un minimo di codice, riducendo significativamente i tempi di sviluppo rispetto a soluzioni che richiederebbero l'integrazione manuale di diverse librerie.

Questo rappresenta un vantaggio sostanziale rispetto a molte alternative open source, dove la documentazione può risultare frammentaria, incompleta o non aggiornata. In ambito scientifico e ingegneristico, la rapidità di prototipazione e sviluppo offerta da MATLAB giustifica spesso l'investimento economico, soprattutto considerando i costi indiretti legati al tempo di sviluppo.

Tuttavia, è importante evidenziare alcune limitazioni. La documentazione ufficiale, pur essendo esaustiva nell'illustrare l'utilizzo delle funzioni, raramente rivela i dettagli implementativi sottostanti. Nel caso della fattorizzazione di Cholesky, ad esempio, la documentazione specifica parametri e comportamenti attesi, ma non approfondisce gli algoritmi utilizzati o le ottimizzazioni applicate. Questa opacità può risultare problematica durante il debugging di casi particolari o quando si necessita di comprendere le ragioni di determinati comportamenti computazionali.

== Commenti

Un aspetto particolarmente interessante emerso dalla nostra analisi riguarda l'architettura interna di MATLAB: alcune funzionalità core, inclusa la fattorizzazione di Cholesky, si basano su librerie open source come SuiteSparse, ottimizzate tramite implementazioni non open-source, ma con licenza libera previa citazione, utilizzabili di BLAS/LAPACK come Intel MKL. Questo solleva interrogativi legittimi sul valore aggiunto del software commerciale rispetto all'utilizzo diretto delle librerie open source sottostanti.

Il valore di MATLAB risiede quindi non tanto nell'esclusività degli algoritmi implementati, quanto nell'integrazione di questi in un ambiente coerente, ben documentato e ottimizzato per la produttività scientifica. La questione se questo valore aggiunto giustifichi il costo di licenza dipende fortemente dal contesto applicativo, dalle esigenze specifiche dell'utente e dai vincoli di tempo e risorse del progetto. Nell'ambito della ricerca, non a scopo di lucro, sviluppare uno strumento che faccia utilizzo di librerie commerciali/proprietarie e open-source potrebbe rivelarsi ragionevole.
