#
# Script to run a test with a given input
# and check that the output matches what is expected.
# The command, input and expected output are all passed
# as files.
#
# Usage:
#   $0 <commandFile> <inputFile> <expectedFile> ...extraArgs...
#
# Example:
#   $0 <( echo '. + 5') <( echo '2' ) <( echo '7' )
#
# In this example, the jq expression ". + 5" is run against
# the input value of "2" and it should result in "7" being output.
#
# If there are any errors or the result doesn't match what we expect,
# an error message is written to stderr and the parameters to stdout.
#
#
# Enviroment variables:
#   Set "VERBOSE", to change the output (optional)
#     0 -- minimal output (default)
#     1 -- a little more descriptive
#     2 -- write parameters out even if the test passed.
#
#   Set "MODPATH" to the directory of the module under test. (required)
#   Set "MODULE" to the name of the jq module under test without a trailing ".jq". (required)

# ABOUT THIS FILE
# ---------------
# This is an incomplete script.  It is missing the "runTest" function.
# If you run this script by itself you will get an error.  Something like
#
# ./test/module-one-test-runner.sh: line 95: runTest: command not found
# 
# To use this code, first define the "runTest" function and then
# source this file to bring in the rest.

# Instruct bash to be strict about error checking.
set -e          # stop if an error happens
set -u          # stop if an undefined variable is referenced
set -o pipefail # stop if any command within a pipe fails
set -o posix    # extra error checking

# Find out the directory of this source file, so we can access sibling files.
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Pick out command arguments
declare -r commandFile="$1"
declare -r inputFile="$2"
declare -r expectedFile="$3"
shift 3
declare -r extraArgs=("$@")

# We use two temporary files
declare -r gotFile="$(mktemp)"
declare -r errFile="$(mktemp)"

# Function to cat out a file nicely to stdout.
# The name of the file is printed and then
# the contents along with line numbers.
function printFile () {
  local -r name="$1"
  echo "${name}:"
  cat -n
  echo ""
}

# Default VERBOSE to '0'
VERBOSE="${VERBOSE:-0}"

# Use the first line of a file as part of the test title
function firstLine () {
  local -r file="$1"
  if [[ -s "${file}" || -p "${file}" ]] ; then
    sed -e 's/^  *//' -e '/^$/d' "${file}" | head --lines=1 
  fi
}

commandHead="$(firstLine "${commandFile}")"
inputHead="$(firstLine "${inputFile}")"
argsHead="$(firstLine <( echo "${extraArgs[*]}" ))"

# Print a descriptive test title message if we are at non-zero verbosity
case "${VERBOSE}" in
  0) ;;
  *)
    echo ''
    echo -n -e '\t'
    if [ -n "${commandHead}" ]; then
      echo -n "${commandHead} ... ${inputHead}"
    else
      echo -n "${argsHead} ... ${inputHead}"
    fi 
    ;;
esac

rc='0'
runTest "${commandFile}" "${inputFile}" "${expectedFile}" "${gotFile}" "${extraArgs[@]}" 2>"${errFile}" || rc="$?"

# If we got an error (or if we are just being verbose), output everything.
if [[ "${rc}" != 0 || "${VERBOSE}" > '1' ]]; then
  # Write a newline first.  Otherwise the error message (if any) gets written in the wrong place.
  echo ""
  cat "${errFile}" 1>&2
  [ -s "${commandFile}" ] && printFile 'Command' <"${commandFile}"
  [ -n "${extraArgs[*]}" ] && ( for x in "${extraArgs[@]}" ; do echo "${x}" ; done ) | printFile 'Args'
  printFile 'Input' <"${inputFile}"
  printFile 'Expected' <"${expectedFile}"
  printFile 'Got' <"${gotFile}"
  for extraFile in "${extraArgs[@]}" ; do
    if [ -f "${extraFile}" ]; then
      printFile "${extraFile}" <"${extraFile}"
    fi
  done
else
  # If things passed then print out a cute character (a checkbox).
  echo -n ' '$'\U2705'
fi

# Clean up our temporary files
rm '-f' "${gotFile}" "${errFile}"

# Exit with the result code of the jq compare
exit "${rc}"
