#!/bin/bash
#
# Script to run a sed expression (command) with a given input
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
  sed \
    --file=<(
      if [ -s "${commandFile}" ]; then
        cat "${commandFile}"
      else
        cat "${MODPATH}/${MODULE}"
      fi
    ) \
    "${extraArgs[@]}" \
    "${inputFile}" \
    > "${gotFile}" \
    || rc="$?"

  # Stop early if there was an error
  if [[ "${rc}" != '0' ]] ; then
    return "${rc}"
  fi

  # Compare what we got from sed with what was expected.  Remove leading '>' characters.
  # We remove the > so that we can eat our own dog food and test the tests-in-comments code
  # using this code.  The > in the expected output lets us enter lines like "Input:" and "Output:"
  # in the output and not have the code get all confused.
  diff "${gotFile}" <( sed -e 's/>//' "${expectedFile}" ) 1>&2
}

source "${SOURCE_DIR}/module-one-test-runner.sh"
