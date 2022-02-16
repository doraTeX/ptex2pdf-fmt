#!/bin/bash

# Copyright (c) 2021 Yusuke Terada (doraTeX)
# This file is distributed under the terms of the MIT license, see LICENSE.

SCRIPTNAME=$(basename "$0")
VERSION=0.1

function usage() {
    echo "Usage: $SCRIPTNAME [options] basename[.tex]"
    echo
    echo "options:"
    echo "  -v, -version  version"
    echo "  -h, -help     help"
    echo "  -f            (re)generate format file even if it already exists"
    echo "  -i            ignore format file and compile normally (disables -f)"
    echo "  -u            use upLaTeX instead of pLaTeX"
    echo "  -s            stop at dvi"
    echo "  -ot '<opts>'  extra options for (u)pLaTeX"
    echo "  -od '<opts>'  extra options for dvipdfmx"
    echo "  -output-directory '<dir>'   directory for created files"
    echo
}

function version() {
    echo "$SCRIPTNAME version $VERSION"
}

ENGINE=platex
OUTPUT_DIR=.
FORCE=false
IGNORE_FMT=false
STOP=false

declare -a args=("$@")
declare -a params=()

I=0
while [ $I -lt ${#args[@]} ]; do
    OPT="${args[$I]}"
    case $OPT in
        -h | -help | --help )
            usage
            exit 0
            ;;
        -v | -version | --version )
            version
            exit 0
            ;;
        -ot | --ot )
            if [[ -z "${args[$(($I+1))]}" ]]; then
                echo "$SCRIPTNAME: option requires an argument -- $OPT" 1>&2
                exit 1
            fi
            OPTIONS_FOR_TEX="${args[$(($I+1))]}"
            I=$(($I+1))
            ;;
        -od | --od )
            if [[ -z "${args[$(($I+1))]}" ]]; then
                echo "$SCRIPTNAME: option requires an argument -- $OPT" 1>&2
                exit 1
            fi
            OPTIONS_FOR_DVIPDFMX="${args[$(($I+1))]}"
            I=$(($I+1))
            ;;
        -output-directory | --output-directory )
            if [[ -z "${args[$(($I+1))]}" ]]; then
                echo "$SCRIPTNAME: option requires an argument -- $OPT" 1>&2
                exit 1
            fi
            OUTPUT_DIR="${args[$(($I+1))]}"
            I=$(($I+1))
            ;;
        -u )
            ENGINE=uplatex
            ;;
        -s )
            STOP=true
            ;;
        -f )
            FORCE=true
            ;;
        -i )
            IGNORE_FMT=true
            ;;
        -recorder )
            OPTIONS_FOR_TEX="$OPTIONS_FOR_TEX -recorder"
            ;;
        -- | -)
            I=$(($I+1))
            while [ $I -lt ${#args[@]} ]; do
                params+=("${args[$I]}")
                I=$(($I+1))
            done
            break
            ;;
        -*)
            echo "$SCRIPTNAME: illegal option -- '$(echo $OPT | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [[ ! -z "$OPT" ]] && [[ ! "$OPT" =~ ^-+ ]]; then
                params+=( "$OPT" )
            fi
            ;;
    esac
    I=$(($I+1))
done

if [ ${#params[@]} -eq 0 ]; then
    echo "$SCRIPTNAME: too few arguments" 1>&2
    echo "Try '$SCRIPTNAME --help' for more information." 1>&2
    exit 1
fi

if [ ${#params[@]} -gt 1 ]; then
    echo "Multiple filename arguments? OK, I'll take the last one."
fi

# 対象が複数指定されている場合は ptex2pdf 同様に最後の引数を採用する
TARGET="${params[$((${#params[@]}-1))]}"
BASENAME=$(basename "$TARGET")
BASENAME=${BASENAME%.*}
FMTNAME="$BASENAME.fmt"
PDFNAME="$OUTPUT_DIR/$BASENAME.pdf"

echo "--------------"
echo "LaTeX engine: $ENGINE"
echo "basename: $BASENAME"
echo "format file: $FMTNAME"
echo "options for $ENGINE: $OPTIONS_FOR_TEX"
echo "options for dvipdfmx: $OPTIONS_FOR_DVIPDFMX"
echo "output directory: $OUTPUT_DIR"
echo "output PDF: $PDFNAME"
echo "--------------"

if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

# TeX → DVI
if $IGNORE_FMT; then # 通常コンパイルモード
    $ENGINE -output-directory "$OUTPUT_DIR" $OPTIONS_FOR_TEX "\let\endofdump\relax\input{$TARGET}"
else # フォーマットファイル使用モード
    # フォーマットファイルがない場合，または強制生成モードのときは生成する
    if [ ! -e "$FMTNAME" ] || $FORCE; then
        $ENGINE -ini $OPTIONS_FOR_TEX -jobname="$BASENAME" \&"$ENGINE" mylatexformat.ltx "$TARGET"
        if [ $? -ne 0 ]; then
            exit 1
        fi
    fi
    $ENGINE -output-directory "$OUTPUT_DIR" $OPTIONS_FOR_TEX \&"$BASENAME" "$TARGET"
fi

if [ $? -ne 0 ]; then
    exit 1
fi

# DVI → PDF
if ! $STOP; then
    dvipdfmx -o "$PDFNAME" $OPTIONS_FOR_DVIPDFMX "$OUTPUT_DIR/$BASENAME"
fi
