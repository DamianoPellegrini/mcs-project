# Guida all'Installazione

Questo documento fornisce istruzioni per l'installazione delle librerie matematiche necessarie su diversi sistemi operativi per poter compilare ed eseguire il progetto.

# Report

Per generare il report, è necessario scaricare l'estensione TinyMist per VS Code e poi compilare il file main.typ

# MATLAB

1. Installa MATLAB

2. Carica le matrici in formato mat nella cartella matlab/matrices

3. Esegui il file main.m da MATLAB

# C++

## In Comune

Inserisci le matrici da analizzare in una cartella chiamata matrices nella root del progetto

## Windows

1. **Intel MKL**
   - Scarica Intel MKL dal [sito ufficiale Intel](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl.html)
   - Installa nella posizione predefinita (tipicamente `C:\Program Files (x86)\Intel\oneAPI\mkl`)

2. **OpenBLAS**
   - Scarica i file binari precompilati di OpenBLAS dal [repository GitHub ufficiale](https://github.com/xianyi/OpenBLAS/releases)
   - Estrai e posiziona i file binari nella directory cmake nella root del progetto

3. Installa Visual Studio 2022 con gli strumenti per la compilazione C/C++

4. Installa il compilatore di Fortran di Intel

5. Esegui il file run.bat che compilerà ed eseguirà le versioni prima MKL e poi OpenBLAS

## Linux

1. **Intel MKL**
   - Installa seguendo la [guida di installazione ufficiale](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html)
   
2. **OpenBLAS (64-bit)**
   - Installa utilizzando il gestore pacchetti:
     ```bash
     # Ubuntu/Debian
     sudo apt-get install libopenblas64-dev
     ```

3. Installa i pacchetti per la compilazione C, C++ e Fortran assieme agli strumenti di build di cmake e make

4. Esegui il file run.sh che compilerà ed eseguirà le versioni prima MKL e poi OpenBLAS

## macOS

1. **OpenBLAS**
   - Installa utilizzando Homebrew:
     ```bash
     brew install openblas
     ```

2. Installa i pacchetti per la compilazione C, C++ e Fortran assieme agli strumenti di build di cmake e make

3. Esegui il file run.sh che compilerà ed eseguirà le versioni prima Accelerate e poi OpenBLAS
