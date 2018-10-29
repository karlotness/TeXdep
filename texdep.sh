#! /usr/bin/env bash
# Copyright (C) 2018 Karl Otness

version="v0.0.1"

print_usage() {
    cat <<EOF
texdep - Automatic Makefile dependencies for LaTeX

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
    echo "# File produced by texdep $version ($(date))"
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
       exit 4
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
    print_usage
    exit 1
elif [[ "$1" == "dep" ]]; then
    if [[ "$#" -ne 2 ]]; then
        print_usage
        exit 2
    elif [[ ! -r "$2" ]]; then
        echo "File '$2' not readable"
        exit 3
    fi
    dep_scan_file "$2"
elif [[ "$1" == "gather" ]]; then
    if [[ "$#" -lt 3 ]]; then
        print_usage
        exit 2
    elif [[ ! -r "$3" ]]; then
        echo "File '$3' not readable"
        exit 3
    fi
    suffix=".texdep"
    if [[ $# -gt 3 ]]; then
        suffix="$4"
    fi
    gather_file "$2" "$3" "$suffix"
fi
