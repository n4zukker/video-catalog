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

declare -r API_PATH='https://youtube.googleapis.com/'
declare -r VIDEO_DB="${VIDEO_DB:-/dev/null}"

# Usage:
#   GET {endpoint}
function GET () {
  local -r endpoint="$1"
  shift
  local -r otherArgs=("$@")

  local -r method='GET'
  local -r curlMethodArgs=(
    '--get'
    '--header' 'Accept: application/json'
  )

  curlMethod '--url' "${API_PATH}${endpoint}" '--header' @<(echo "Authorization: Bearer ${YOUTUBE_ACCESS_TOKEN:?}") "${otherArgs[@]}"
}

declare -r videoPartsJsonFile="$(mktemp)"
declare -r pageStopJsonFile="$(mktemp)"
declare -r idFile="$(mktemp)"

function GET_PAGES () {
  local -r argArray=("${@}")
  (
    exec {fdOut}>&1

    local nextPageToken=''
    while true; do
      nextPageToken="$(
        GET "${argArray[@]}" $( [[ -n "${nextPageToken}" ]] && printf "%q %q" '--data-urlencode' "pageToken=${nextPageToken}" ) \
        | tee >( jq '.items[]' >"/dev/fd/${fdOut}" ) \
        | tee >( jq '.items[].id.videoId' >"${idFile}" ) \
        | jq --raw-output '.nextPageToken // empty'
      )"
      if [[ -z "${nextPageToken}" ]]; then
        pinoTrace -u "${fdLog}" 'Reached last page'
        break
      fi

      if [[ "$(cat "${idFile}" | jq 'select ( . as $id | $stops | index ($id) )' --slurpfile stops "${pageStopJsonFile}" | wc --lines )" != '0' ]]; then
        pinoTrace -u "${fdLog}" 'Reached video ids that we have seen before'
        break
      fi
    done
  )
}

nextPageToken=''
function getMine () (
  GET_PAGES 'youtube/v3/search' \
        --data-urlencode 'forMine=true' \
        --data-urlencode 'part=id' \
        --data-urlencode 'maxResults=50' \
        --data-urlencode 'type=video' \
        --data-urlencode 'order=date'
)

function getUpcoming () {
  local -r channelId='UCHYXf9VZK51bNOz-zJX9T6Q'

  GET_PAGES 'youtube/v3/search' \
    --data-urlencode 'part=id' \
    --data-urlencode 'maxResults=50' \
    --data-urlencode "channelId=${channelId}" \
    --data-urlencode 'eventType=upcoming' \
    --data-urlencode 'type=video' \
    --data-urlencode 'order=date'
}

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
)

rm "${videoPartsJsonFile}" "${pageStopJsonFile}" "${idFile}"
