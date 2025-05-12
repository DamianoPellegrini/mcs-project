= Introduzione

La fattorizzazione di Cholesky rappresenta un metodo efficiente per risolvere sistemi lineari quando la matrice dei coefficienti 
è simmetrica e definita positiva. Data una matrice A, la fattorizzazione di Cholesky produce una matrice triangolare inferiore L tale che:

$ A = L dot L^T $

Dove:
- $A$ è una matrice simmetrica definita positiva (il che implica che tutti i suoi autovalori sono strettamente positivi)
- $L$ è una matrice triangolare inferiore
- $L^T$ è la trasposta di L

Questa decomposizione risulta particolarmente utile nella risoluzione di sistemi lineari, nell'ottimizzazione 
numerica e nelle applicazioni statistiche.

Esiste anche una variante della fattorizzazione di Cholesky che introduce una matrice diagonale D, portando alla seguente
espressione:

$ A = L dot D dot L^T $

Dove:
- $A$ è una matrice simmetrica definita positiva
- $L$ è una matrice triangolare inferiore con diagonale unitaria (tutti gli elementi diagonali sono 1)
- $D$ è una matrice diagonale contenente i pivot della fattorizzazione
- $L^T$ è la trasposta di L
Questa variante è particolarmente utile quando si desidera evitare di estrarre la radice quadrata degli elementi diagonali
di L, semplificando così i calcoli e migliorando la stabilità numerica.

Nelle applicazioni pratiche, molti problemi ingegneristici e scientifici generano matrici di grandi dimensioni in cui 
la maggior parte degli elementi sono zero (matrici sparse). Questo porta a un problema durante la fattorizzazione di Cholesky, 
cioè la gestione del fill-in.
Il fill-in è un fenomeno che si verifica durante la fattorizzazione di Cholesky, in cui gli zeri nella matrice originale
diventano non zero nella matrice triangolare inferiore L. Questo può portare a un significativo aumento del
numero di elementi non-zero e, di conseguenza, a maggiori requisiti di memoria e tempo di calcolo per la fattorizzazione.
Il fill-in è fortemente influenzato dall'ordinamento delle righe e delle colonne della matrice originale e quindi 
un ordinamento appropriato può ridurre drasticamente il numero di elementi non-zero che appaiono durante la fattorizzazione.
Sono stati quindi sviluppati diversi algoritmi e tecniche per ridurre il fill-in. Tra questi,
uno dei più utilizzati è l'AMD (Approximate Minimum Degree), che opera riordinando le righe e colonne in base al 
grado dei nodi nel grafo associato alla matrice. Altri approcci includono l'ordinamento Nested Dissection e le tecniche
di Minimum Fill.

In questa relazione, analizzeremo in dettaglio l'implementazione della fattorizzazione di Cholesky in MATLAB, esplorando 
le sue caratteristiche, i punti di forza e le eventuali limitazioni. Successivamente, applicheremo questi concetti per 
sviluppare un'implementazione open source in C++ (e se possibile un'implementazione comparabile a quella di MATLAB), 
confrontando approfonditamente le due soluzioni in termini di efficienza 
computazionale, gestione della memoria e scalabilità su diverse tipologie di matrici sparse. Questo confronto ci permetterà 
di verificare se ha senso avventurarsi in librerie open source per la fattorizzazione di Cholesky, oppure se è più
opportuno pagare per una libreria commerciale come MATLAB.
