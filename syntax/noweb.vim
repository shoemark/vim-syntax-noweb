" Vim syntax file
" Language:	noweb
" Filenames:	*.nw
" Maintainer:	Markus Schöngart (https://github.com/shoemark)
" Last Change:	2016 Jan 24 - Recognizing chunk options is now optional.
"		2015 Dec 15 - Initial version.
" License:	Public Domain
"
" A syntax file for the `noweb' literate programming system.
"
" This syntax file highlights chunks written in arbitrary documentation and
" code languages according to their respective syntax definition.
"
" Languages for documentation chunks can be loaded by `:call
" noweb#LoadDocLanguages("SYN")', where `SYN' is the name of a syntax file,
" without extension.  Languages for code chunks can be loaded by `:call
" noweb#LoadCodeLanguages("SYN")', where `SYN' is the name of a syntax file,
" without extension.  Syntax files identified by the variables
" `noweb_doc_languages' and `noweb_code_languages', which are strings of
" comma-separated syntax file names (without extension), are loaded during
" initialization.
"
" Regardless of the method of language loading, the syntax that has been loaded
" least recently is taken to be the syntax that will be employed by default.
"
" So, putting `let noweb_code_languages="c,cpp,python,r"' into your .vimrc
" prior to loading this syntax file will make code languages for C, C++, Python
" and R available, with R being the default syntax.
"
" If `noweb_doc_languages' is not defined, it will default to `tex'.
" If `noweb_code_languages' is not defined, it will default to `nosyntax'.
"
" Chunks in web files following strict noweb syntax can only be highlighted in
" the selected default syntax and all chunks will be highlighted thusly at the
" same time.  It is still possible, albeit cumbersome, to work with code
" chunks in various different programming languages.  The method is to invoke
" `:call noweb#LoadCodeLanguages("SYN")' with SYN set to the syntax that is to
" be used for highlighting whenever you switch to a chunk that has a different
" syntax than the one you have just been working with.  This will set the
" default syntax to `SYN' which will render all code chunks according to that
" syntax file by default.
"
" This syntax file offers to optionally recognize a syntax extension that
" makes working with heterogeneously typed chunks easier.  If it is enabled,
" then a chunk may begin with an option region, which may span several lines.
" It is introduced by `@[' and terminated by `]' and its content is taken to
" be a comma separated list of key/value assignments pertaining to the chunk
" introduced.  If the pattern `lang=SYN' matches (exactly) one of the options,
" then vim will highlight the chunk according to the syntax file `SYN', if it
" has been loaded.
" Since this places the options into the chunk's content, a custom filter in
" the noweb toolchain is required to strip them out again.
"
" This extension can be enabled by the vim variables called
" `noweb_doc_options_enabled' and 'noweb_code_options_enabled'.
" They should be set to "yes" if option recognition is desired.
"

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
" They are `transparent' because highlighting is done at lower levels.
syntax region nowebPreamble
	\ start="\%^"
	\ end="\(\%$\|^@\(\s\|\_$\)\|^<<.*>>=$\)"me=s-1,he=s-1,re=s-1
	\ contains=nowebDocChunkDefault
	\ keepend fold transparent
syntax region nowebChunk
	\ start="\(^@\(\s\|\_$\)\|^<<.*>>=$\)"
	\ end="\(^@\(\s\|\_$\)\|^<<.*>>=$\|\%$\)"me=s-1,he=s-1,re=s-1
	\ containedin=ALLBUT,nowebPreamble,nowebChunk
	\ contains=nowebDocChunkIntro,nowebCodeChunkIntro
	\ keepend fold transparent

" All documentation chunks are contained in a `nowebDocChunkIntro' region.
" It contains a `nowebDocChunkDef' child region, which regards the chunk's
" introduction (matching the regular expression `^@(\s|$)') as region and
" highlights it. (This is slightly silly in this case but is retained for
" syntactical similarity to the code chunks' representation).
" The `nowebDocChunk' cluster is also contained.  It represents the set of all
" types of documentation chunks, one for the default type
" (`nowebDocChunkDefault') and one for each documentation syntax that has been
" loaded.
syntax region nowebDocChunkIntro
	\ start="^@\(\s\|\_$\)"
	\ end="\%$"
	\ contained containedin=nowebChunk
	\ contains=nowebDocChunkDef,nowebDocChunk
	\ transparent

" Generally, the region named `nowebDocChunkSYN' defines the documentation
" chunk for language `SYN'.  The region named `nowebDocChunkDefault' denotes
" the default documentation syntax that is active when no `lang=SYN' option
" (for a loaded language `SYN') is given.
syntax region nowebDocChunkDefault
	\ start=".\@="
	\ end="\%$"
	\ contained containedin=nowebDocChunkIntro
	\ contains=nowebDocChunkOpts,nowebDocChunkDefaultDoc
	\ transparent

" The cluster `nowebDocChunk' contains all loaded documentation chunk regions,
" including chunk options.  The cluster `nowebDocChunkDoc' contains all
" regions pertaining to loaded documentation languages.
syntax cluster nowebDocChunk contains=nowebDocChunkDefault
syntax cluster nowebDocChunkDoc contains=nowebDocChunkDefaultDoc

" Load new documentation languages and set the last one as default.  This
" function accepts variadic arguments and expects each argument to be a string
" denoting a syntax file name, without extension.
" Example: `:call noweb#LoadDocLanguages("tex", "html")'
function! noweb#LoadDocLanguages(...)
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
		" It contains the `nowebDocChunkOpts', which highlights the
		" documentation chunk's options, as well as the region
		" `nowebDocChunkSYNDoc', which recognizes the documentation's
		" actual syntax (`SYN').
		" Generation of this region is supressed if strict noweb
		" compatibility is requested.
		if exists("g:noweb_doc_options_enabled") && g:noweb_doc_options_enabled ==? "yes"
			execute "syntax region nowebDocChunk" . syntax
				\ . " start=/@\\[\\_s*\\([^]]\\+\\_s*,\\_s*\\)*lang=" . syntax . "\\(\\_s*,\\_s*[^]]\\+\\)*\\_s*\\]/"
				\ . " end=/\\%$/"
				\ . " contained containedin=nowebDocChunkIntro"
				\ . " contains=nowebDocChunkOpts,nowebDocChunk" . syntax . "Doc"
				\ . " transparent"
		endif

		" Create both the `nowebDocChunkSYNDoc' as well as the default
		" region `nowebDocChunkDefaultDoc' and make it recognize the
		" requested language. Re-creating the region for the default
		" syntax has the effect that chunks that omit a suitable
		" `lang=SYN' option are from now on matched to this syntax,
		" too.
		for name in [ syntax, "Default" ]
			execute "syntax region nowebDocChunk" . name . "Doc"
				\ . " start=/.\\@=/"
				\ . " end=/\\%$/"
				\ . " contained containedin=nowebDocChunk" . name
				\ . " contains=@nowebDocChunk" . syntax . "Syntax"
		endfor

		execute "syntax cluster nowebDocChunk add=nowebDocChunk" . syntax
		execute "syntax cluster nowebDocChunkDoc add=nowebDocChunk" . syntax . "Doc"

		" Although `nowebDocChunkDef' and `nowebDocChunkOpts' both do
		" not depend on the syntax being loaded, we still re-create
		" them here to keep their priority high.  If we don't do that,
		" vim will attempt to apply the actual documentation syntax to
		" the chunk's introduction.
	
		syntax region nowebDocChunkDef
			\ matchgroup=nowebDocChunkDelimiter
			\ start="^@"rs=e
			\ end="\(\s\|\_$\)"re=s
			\ contained containedin=nowebDocChunkIntro
			\ nextgroup=nowebDocChunk

		if exists("g:noweb_doc_options_enabled") && g:noweb_doc_options_enabled ==? "yes"
			syntax region nowebDocChunkOpts
				\ matchgroup=nowebDocChunkOptsDelimiter
				\ start="@\["rs=e
				\ end="@\@1<!\]"re=s
				\ contained containedin=nowebDocChunk
		endif
	endfor
endfunction

" Load the requested documentation languages or default to `tex'.
if exists("g:noweb_doc_languages")
	for language in split(g:noweb_doc_languages, ",")
		call noweb#LoadDocLanguages(language)
	endfor
else
	call noweb#LoadDocLanguages("tex")
endif

" All code chunks are contained in a `nowebCodeChunkIntro' region.
" It contains a `nowebCodeChunkDef' child region, which regards the chunk's
" introduction (matching the regular expression `^<<.*>>=$') as region and
" highlights it.
" The `nowebCodeChunk' cluster is also contained.  It represents the set of
" all types of code chunks, one for the default type (`nowebCodeChunkDefault')
" and one for each code syntax that has been loaded.
syntax region nowebCodeChunkIntro
	\ start="^<<.*>>=$"
	\ end="\%$"
	\ contained containedin=nowebChunk
	\ contains=nowebCodeChunkDef,nowebCodeChunk
	\ transparent

" Generally, the region named `nowebCodeChunkSYN' defines the code chunk for
" language `SYN'.  The region named `nowebCodeChunkDefault' denotes the
" default code syntax that is active when no `lang=SYN' option (for a loaded
" language `SYN') is given.
syntax region nowebCodeChunkDefault
	\ start=".\@="
	\ end="\%$"
	\ contained containedin=nowebCodeChunkIntro
	\ contains=nowebCodeChunkOpts,nowebCodeChunkDefaultCode
	\ transparent

" The cluster `nowebCodeChunk' contains all loaded code chunk regions,
" including chunk options.  The cluster `nowebCodeChunkCode' contains all
" regions pertaining to loaded code languages.
syntax cluster nowebCodeChunk contains=nowebCodeChunkDefault
syntax cluster nowebCodeChunkCode contains=nowebCodeChunkDefaultCode

" Load new code languages and set the last one as default.  This function
" accepts variadic arguments and expects each argument to be a string denoting
" a syntax file name, without extension.
" Example: `:call noweb#LoadCodeLanguages("c", "cpp", "python", "r")'
function! noweb#LoadCodeLanguages(...)
	for syntax in a:000
		" Undefine `b:current_syntax' so we don't confuse the syntax
		" script we're going to load.
		if exists("b:current_syntax")
			unlet b:current_syntax
		endif

		execute "syntax include @nowebCodeChunk" . syntax . "Syntax syntax/" . syntax . ".vim"

		" Restore `b:current_syntax' according to the conventions.
		let b:current_syntax = "noweb"

		" Define the region `nowebCodeChunkSYN' for syntax named
		" `SYN'.  It contains the `nowebCodeChunkOpts', which
		" highlights the code chunk's options, as well as the region
		" `nowebCodeChunkSYNCode', which recognizes the code's actual
		" syntax (`SYN').
		" Generation of this region is supressed if strict noweb
		" compatibility is requested.
		if exists("g:noweb_code_options_enabled") && g:noweb_code_options_enabled ==? "yes"
			execute "syntax region nowebCodeChunk" . syntax
				\ . " start=/^@\\[\\_s*\\([^]]\\+\\_s*,\\_s*\\)*lang=" . syntax . "\\(\\_s*,\\_s*[^]]\\+\\)*\\_s*\\]/"
				\ . " end=/\\%$/"
				\ . " contained containedin=nowebCodeChunkIntro"
				\ . " contains=nowebCodeChunkOpts,nowebCodeChunk" . syntax . "Code"
				\ . " transparent"
		endif

		" Create both the `nowebCodeChunkSYNCode' as well as the
		" default region `nowebCodeChunkDefaultCode' and make it
		" recognize the requested language. Re-creating the region for
		" the default syntax has the effect that chunks that omit a
		" suitable `lang=SYN' option are from now on matched to this
		" syntax, too.
		for name in [ syntax, "Default" ]
			execute "syntax region nowebCodeChunk" . name . "Code"
				\ . " start=/.\\@=/"
				\ . " end=/\\%$/"
				\ . " contained containedin=nowebCodeChunk" . name
				\ . " contains=nowebCodeChunkRef,@nowebCodeChunk" . syntax . "Syntax"
		endfor

		execute "syntax cluster nowebCodeChunk add=nowebCodeChunk" . syntax
		execute "syntax cluster nowebCodeChunkCode add=nowebCodeChunk" . syntax . "Code"

		" Although `nowebCodeChunkDef' and `nowebCodeChunkOpts' both
		" do not depend on the syntax being loaded, we still re-create
		" them here to keep their priority high.  If we don't do that,
		" vim will attempt to apply the actual code syntax to the
		" chunk's introduction.
		" Similarly, if we don't recreate `nowebCodeChunkRef' then the
		" code chunk references (`<<...>>') will be highlighted
		" according to the code syntax, instead of noweb's meta syntax.

		syntax region nowebCodeChunkDef
			\ matchgroup=nowebCodeChunkDelimiter
			\ start="^<<"rs=e
			\ end=">>=$"re=s
			\ contained containedin=nowebCodeChunkIntro
			\ nextgroup=nowebCodeChunk
			\ oneline

		if exists("g:noweb_code_options_enabled") && g:noweb_code_options_enabled ==? "yes"
			syntax region nowebCodeChunkOpts
				\ matchgroup=nowebCodeChunkOptsDelimiter
				\ start="@\["rs=e
				\ end="@\@1<!\]"re=s
				\ contained containedin=nowebCodeChunk
		endif

		syntax region nowebCodeChunkRef
			\ matchgroup=nowebCodeChunkDelimiter
			\ start="^\s*<<"hs=e-2,rs=e
			\ end=">>\s*$"he=s+2,re=s
			\ oneline
	endfor
endfunction

" Load the requested code languages or none at all.
if exists("g:noweb_code_languages")
	for language in split(g:noweb_code_languages, ",")
		call noweb#LoadCodeLanguages(language)
	endfor
else
	call noweb#LoadCodeLanguages("nosyntax")
endif

highlight link nowebDocChunkOptsDelimiter	nowebDelimiter
highlight link nowebDocChunkDelimiter		nowebDelimiter
highlight link nowebDocChunkOpts		nowebChunkOpts

highlight link nowebCodeChunkOptsDelimiter	nowebDelimiter
highlight link nowebCodeChunkDelimiter		nowebDelimiter
highlight link nowebCodeChunkDef		nowebCodeChunkName
highlight link nowebCodeChunkRef		nowebCodeChunkName
highlight link nowebCodeChunkOpts		nowebChunkOpts

highlight link nowebDelimiter			Delimiter
highlight link nowebCodeChunkName		Function
highlight link nowebChunkOpts			Comment

let b:current_syntax = "noweb"
