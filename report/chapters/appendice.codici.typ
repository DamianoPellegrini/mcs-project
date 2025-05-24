#import "../packages.typ": codly, codly-languages

#show: codly.codly-init
#codly.codly(languages: codly-languages.codly-languages)

= Appendice Codici

#let code-counter = counter("figure")
#code-counter.step()


#let cpp_files = (
  ("../../src/main.cpp", "main"),
)

#let matlab_files = (
  ("../../matlab/main.m", "main"),
  ("../../matlab/getProfileResults.m", "helper function"),
  ("../../matlab/sparse_lib_versions.m", "sparse lib versions"),
)
#let createCodeBlock(file, language, label) = {
  let code = read(file)
  code = code.replace("loadMem,", "loadMem,\n")
  let fileName = file.split("/").last()
  block(
    [
      #align(center)[File: #fileName]
      #raw(code, block: true, lang: language)
      #if label != "" {
        align(center)[Codice #context code-counter.get().at(0): #label]
      } else {
        align(center)[Codice #context code-counter.get().at(0)]
      }
      #code-counter.step()
    ]
  )
}

== C++ e CMake

#for (file, label) in cpp_files {
  createCodeBlock(file, "cpp", label)
}

#createCodeBlock("../../CMakeLists.txt", "cmake", "")

== MATLAB

#for (file, label) in matlab_files {
  createCodeBlock(file, "matlab", label)
}
