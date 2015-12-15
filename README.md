# vim-syntax-noweb

A syntax file for the `noweb' literate programming system.

Actually, a small extension of noweb's syntax is recognized, as follows.

The leading `@` that introduces documentation chunks may optionally be followed
by a region enclosed in square brackets (`'[' ... ']'`), the content of which
are taken to be comma separated options pertaining to the documentation chunk
introduced. If the pattern `lang=SYN` matches (exactly) one of the options,
then vim will highlight the chunk according to the syntax file `SYN`, if it has
been loaded. The preamble cannot have options since it is not introduced
explicitly.
For example, `@[lang=tex] This is to be highlighted as \TeX{}`.

Similarly, the pattern `'<<' ... '>>='` that introduces code chunks may
optionally contain an option region (as in `'<<' ... '[' OPTS ']' '>>='`).
It, too, may contain the `lang=SYN` option and if it does, vim will highlight
the code chunk according to the syntax file `SYN`, if it has been loaded.
For example, `<<Do Something [lang=cpp]>>=` introduces a C++ code chunk.

Documentation languages can be loaded by `:call noweb#LoadDocLanguages("SYN")`,
where `SYN` is the name of a syntax file, without extension.
Code languages can be loaded by `:call noweb#LoadCodeLanguages("SYN")`,
where `SYN` is the name of a syntax file, without extension.
Syntax files identified by the variables `noweb_doc_languages` and
`noweb_code_languages`, which are strings of comma-separated syntax file
names (without extension), are loaded during initialization.

Regardless of the method of language loading, the syntax that has been loaded
least recently is taken to be the default syntax that will be employed
whenever a chunk is missing the `lang=SYN` option.

So, putting `let noweb_code_languages="c,cpp,python,r"` into your .vimrc
prior to loading this syntax file will make code languages for C, C++, Python
and R available, where R is the syntax that will be assumed for all chunks
missing a suitable option.

If `noweb_doc_languages` is not defined, it will default to `tex`.
If `noweb_code_languages` is not defined, it will default to `nosyntax`.

It is possible to work with files following strict noweb syntax (without
`lang=SYN` options) and still highlight various different code languages
(although not at the same time). The method is to invoke `:call
noweb#LoadCodeLanguages("SYN")` with SYN set to the syntax that is to be used
for highlighting whenever you switch to a chunk that has a different syntax
than the one you have just been working with.  This will set the default
syntax to `SYN` which will render all code chunks with unidentified languages
according to that syntax file.
