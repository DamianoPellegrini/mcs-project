// Workaround for the lack of an `std` scope.
#let _std-bibliography = bibliography

#let _enStrings = (
  university: "University of Milan - Bicocca",
  mentor: "Mentor",
  co-mentor: "Co-mentor",
  thesis: "Bachelor's Thesis of",
  academic-year: "Academic year",
  introduction: "Introduction",
  acknowledgements: "Acknowledgments",
  chapter: "Chapter",
  abstract: "Abstract",
)

#let _itStrings = (
  university: "Università degli Studi di Milano - Bicocca",
  mentor: "Relatore",
  co-mentor: "Co-relatore",
  thesis: "Relazione della prova finale di",
  academic-year: "Anno accademico",
  introduction: "Introduzione",
  acknowledgements: "Riconoscimenti",
  chapter: "Capitolo",
  abstract: "Sommario",
)

#let unimib-thesis(
  title: [A long enough thesis title for it to wrap on a newline and show how the title wraps],
  abstract: none,
  keywords: (),
  // Your informations
  author: (
    name: [Mario Rossi],
    // Your matriculation number
    matr: [XXXXXX],
  ),
  // Your mentor that helped you with this thesis
  mentor: (
    name: [University Tutor],
  ),
  // Co-mentors that helped reviewing this thesis
  co-mentors: (
    (name: [Business Tutor]),
    (name: [University Tutor 2]),
  ),
  // University area of education
  area: [School of Sciences],
  // University department
  department: [Department of Informatics, Systems and Communications],
  // University course
  course: [Degree course in Computer Science],
  // The latter academic year in which you are writing this thesis for
  scholar-year: datetime.today().year(),
  // The result of a call to the `bibliography` function or `none`.
  bibliography: none,
  paper-size: "us-letter",
  single-page: true,
  // Sets the language, could be either "it", "en" or none, in that case it defaults to "en"
  lang: "en",
  // Thesis content
  body,
) = {
  set document(title: title, author: author.name.text, date: datetime.today(), keywords: keywords)

  // Language settings
  set text(lang: lang)
  let langStrings = if lang == "en" {
    _enStrings
  } else if lang == "it" {
    _itStrings
  }

  // Font style
  set text(size: 13pt, font: "New Computer Modern")
  show raw: set text(font: "New Computer Modern Mono")


  // Style outline
  set outline(depth: 3, indent: 1em)

  // Style bibliography.
  show _std-bibliography: set text(10pt)
  set _std-bibliography(style: "ieee")

  // Configure the page.
  set page(
    paper: paper-size,
    // The margins depend on the paper size.
    margin: if paper-size != "a4" {
      (
        top: (1.5in / 279mm) * 100%,
        inside: (if single-page { 1in } else { 1.75in } / 216mm) * 100%,
        outside: (1in / 216mm) * 100%,
        bottom: (1in / 279mm) * 100%,
      )
    } else {
      (
        top: 1.5in,
        inside: if single-page { 1in } else { 1.75in },
        outside: 1in,
        bottom: 1in,
      )
    },
  )

  // Configure lists.
  set enum(indent: 1em, body-indent: 0.9em)
  set list(indent: 1em, body-indent: 0.9em)

  // Configure headings.
  set heading(numbering: "1.1.")
  show heading: set block(above: 1.4em, below: 1em)
  show heading: it => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(here())

    set par(first-line-indent: 0pt)
    if it.level == 1 [
      // We don't want to number of the acknowledgment section.
      #let is-nonnum = it.body in ([#langStrings.acknowledgements], [])
      #if is-nonnum {
        // Uncount non numbered section
        // counter(heading).update(n => n - 1)
      }
      // TODO: find how to not count certain sections in this file rather than externally based con content or maybe a custom function

      #v(2em, weak: true)
      #if it.numbering != none and not is-nonnum {
        set text(0.75em)
        block(breakable: false)[
          #text(langStrings.chapter + " ")
          #numbering("1", ..levels)
          #linebreak()
          #v(1.375em, weak: true)
        ]
      }

      #it.body
      #v(1.375em, weak: true)

    ] else if it.level >= 2 [
      #set par(first-line-indent: measure(numbering(it.numbering, ..levels)).width) if it.numbering != none

      #v(1em, weak: true)
      #it
      #v(1em, weak: true)
    ]
  }

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 1em)

  // Configure appearance of references
  show ref: it => {
    if it.element != none and it.element.func() == math.equation {
      // Override equation references.
      link(
        it.element.location(),
        numbering(
          it.element.numbering,
          ..counter(math.equation).at(it.element.location()),
        ),
      )
    } else if it.element != none and it.element.func() == heading and it.element.level == 1 {
      // Override heading aka section references.
      link(
        it.element.location(),
        [
          #langStrings.chapter #numbering(
            "1",
            ..counter(heading).at(it.element.location()),
          )
        ],
      )
    } else {
      // Other references as usual.
      it
    }
  }

  // ===============
  // Frontispice
  // ===============


  grid(
    columns: (auto, 1fr),
    rows: (auto,) * 4,
    row-gutter: 0.75em,
    column-gutter: 0.4em,
    grid.cell(rowspan: 4, image("bicocca-logo-crop.png", height: 5em)),
    smallcaps(text(weight: "thin", langStrings.university)),
    strong(area),
    strong(department),
    strong(course)
  )

  // let imageas(body) = context {
  //   let size = measure(body)
  //   image("bicocca-logo-crop.png", height: size.height)
  // }

  // let tmp = stack(
  //     spacing: 0.65em,
  //     smallcaps(text(weight: "thin", langStrings.university)),
  //     strong(area),
  //     strong(department),
  //     strong(course)
  // )

  // grid(
  //   columns: (auto, 1fr),
  //   column-gutter: 0.4em,
  //   imageas(tmp),
  //   tmp
  // )
  v(4fr)
  align(center, text(1.75em, weight: "medium", title))
  v(5fr)

  [
    *#langStrings.mentor:* #mentor.name \
    #for co-mentor in co-mentors {
      [*#langStrings.co-mentor:* #co-mentor.name \ ]
    }
  ]

  v(1.5fr, weak: true)

  align(right)[
    *#langStrings.thesis:* \
    #author.name \
    matr. #author.matr
  ]
  v(2fr, weak: true)

  align(center)[*#langStrings.academic-year #(scholar-year - 1)-#scholar-year*]
  pagebreak()

  // ===================================
  // Abstract & Outline, Document header
  // ===================================

  // Set non content pages to roman numerals
  set page(numbering: "i")
  counter(page).update(1)
  if abstract != none {
    set text(size: 11pt)
    set par(justify: true)
    smallcaps(align(center, text(weight: "extralight", size: 1.2em, [#langStrings.abstract])))
    align(center, abstract)
    pagebreak()
  }

  outline()
  pagebreak()

  // =================
  // Content body
  // =================

  // Configure paragraph properties.
  set par(spacing: 0.55em, first-line-indent: 0em, justify: true, leading: 0.55em)

  // Reset counter for normal pages
  set page(numbering: "1")
  counter(page).update(1)

  body

  // =================
  // Document trailer
  // =================

  if bibliography != none {
    pagebreak()
    bibliography
  }
}
