#!/bin/bash
#
# Script to run a yq expression (command) with a given input
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
  (
    # Parse the extra arguments.  Pull out and execute any key=value
    # assignment statements.  The remaining of the extra areuments
    # are placed in the exArgs array.
    source <( "${SOURCE_DIR}/env-args.sh" "${extraArgs[@]}" )

    # Run the test within yq.  The first line of the expression will include
    # the module under test. The result of the expression is written in "gotFile".
    # Any errors that yq writes go to stderr.
    yq \
      --from-file <( sed -e 's/#.*//' "${MODPATH}/${MODULE}" ) \
      "${exArgs[@]}" \
      "${inputFile}" \
     > "${gotFile}" \
  ) || rc="$?"

  # Stop early if there was an error
  if [[ "${rc}" != '0' ]] ; then
    return "${rc}"
  fi

  local -r sortedGot="$(mktemp)"
  local -r sortedExpected="$(mktemp)"

  yq --prettyPrint 'sort_keys(...) | ... comments=""' "${gotFile}" > "${sortedGot}"
  yq --prettyPrint 'sort_keys(...) | ... comments=""' "${expectedFile}" > "${sortedExpected}"

  diff --label "got" --label "expected" --context "${sortedGot}" "${sortedExpected}" || rc="$?"
  rm "${sortedGot}" "${sortedExpected}"

  return "${rc}"
}

source "${SOURCE_DIR}/module-one-test-runner.sh"
