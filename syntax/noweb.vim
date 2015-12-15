" Vim syntax file
" Language:	noweb
" Filenames:	*.nw
" Maintainer:	Markus Schöngart <markus@schoengart.net>
" Last Change:	2015 Dec 15 - Initial version.
" License:	Public Domain
"
" A syntax file for the `noweb' literate programming system.
"
" Actually, a small extension of noweb's syntax is recognized, as follows.
"
" The leading `@' that introduces documentation chunks may optionally be
" followed by a region enclosed in square brackets (`[' ... `]'), the content
" of which are taken to be comma separated options pertaining to the
" documentation chunk introduced. If the pattern `lang=SYN' matches (exactly)
" one of the options, then vim will highlight the chunk according to the syntax
" file `SYN', if it has been loaded. The preamble cannot have options since it
" is not introduced explicitly.
" For example, `@[lang=tex] This is to be highlighted as \TeX{}'.
"
" Similarly, the pattern `<<...>>=' that introduces code chunks may optionally
" contain an option region (as in `<<... [OPTS]>>='). It, too, may contain the
" `lang=SYN' option and if it does, vim will highlight the code chunk according
" to the syntax file `SYN', if it has been loaded.
" For example, `<<Do Something [lang=cpp]>>=' introduces a C++ code chunk.
"
" Documentation languages can be loaded by `:call noweb#LoadDocLanguages("SYN")',
" where `SYN' is the name of a syntax file, without extension.
" Code languages can be loaded by `:call noweb#LoadCodeLanguages("SYN")',
" where `SYN' is the name of a syntax file, without extension.
" Syntax files identified by the variables `noweb_doc_languages' and
" `noweb_code_languages', which are strings of comma-separated syntax file
" names (without extension), are loaded during initialization.
"
" Regardless of the method of language loading, the syntax that has been loaded
" least recently is taken to be the default syntax that will be employed
" whenever a chunk is missing the `lang=SYN' option.
"
" So, putting `let noweb_code_languages="c,cpp,python,r"' into your .vimrc
" prior to loading this syntax file will make code languages for C, C++, Python
" and R available, where R is the syntax that will be assumed for all chunks
" missing a suitable option.
"
" If `noweb_doc_languages' is not defined, it will default to `tex'.
" If `noweb_code_languages' is not defined, it will default to `nosyntax'.
"
" It is possible to work with files following strict noweb syntax (without
" `lang=SYN' options) and still highlight various different code languages
" (although not at the same time). The method is to invoke `:call
" noweb#LoadCodeLanguages("SYN")' with SYN set to the syntax that is to be used
" for highlighting whenever you switch to a chunk that has a different syntax
" than the one you have just been working with.  This will set the default
" syntax to `SYN' which will render all code chunks with unidentified languages
" according to that syntax file.

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Define our top-level syntax items, nowebPreamble and nowebChunk.
" The preamble begins at the beginning of the file and ranges to the first
" chunk marker. Any other chunk is started by a chunk marker and ranges to the
" next one or the end of the file, whichever comes first.
" These items are `containedin=ALLBUT,<themselves>' since chunks cannot be
" nested.
" They are `keepend' so that further levels of syntax regions may match until
" the end of the document (`\%$') and need not repeat all the chunk markers,
" reducing some duplication.
" They are `fold' to enable the user to fold exactly at chunk boundaries.
" They are `transparent' because highlighting is done in the next level and
" beyond, which descriminates between documentation and code chunks.
syntax region nowebPreamble
	\ start="\%^"
	\ end="\(\%$\|^@\(\[[^]]*\]\)\?\(\s\|$\)\|^<<.*>>=$\)"me=s-1,he=s-1,re=s-1
	\ contains=nowebDocChunkDefaultDoc
	\ keepend fold transparent
syntax region nowebChunk
	\ start="\(^@\(\[[^]]*\]\)\?\(\s\|$\)\|^<<.*>>=$\)"
	\ end="\(^@\(\[[^]]*\]\)\?\(\s\|$\)\|^<<.*>>=$\|\%$\)"me=s-1,he=s-1,re=s-1
	\ containedin=ALLBUT,nowebPreamble,nowebChunk
	\ contains=nowebDocChunk,nowebCodeChunk
	\ keepend fold transparent

" Generally, the region named `nowebDocChunkSYN' defines the documentation
" chunk for language `SYN'.  The region named `nowebDocChunkDefault' denotes
" the default documentation syntax that is active when no `lang=SYN' option
" (for a loaded language) is given.
syntax region nowebDocChunkDefault
	\ start="^@\(\[[^]]*\]\)\?\(\s\|$\)"
	\ end="\%$"
	\ contained containedin=nowebChunk
	\ contains=nowebDocChunkDef,nowebDocChunkDefaultDoc
	\ transparent

" The cluster `nowebDocChunk' contains all loaded documentation chunk regions.
syntax cluster nowebDocChunk contains=nowebDocChunkDefault

" Load new documentation languages and set the last one as default.  This
" function accepts variadic arguments and expects each argument to be a string
" denoting a syntax file name, without extension.
" Example: `:call noweb#LoadDocLanguages("tex", "html")'
function noweb#LoadDocLanguages(...)
	for syntax in a:000
		" Undefine `b:current_syntax' so we don't confuse the syntax
		" script we're going to load.
		if exists("b:current_syntax")
			unlet b:current_syntax
		endif

		execute "syntax include @nowebDocChunk" . syntax . "Syntax syntax/" . syntax . ".vim"

		" Restore `b:current_syntax' according to the conventions.
		let b:current_syntax = "noweb"

		" Define the region `nowebDocChunkSYN' for syntax named `SYN'.
		" It contains the `nowebDocChunkDef', which highlights the
		" documentation chunk's introduction, as well as the region
		" `nowebDocChunkSYNDoc', which recognizes the documentation's
		" actual syntax (`SYN').
		execute "syntax region nowebDocChunk" . syntax
			\ . " start=/^@\\(\\[\\([^]]*,\\)*lang=" . syntax . "\\(,[^]]*\\)*\\]\\)\\?\\(\\s\\|$\\)/"
			\ . " end=/\\%$/"
			\ . " contained containedin=nowebChunk"
			\ . " contains=nowebDocChunkDef,nowebDocChunk" . syntax . "Doc"
			\ . " transparent"

		" Create both the `nowebDocChunkSYNChunk' as well as the
		" default region `nowebDocChunkDefaultDoc' and make it
		" recognize the requested language. Re-creating the region for
		" the default syntax has the effect that chunks that omit a
		" suitable `lang=SYN' option are matched to this syntax, too.
		for name in [ syntax, "Default" ]
			execute "syntax region nowebDocChunk" . name . "Doc"
				\ . " start=/.\\@=/"
				\ . " end=/\\%$/"
				\ . " contained containedin=nowebDocChunk" . name
				\ . " contains=@nowebDocChunk" . syntax . "Syntax"
		endfor

		execute "syntax cluster nowebDocChunk add=nowebDocChunk" . syntax

		" Although `nowebDocChunkDef' and `nowebDocChunkOpts' both do
		" not depend on the syntax being loaded, we still re-create
		" them here to keep their priority high.  If we don't do that,
		" vim will attempt to apply the actual documentation syntax to
		" the chunk's introduction.
	
		syntax region nowebDocChunkDef
			\ matchgroup=nowebDocChunkDelimiter
			\ start="^@\(\[\)\?"rs=s+1
			\ end="\(\]\)\?\(\s\|$\)"re=s
			\ contained containedin=nowebDocChunk
			\ contains=nowebDocChunkOpts
			\ oneline

		syntax region nowebDocChunkOpts
			\ start="\["
			\ end="\]"
			\ contained containedin=nowebDocChunkDef
			\ oneline
	endfor
endfunction

" Load the requested documentation languages or default to `tex'.
if exists("noweb_doc_languages")
	for language in split(noweb_doc_languages, ",")
		call noweb#LoadDocLanguages(language)
	endfor
else
	call noweb#LoadDocLanguages("tex")
endif

" Generally, the region named `nowebCodeChunkSYN' defines the code chunk for
" language `SYN'.  The region named `nowebCodeChunkDefault' denotes the default
" code syntax that is active when no `lang=SYN' option (for a loaded language)
" is given.
syntax region nowebCodeChunkDefault
	\ start="^<<.*>>=$"
	\ end="\%$"
	\ contained containedin=nowebChunk
	\ contains=nowebCodeChunkDef,nowebCodeChunkDefaultCode
	\ transparent

" The cluster `nowebCodeChunk' contains all loaded code chunk regions
" (including the chunk introduction) and the cluster `nowebCodeChunkCode'
" contains all regions of actual code language blocks, excluding the chunk
" intruduction (`<<.*>>=').
syntax cluster nowebCodeChunk contains=nowebCodeChunkDefault
syntax cluster nowebCodeChunkCode contains=nowebCodeChunkDefaultCode

" Load new code languages and set the last one as default.  This function
" accepts variadic arguments and expects each argument to be a string denoting
" a syntax file name, without extension.
" Example: `:call noweb#LoadCodeLanguages("c", "cpp", "python", "r")'
function noweb#LoadCodeLanguages(...)
	for syntax in a:000
		" Undefine `b:current_syntax' so we don't confuse the syntax
		" script we're going to load.
		if exists("b:current_syntax")
			unlet b:current_syntax
		endif

		execute "syntax include @nowebCodeChunk" . syntax . "Syntax syntax/" . syntax . ".vim"

		" Restore `b:current_syntax' according to the conventions.
		let b:current_syntax = "noweb"

		" Define the region `nowebCodeChunkSYN' for syntax named `SYN'.
		" It contains the `nowebCodeChunkDef', which highlights the
		" code chunk's introduction, as well as the region
		" `nowebCodeChunkSYNDoc', which recognizes the code's actual
		" syntax (`SYN').
		execute "syntax region nowebCodeChunk" . syntax
			\ . " start=/^<<.*\\[\\([^]]*,\\)*lang=" . syntax . "\\(,[^]]*\\)*\\]>>=$/"
			\ . " end=/\\%$/"
			\ . " contained containedin=nowebChunk"
			\ . " contains=nowebCodeChunkDef,nowebCodeChunk" . syntax . "Code"
			\ . " transparent"

		" Create both the `nowebCodeChunkSYNChunk' as well as the
		" default region `nowebCodeChunkDefaultCode' and make it
		" recognize the requested language. Re-creating the region for
		" the default syntax has the effect that chunks that omit a
		" suitable `lang=SYN' option are matched to this syntax, too.
		for name in [ syntax, "Default" ]
			execute "syntax region nowebCodeChunk" . name . "Code"
				\ . " start=/.\\@=/"
				\ . " end=/\\%$/"
				\ . " contained containedin=nowebCodeChunk" . name
				\ . " contains=nowebCodeChunkRef,@nowebCodeChunk" . syntax . "Syntax"
		endfor

		execute "syntax cluster nowebCodeChunk add=nowebCodeChunk" . syntax
		execute "syntax cluster nowebCodeChunkCode add=nowebCodeChunk" . syntax . "Code"

		" Although `nowebCodeChunkDef' and `nowebCodeChunkOpts' both do
		" not depend on the syntax being loaded, we still re-create
		" them here to keep their priority high.  If we don't do that,
		" vim will attempt to apply the actual documentation syntax to
		" the chunk's introduction.
		" Similarly, if we don't recreate `nowebCodeChunkRef' then the
		" code chunk references (`<<...>>') will be highlighted
		" according to the code syntax, instead of noweb's meta syntax.

		syntax region nowebCodeChunkDef
			\ matchgroup=nowebCodeChunkDelimiter
			\ start="^<<"rs=e
			\ end=">>=$"re=s
			\ contained containedin=nowebCodeChunk
			\ contains=nowebCodeChunkOpts
			\ oneline

		syntax region nowebCodeChunkRef
			\ matchgroup=nowebCodeChunkDelimiter
			\ start="^\s*<<"hs=e-2,rs=e
			\ end=">>\s*$"he=s+2,re=s
			\ contains=nowebCodeChunkOpts
			\ oneline

		syntax region nowebCodeChunkOpts
			\ start="\s*\["ms=e,hs=e,rs=e
			\ end="\]>>"me=s,he=s,re=s
			\ contained containedin=nowebCodeChunkDef
			\ oneline
	endfor
endfunction

" Load the requested code languages or none at all.
if exists("noweb_code_languages")
	for language in split(noweb_code_languages, ",")
		call noweb#LoadCodeLanguages(language)
	endfor
else
	call noweb#LoadCodeLanguages("nosyntax")
endif

highlight link nowebDocChunkDelimiter		nowebDelimiter
highlight link nowebDocChunkOpts		nowebChunkOpts

highlight link nowebCodeChunkDelimiter		nowebDelimiter
highlight link nowebCodeChunkDef		nowebCodeChunkName
highlight link nowebCodeChunkRef		nowebCodeChunkName
highlight link nowebCodeChunkOpts		nowebChunkOpts

highlight link nowebDelimiter			Delimiter
highlight link nowebCodeChunkName		Function
highlight link nowebChunkOpts			Comment

let b:current_syntax = "noweb"
