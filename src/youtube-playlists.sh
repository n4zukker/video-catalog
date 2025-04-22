#!/bin/bash

# Instruct bash to be strict about error checking.
set -e          # stop if an error happens
set -u          # stop if an undefined variable is referenced
set -o pipefail # stop if any command within a pipe fails
set -o posix    # extra error checking

# We will log to stderr.  Get a copy of the stderr file descriptor.
# This will let us write logs even when we redirect stdout within the script
# for other purposes.
exec {fdLog}>&2

# The pid variable will be used in our logs.
declare -r -x pid="${$}"

# Import logging
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SOURCE_DIR}/lib/bash-pino-trace.sh"
source "${SOURCE_DIR}/lib/call-rest.sh"
source "${SOURCE_DIR}/lib/utils.sh"

declare -r idFile="$(mktemp)"
declare -r pageStopJsonFile="$(mktemp)"

rc='0'
(
  exec {fdOut}>&1

  getMyPlaylists | tee >( cat >&"${fdOut}" ) | jq --raw-output --compact-output '.id' | while read -r listId ; do
    getPlaylistItems "${listId}"
  done
) && rc="$?"

rm "${pageStopJsonFile}" "${idFile}"

exit "${rc}"
