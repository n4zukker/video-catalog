#!/bin/bash
#
# Script to run a jq expression (command) with a given input
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
  # Run the test within jq.  The first line of the expression will include
  # the module under test. The result of the expression is written in "gotFile".
  # Any errors that jq writes out go to stdout.
  jq \
    -L "${MODPATH}" \
    --from-file <(
      if [ -s "${commandFile}" ]; then
        echo 'include "'"${MODULE}"'";'
        cat "${commandFile}"
      else
        cat "${MODPATH}/${MODULE}.jq"
      fi
    ) \
    "${extraArgs[@]}" \
    "${inputFile}" \
    > "${gotFile}" \
    || rc="$?"

  # Stop early if there was an error
  if [[ "${rc}" != '0' ]] ; then
    printf "%q " jq -L "${MODPATH}" --from-file ... "${extraArgs[@]}" '<inputFile>'
    return "${rc}"
  fi

  "${SOURCE_DIR}/compare-results-json.sh" "${gotFile}" "${expectedFile}"
}

source "${SOURCE_DIR}/module-one-test-runner.sh"
