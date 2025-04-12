#!/bin/bash
#
# Script to shift all lines of a file to the left
# so that initial leading spaces are removed.
# Note that all leading space on all lines is not removed.
# The indentation of the file will remain intact.
#
# This script only removes spaces.  It treats a tab as a
# regular non-space character.
#
# Examples:
#   Input:
#      Hello World
#   Output: -
#   Hello World
#
#   -----
#
#   Input:
#      yaml:
#        - 5
#        - "text"
#
#      foo:
#        - "bar"
#
#   Output: -
#
#   yaml:
#     - 5
#     - "text"
#
#   foo:
#     - "bar"

# Instruct bash to be strict about error checking.
set -e          # stop if an error happens
set -u          # stop if an undefined variable is referenced
set -o pipefail # stop if any command within a pipe fails
set -o posix    # extra error checking

declare -r filename="${1:-}"
declare -r tempFile="$(mktemp)"
declare -r workFile="${filename:-${tempFile}}"

if [ -z "${filename}" ]; then
  cat >"${workFile}"
fi

shiftCount="$(
  # Remote empty lines from the file
  # Remove all text after the leading spaces in each line (leaving just the leading whitespace)
  # Find the length of the shortest line
  grep -vx '' "${workFile}" \
  | sed -e 's/[^ ].*//' \
  | awk 'NR == 1 { x=$0 } length($0) < length(x) { x = $0 } END { print length(x) }'
)"

if [ "${shiftCount}" != '0' ]; then
  sed -i "s/^[ ]\{${shiftCount}\}//" "${workFile}"
fi

if [ -z "${filename}" ]; then
  cat "${workFile}"
fi

rm "${tempFile}"