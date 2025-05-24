#import "unimib-template.typ": unimib

#show: unimib.with(
  title: "Metodo del Calcolo Scientifico - Assignment 1 - Decomposizione con metodo di Cholesky",
  area: [Scuola di Scienza],
  department: [Dipartimento di Informatica, Sistemi e Comunicazione],
  course: [Corso di Scienze Informatiche],
  authors: (
    "Pellegrini Damiano 886261",
    "Sanvito Marco 886493",
  ),
  bibliography: bibliography(style: "ieee", "citations.bib"),
  abstract: include("chapters/abstract.typ"),
  dark: false,
  lang: "it",
  // flipped: true
)

#outline(target: figure.where(kind: "code"), title: [Indice codici])
#pagebreak(weak: true)

#set heading(numbering: none)

#include "chapters/introduction.typ"

#set heading(numbering: "1.1.")

#include "chapters/1.matlab.typ"
#include "chapters/2.c++.typ"
#include "chapters/3.results.typ"
#include "chapters/4.conclusion.typ"

#counter(heading).update(0)
#set heading(numbering: "A.i.")

#include "chapters/appendice.codici.typ"

#set heading(numbering: none)
