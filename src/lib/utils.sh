#!/bin/bash

declare -r API_PATH='https://youtube.googleapis.com/'

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

function GET_PAGES () {
  local -r argArray=("${@}")
  (
    exec {fdOut}>&1

    local nextPageToken=''
    while true; do
      nextPageToken="$(
        GET "${argArray[@]}" $( [[ -n "${nextPageToken}" ]] && printf "%q %q" '--data-urlencode' "pageToken=${nextPageToken}" ) \
        | tee >( jq '.items[]' >"/dev/fd/${fdOut}" ) \
	| tee >( jq '.items[].id | select ( type == "object" ) | .videoId' >"${idFile}" ) \
        | jq --raw-output '.nextPageToken // empty'
      )"
      if [[ -z "${nextPageToken}" ]]; then
        pinoTrace -u "${fdLog}" 'Reached last page'
        break
      fi

      if [[ "$( jq 'select ( . as $id | $stops | index ($id) )' --slurpfile stops "${pageStopJsonFile}" "${idFile}" | wc --lines )" != '0' ]]; then
        pinoTrace -u "${fdLog}" 'Reached video ids that we have seen before'
        break
      fi
    done
  )
}

function getMyPlaylists () (
  GET_PAGES 'youtube/v3/playlists' \
	--data-urlencode 'part=contentDetails' \
	--data-urlencode 'part=snippet' \
	--data-urlencode 'part=id' \
        --data-urlencode 'mine=true' \
        --data-urlencode 'maxResults=50' \
        --data-urlencode 'order=date'
)

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

