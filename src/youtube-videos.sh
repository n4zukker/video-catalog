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

declare -r VIDEO_DB="${VIDEO_DB:-/dev/null}"
declare -r idFile="$(mktemp)"

declare -r videoPartsJsonFile="$(mktemp)"
declare -r pageStopJsonFile="$(mktemp)"

rc='0'
(
    (
      jq '.id' "${VIDEO_DB}" >"${pageStopJsonFile}"
      getUpcoming
      getMine
    ) | tee search.json | jq '.id.videoId' \
  | cat - "${pageStopJsonFile}" | sort | uniq \
  | jq --slurp --raw-output --compact-output '_nwise(50) | join(",")' \
  | while read -r idList ; do
      GET 'youtube/v3/videos' \
        --data-urlencode 'part=contentDetails' \
        --data-urlencode 'part=id' \
        --data-urlencode 'part=liveStreamingDetails' \
        --data-urlencode 'part=recordingDetails' \
        --data-urlencode 'part=snippet' \
        --data-urlencode 'part=statistics' \
        --data-urlencode 'part=status' \
        --data-urlencode 'part=topicDetails' \
        --data-urlencode "id=${idList}" \
        --data-urlencode 'part=fileDetails' \
        --data-urlencode 'part=processingDetails' \
        ;
    done \
  | jq '.items[]' \
  | tee "${videoPartsJsonFile}"
) || rc="$?"

rm "${videoPartsJsonFile}" "${pageStopJsonFile}" "${idFile}"

exit "${rc}"
