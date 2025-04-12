#!/bin/bash
#
# Script to compare two files containing JSON.
#

# Instruct bash to be strict about error checking.
set -e          # stop if an error happens
set -u          # stop if an undefined variable is referenced
set -o pipefail # stop if any command within a pipe fails
set -o posix    # extra error checking

declare -r gotFile="$1"
declare -r expectedFile="$2"

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Compare what we got from the expression with what was expected.
# Our jq compare code will halt with a non-zero code if there's a difference.
jq --null-input \
  --slurpfile got "${gotFile}" \
  --slurpfile expected "${expectedFile}" \
  --from-file "${SOURCE_DIR}/compare-results.jq"
