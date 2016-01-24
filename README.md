# vim-syntax-noweb

A syntax file for the `noweb` literate programming system.

This syntax file highlights chunks written in arbitrary documentation and code
languages according to their respective syntax definition.

Languages for documentation chunks can be loaded by `:call
noweb#LoadDocLanguages("SYN")`, where `SYN` is the name of a syntax file,
without extension.  Languages for code chunks can be loaded by `:call
noweb#LoadCodeLanguages("SYN")`, where `SYN` is the name of a syntax file,
without extension.  Syntax files identified by the variables
`noweb_doc_languages` and `noweb_code_languages`, which are strings of
comma-separated syntax file names (without extension), are loaded during
initialization.

Regardless of the method of language loading, the syntax that has been loaded
least recently is taken to be the syntax that will be employed by default.

So, putting `let noweb_code_languages="c,cpp,python,r"` into your .vimrc prior
to loading this syntax file will make code languages for C, C++, Python and R
available, with R being the default syntax.

If `noweb_doc_languages` is not defined, it will default to `tex`.
If `noweb_code_languages` is not defined, it will default to `nosyntax`.

Chunks in web files following strict noweb syntax can only be highlighted in
the selected default syntax and all chunks will be highlighted thusly at the
same time.  It is still possible, albeit cumbersome, to work with code chunks
in various different programming languages.  The method is to invoke `:call
noweb#LoadCodeLanguages("SYN")` with SYN set to the syntax that is to be used
for highlighting whenever you switch to a chunk that has a different syntax
than the one you have just been working with.  This will set the default syntax
to `SYN` which will render all code chunks according to that syntax file by
default.

This syntax file offers to optionally recognize a syntax extension that makes
working with heterogeneously typed chunks easier.  If it is enabled, then a
chunk may begin with an option region, which may span several lines.  It is
introduced by `@[` and terminated by `]` and its content is taken to be a comma
separated list of key/value assignments pertaining to the chunk introduced.  If
the pattern `lang=SYN` matches (exactly) one of the options, then vim will
highlight the chunk according to the syntax file `SYN`, if it has been loaded.
Since this places the options into the chunk's content, a custom filter in the
noweb toolchain is required to strip them out again.

This extension can be enabled by the vim variables called
`noweb_doc_options_enabled` and `noweb_code_options_enabled`.
They should be set to "yes" if option recognition is desired.
