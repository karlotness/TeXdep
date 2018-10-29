# TeXdep - Auto dependencies for LaTeX and Make
TeXdep produces Make rules listing dependencies for LaTeX files in a
given project. If you use LaTeX with Make (particularly GNU Make) to
build external figures and other resources, then this script might be
of use.

Currently TeXdep lists files referenced in `\input`, `\include`, and
`\includegraphics` macros.

## Usage
Make sure `texdep.sh` is accessible from your Makefile. The easiest
way to do this is to include it in your project's source code. After
you have done this you need to include it in your Makefile build.

TeXdep locates dependencies in two steps, for each `.tex` source file
a `.texdep` file will be created listing the files referenced in that
file directly. These will then be recursively gathered into a `.d`
dependency file with a Make-formatted rule. A set of rules like those
listed below will use TeXdep to find dependencies, assuming your
Makefile builds `document.pdf` from a set of TeX source files in the
top-level directory.

```make
TEXFILES=$(wildcard *.tex)

include document.d

%.texdep: %.tex texdep.sh
	./texdep.sh dep $< > $@

%.d: $(TEXFILES:.tex=.texdep) texdep.sh
	./texdep.sh gather document.pdf document.texdep > $@
```

These rules should be modified for your particular set of build steps
and can be used alongside `latexmk` to run the LaTeX build step after
all dependencies are up to date. The `%.texdep` rule produces the
dependency lists for each TeX source file. The next rule gathers these
into a Make rule specifying dependencies for `document.pdf` starting
the recursion with the files listed in `document.texdep`.

## Alternatives
One alternative to this script is to use latexmk's `-MF` flag. This
script accomplishes basically the same task except that it looks at
the TeX source itself and does not require TeX to finish with the
project before listing dependencies. This has approach is a bit more
resilient to cases where your project may not fully build when
dependencies are missing and in cases where having latexmk call Make
on its own may be undesirable. However, this also means that system
TeX files will not be listed and that the listing of dependencies is
less thorough.

## License
This project is distributed under the MIT license. The license text is
included in the source file and also in [LICENSE.txt](LICENSE.txt).
