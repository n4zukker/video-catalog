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
declare -r playlistTempJsonFile="$(mktemp)"

rc='0'
(
  getMyPlaylists >"${playlistTempJsonFile}"

  jq . "${playlistTempJsonFile}"

  jq --raw-output --compact-output '.id' "${playlistTempJsonFile}" \
  | while read -r listId ; do
      GET 'youtube/v3/playlistItems' \
        --data-urlencode 'part=contentDetails' \
        --data-urlencode 'part=id' \
        --data-urlencode 'part=snippet' \
        --data-urlencode "playlistId=${listId}" \
	;
    done \
  | jq '.items[]'
) && rc="$?"

rm "${playlistTempJsonFile}" "${idFile}"

exit "${rc}"
