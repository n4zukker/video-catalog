#!/bin/bash

#
# Function to make an arbitrary <method> request to an HTTP server.
#
# Usage:
#   curlMethod {args...} {url}
#
# with the following two variables set:
#   curlMethodArgs -- an array of arguments specific to the method
#      e.g. ('--get') for GET; (-X POST -H 'Content-Type: application/json') for POST...
#      This array is not logged, so sensitive info such as tokens should go here.   
#
#   method -- the name of the method (GET, POST, PATCH...)
#
# Logs and returns the JSON result of the request to stdout.
#
function curlMethod () {
  local argArray=("$@")

  local -r responseJsonFile="$(mktemp)"
  local -r responseCodeJsonFile="$(mktemp)"
  local rc

  responseCode=''

  pinoTrace -u "${fdLog}" 'Making curl request' method argArray
  if curl \
    --insecure \
    "${curlMethodArgs[@]}" \
    --silent \
    --output "${responseJsonFile}" \
    --write-out '{\n"response_code": %{response_code}\n}' \
    "$@" \
    >"${responseCodeJsonFile}" ; \
  then
    responseCode="$(grep '^"response_code": [0-9][0-9]*$' "${responseCodeJsonFile}" | tail --lines=1 | sed -e 's/"response_code": //')"
    local -r wcResponse="$( wc <"${responseJsonFile}")"
    case "${responseCode}" in
      2*)
        pinoTrace -u "${fdLog}" 'Response from request' method argArray responseCodeJsonFile responseCode wcResponse
        cat "${responseJsonFile}"
        rc='0'
        ;;

      4* | 5*)
        rc="$(( ${responseCode} - 400 ))"
        pinoTrace -u "${fdLog}" 'Response from request' method argArray responseCodeJsonFile responseJsonFile responseCode wcResponse
        ;;

      *)
        pinoTrace -u "${fdLog}" 'Response from request' method argArray responseCodeJsonFile responseJsonFile responseCode 
        rc='1'
        ;;
    esac
  else
    local -r rcCurl="$?"
    rc="${rcCurl}"
    pinoTrace -u "${fdLog}" 'Curl failed' method argArray rcCurl
  fi

  rm "${responseJsonFile}" "${responseCodeJsonFile}"
  return "${rc}"
}
