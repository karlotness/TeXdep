#! /usr/bin/env bash
#
# Copyright (c) 2018 Karl Otness
#
# This file contains TeXdep, an automatic dependency printer for
# LaTeX. TeXdep is distributed under the MIT license, a copy of which
# has been included below.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

version="v0.0.1"

print_usage() {
    cat <<EOF
TeXdep $version - Automatic Makefile dependencies for LaTeX

Usage: texdep SUBCOMMAND OPTIONS...

Subcommands:
- dep: list single-file dependencies
- gather: recursively gather multi-file dependencies in Make format

Usage for dep:
  texdep dep FILE

- FILE: LaTeX source file to scan

Usage for gather:
  texdep gather RULE_NAME ROOT_DEP_FILE [SUFFIX]

- RULE_NAME: Name of Make rule to produce
- ROOT_DEP_FILE: Starting dependency list file to read (from dep)
- SUFFIX: suffix with which to replace ".tex" when recursively searching for dep files
EOF
}

print_header() {
    echo "# File produced by TeXdep $version ($(date))"
}

dep_scan_file() {
    file="$1"
    print_header
    # Find input and include macros
    sed -n 's/^.*\\\(input\|include\){\(.*\)}/\2/p' "$file"
    # Find includegraphics macros
    sed -n 's/^.*\\\(includegraphics\)\(\[.*\]\)*{\(.*\)}/\3/p' "$file"
}

rec_gather_file() {
    file="$1"
    suffix="$2"
    if [[ ! -r "$file" ]]; then
       echo "# ERROR: File '$file' not readable"
       exit 2
    fi
    while read -r line; do
        if [[ "$line" =~ ^# ]]; then
            continue
        fi
        echo "  $line \\"
        if [[ "$line" =~ ^(.*)\.tex$ ]]; then
            rec_gather_file "${BASH_REMATCH[1]}$suffix"
        fi
    done < "$file"
}

gather_file() {
    rule_name="$1"
    root_file="$2"
    suffix="$3"
    print_header
    echo ""
    echo "$rule_name: \\"
    rec_gather_file "$root_file" "$suffix"
    echo ""
}

if [[ "$#" -lt 1 ]]; then
    # No arguments, print usage
    print_usage
    exit 1
fi
case "$1" in
    -h|--help)
        print_usage
        exit 0
        ;;
    "dep")
        # Dependency subcommand
        if [[ "$#" -ne 2 ]]; then
            print_usage
            exit 1
        elif [[ ! -r "$2" ]]; then
            echo "File '$2' not readable"
            exit 2
        fi
        dep_scan_file "$2"
        ;;
    "gather")
        # Gather subcommand
        if [[ "$#" -lt 3 ]]; then
            print_usage
            exit 1
        elif [[ ! -r "$3" ]]; then
            echo "File '$3' not readable"
            exit 2
        fi
        suffix=".texdep"
        if [[ $# -gt 3 ]]; then
            suffix="$4"
        fi
        gather_file "$2" "$3" "$suffix"
        ;;
esac
