#!/bin/bash
#
# Script to compare two text files.
# Leading > is removed from the expected text file lines
# so that we can more easily express the expected text in
# comments.
#

# Instruct bash to be strict about error checking.
set -e          # stop if an error happens
set -u          # stop if an undefined variable is referenced
set -o pipefail # stop if any command within a pipe fails
set -o posix    # extra error checking

declare -r gotFile="$1"
declare -r expectedFile="$2"

diff "${gotFile}" <( sed -e 's/>//' "${expectedFile}" ) | sed -e 's/\( \)$/\1\$/' 1>&2
