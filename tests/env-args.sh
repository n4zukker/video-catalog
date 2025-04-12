#!/bin/bash
#

declare exArgs=( )

for x in "${@}" ; do
  if [[ "${x}" == *=* ]]; then
    lhs="$( printf "%q" "${x%=*}" )"
    rhs="$( printf "%q" "${x#*=}" )"
    echo "declare -x ${lhs}=${rhs}"
  else
    exArgs=("${exArgs[@]}" "${x}")
  fi
done

declare -p 'exArgs'
