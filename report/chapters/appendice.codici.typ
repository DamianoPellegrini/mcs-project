#import "../packages.typ": codly, codly-languages

#show: codly.codly-init
#codly.codly(languages: codly-languages.codly-languages, breakable: true)

#let code-counter = counter("figure")
#code-counter.step()

#let cpp_files = (
  ("../../src/main.cpp", "Entrypoint C++"),
)

#let matlab_files = (
  ("../../matlab/main.m", "Entrypoint MATLAB"),
  ("../../matlab/getProfileResults.m", "MATLAB helper functions"),
  ("../../matlab/sparse_lib_versions.m", "MATLAB Sparse librares info"),
)

#let createCodeBlock(file, language, label) = {
  let code = read(file)
  code = code.replace("loadMem,", "loadMem,\n")
  let fileName = file.split("/").last()
  show figure: set block(breakable: true)
  figure(
    caption: [#label. File: #fileName],
    supplement: [Codice],
    kind: "code",
    raw(code, block: true, lang: language, tab-size: 2),
  )
  pagebreak(weak: true)
}

= Codici

#outline(target: figure.where(kind: "code"))

== C++ e CMake

#for (file, label) in cpp_files {
  createCodeBlock(file, "cpp", label)
}

#createCodeBlock("../../CMakeLists.txt", "cmake", "Project configuration")

== MATLAB

#for (file, label) in matlab_files {
  createCodeBlock(file, "matlab", label)
}
