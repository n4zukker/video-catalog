#!/bin/bash
#

# Examples:
#
# -------
# Input: -
#   AAA=123
#   BBB=Hello World
#   C=
#   Other text
#
# Output: -
#   declare -x AAA=123
#   declare -x BBB=Hello\ World
#   declare -x C=''
#
# -------
# Input: -
#   MULTI<<<EOL
#     line 1
#     line 2
#   EOL
#   AAA=123
#   Other text
#
# Output: -
#   declare -x MULTI=$'line 1\nline 2\n'
#   declare -x AAA=123
#
# -------
# Input: -
#   AAA=123
#   Other text
#   more text
#
# Arg: /dev/null /dev/stdout
#
# Output: -
#   Other text
#   more text
#
# -------
# Command:
# Input: -
#   text with equals AAA=123 example
#   Other text
#   more text
#
# Output: -
#
# -------
# Input: -
#   text with equals AAA=123 example
#   Other text
#   more text
#
# Arg: /dev/null /dev/stdout
#
# Output: -
#   text with equals AAA=123 example
#   Other text
#   more text
#
# -------
# Command:
# Input: -
#   text with equals AAA=123 example
#   Other text
#   more text
#
# Output: -
#
# -------
# Input: -
#   AAA=assignment B=5
#   MULTI<<<123<<<456
#   Hello
#   123<<<456
#   BBB=not<<<multi
#
# Output: -
#   declare -x AAA=assignment\ B=5
#   declare -x MULTI=$'Hello\n'
#   declare -x BBB=not\<\<\<multi
#
declare -r assignmentFile="${1:-/dev/stdout}"
declare -r remainderFile="${2:-/dev/stderr}"

declare -r newline=$'\n'

eol=''
multiline=''
while read -r line ; do
  if [[ -n "${eol}" ]]; then
    if [[ "${line}" == "${eol}" ]]; then
	  eol=''
      rhs="$( printf "%q" "${multiline}" )"
	  echo "declare -x ${lhs}=${rhs}" >>"${assignmentFile}"
	  multiline=''
    else
      multiline="${multiline}${line}${newline}"
	fi
  elif [[ "${line}" == *([[:word:]])=* ]]; then
    lhs="$( printf "%q" "${line%=*}" )"
    rhs="$( printf "%q" "${line##*=}" )"
    echo "declare -x ${lhs}=${rhs}" >>"${assignmentFile}"
  elif [[ "${line}" == *'<<<'* ]]; then
  	lhs="${line%%<<<*}"
    eol="${line#*<<<}"
  else
    echo "${line}" >>"${remainderFile}"
  fi
done