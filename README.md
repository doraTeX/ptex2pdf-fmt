# ptex2pdf-fmt

This is a Bash script for converting Japanese TeX files to PDF with (u)pLaTeX using mylatexformat.

Its function and interface is similar to [`ptex2pdf`](https://github.com/texjporg/ptex2pdf), but this script makes use of [`mylatexformat`](https://ctan.org/pkg/mylatexformat?lang=en) for compilation.

# Usage

```
$ ptex2pdf-fmt.sh [options] basename[.tex]

options:
  -v, -version  version
  -h, -help     help
  -f            (re)generate format file even if it already exists
  -i            ignore format file and compile normally (disables -f)
  -u            use upLaTeX instead of pLaTeX
  -s            stop at dvi
  -ot '<opts>'  extra options for (u)pLaTeX
  -od '<opts>'  extra options for dvipdfmx
  -output-directory '<dir>'   directory for created files
```

# Typical Usage

```sh
$ ptex2pdf-fmt.sh sample
```

This invokes the following commands:

1. `platex -ini -jobname=sample &platex mylatexformat.ltx sample`
1. `platex &sample sample`
1. `dvipdfmx sample`

*Step 1* generates `sample.fmt`, which works as a cache of preamble of `sample.tex`. If there already exists `sample.fmt` in current directory, *Step 1* is omitted.

*Step 2* intends to compile `sample.tex` using `sample.fmt`. Since expansion of preamble is already finished, *Step 2* takes a shorter time than normal compilation.

# Options

## `-f`: (re)generate format file even if it already exists

If you change the contents of preamble, you must regenerate `.fmt` file for the change to take effect.

## `-i`: ignore format file and compile normally

When you use `-i` option, this script does not generate or load `.fmt` file. If you execute `ptex2pdf-fmt.sh -i sample`, this invokes the following commands:

1. `platex "\let\endofdump\relax\input{sample}"`
1. `dvipdfmx sample`

Due to `\let\endofdump\relax`, `\endofdump` in `sample.tex` does not cause the `Undefined control sequence` error. The control sequence `\endofdump`, defined in `mylatexformat.ltx`, is a macro to stop caching.

Other options, like `-ot`, `-od`, have the same functions as `ptex2pdf`.

# Details

For details, see my [blog post (Japanese)](https://doratex.hatenablog.jp/entry/20211206/1638749451).
