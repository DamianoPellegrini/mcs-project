// #import "unimib-thesis.typ": unimib-thesis
#import "sesso.typ": sesso

// #show: unimib-thesis.with(
//   title: [Simulating and rendering real-time fluid surfaces by stochastically sampling frequency spectrums],
//   author: (
//     name: [Damiano Pellegrini],
//     matr: [886261]
//   ),
//   mentor: (
//     name: [Prof. Ciocca Gianluigi]
//   ),
//   co-mentors: (
//     (name: [Prof. Marelli Davide]),
//   ),
//   area: [School of Sciences],
//   department: [Department of Informatics, Systems and Communications],
//   course: [Degree course in Computer Science],
//   bibliography: bibliography(style: "ieee", "citations.bib"),
//   paper-size: "a4",
//   scholar-year: 2024,
//   abstract: include("chapters/abstract.typ"),
// )
#show: sesso.with(
  title: "Appunti - Teoria dell'Informazione e Crittografia",
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

#set cite(form: "prose")

#set heading(numbering: none)

#include "chapters/introduction.typ"

#set heading(numbering: "1.1.")

#include "chapters/1.matlab.typ"
#include "chapters/2.c++.typ"
#include "chapters/3.results.typ"

#set heading(numbering: none)
