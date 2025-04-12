#!/bin/bash
#
# Script to run a shell script with a given input
# and check that the output matches what is expected.
# The command, input and expected output are all passed
# as files.
#
# See module-one-test-runner.sh for more explanation.
#

# Instruct bash to be strict about error checking.
set -e          # stop if an error happens
set -u          # stop if an undefined variable is referenced
set -o pipefail # stop if any command within a pipe fails
set -o posix    # extra error checking

# Find out the directory of this source file, so we can access sibling files.
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function runTest() {
  rc='0'
  "${MODPATH}/${MODULE}" "${extraArgs[@]}" <"${inputFile}" >"${gotFile}" || rc="$?"

  # Stop early if there was an error
  if [[ "${rc}" != '0' ]] ; then
    return "${rc}"
  fi
  # Compare what we got from sed with what was expected.
  if ( jq . "${gotFile}" && jq . "${expectedFile}" ) > /dev/null 2>&1 ; then
    # if got and expected both parse as json, do a json compare.
    "${SOURCE_DIR}/compare-results-json.sh" "${gotFile}" "${expectedFile}"
  else
    "${SOURCE_DIR}/compare-results-text.sh" "${gotFile}" "${expectedFile}"
  fi
}

source "${SOURCE_DIR}/module-one-test-runner.sh"
