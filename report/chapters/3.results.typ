#import "../import.typ": cpp_csv_file

#import "../macros.typ": *

= Risultati

== Specifiche del sistema

Specifiche del sistema per Windows:

- *Processore*: Intel(R) Core(TM) i7-7700HQ CPU \@ 2.80GHz 2.81 GHz
- *Architettura*: Sistema operativo a 64 bit, processore basato su x64
- *RAM installata*: 16 GB
- *Archiviazione*: 238 GB SSD e 1 TB SSD Esterno
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

#figure(
  caption: [Matrici analizzate],
  table(
    columns: (auto,) * 3,
    table.header[*Nome Matrice*][*Righe & Colonne*][*Valori non zero*],
    ..filter_by_os_blas(cpp_csv_file, blas: "OpenBLAS", os: "Linux")
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

Dato che sia MATLAB che C++ utilizzano la stessa libreria CHOLMOD, ci si aspetta che i risultati siano simili. Tuttavia, potrebbero emergere delle differenze, soprattutto a causa della versione obsoleta di MATLAB, meno aggiornata rispetto a quella di C++. Inoltre, l'uso delle differenti librerie BLAS potrebbe influenzare ulteriormente i risultati.

Prima di andare a fare il confronto tra MATLAB e C++, è necessario analizzare i risultati di quest'ultimi, in modo da avere un'idea di cosa aspettarsi.

#include "3.results/3.results.matlab.typ"

#include "3.results/3.results.c++.typ"

#include "3.results/3.results.compare.typ"
