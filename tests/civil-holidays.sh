#!/bin/bash

function testTitle () {
  printf "%40s " "${1}"
}

function checkJson () {
  jq "${@}" | jq --slurp '
    . as $input |
    if ( length == 0 ) then
      "Fail\n" | halt_error
    else
      "Pass"
    end
  '
}

GOT_2023="$(
  echo 2023 | jq \
    --slurpfile aPolicies <( jq --null-input '{ includeCivil: true }' ) \
    -f civil-holidays.jq
)"

GOT_2024="$(
  echo 2024 | jq \
    --slurpfile aPolicies <( jq --null-input '{ includeCivil: true }' ) \
    -f civil-holidays.jq
)"

aNewYearDay="$(jq --null-input '[ { "feast": "New Year'"'"'s Day", "glance": "New Year'"'"'s Day" } ]')"
aMLKDay="$(jq --null-input '[ { "feast": "Martin Luther King, Jr. Day", "glance": "M. L. King Jr. Day" } ]')"
aMotherDay="$(jq --null-input '[ { "feast": "Mother'"'"'s Day", "glance": "Mother'"'"'s Day" } ]')"
aMemorialDay="$(jq --null-input '[ { "feast": "Memorial Day", "glance": "Memorial Day" } ]')"
aThanksgivingDay="$(jq --null-input '[ { "feast": "Thanksgiving Day", "glance": "Thanksgiving D." } ]')"

testTitle '---- Church Year 2023 ----'; echo
testTitle 'Thanksgiving Day'
echo "${GOT_2023}" | checkJson --argjson aDay "${aThanksgivingDay}" 'select ( .["November"]["23"] == $aDay )'

testTitle 'New Year'
echo "${GOT_2023}" | checkJson --argjson aDay "${aNewYearDay}"  'select ( .["January"]["1"] == $aDay )'

testTitle 'MLK'
echo "${GOT_2023}" | checkJson --argjson aDay "${aMLKDay}"      'select ( .["January"]["15"] == $aDay )'

testTitle 'Mother'"'"'s Day'
echo "${GOT_2023}" | checkJson --argjson aDay "${aMotherDay}"   'select ( .["May"]["12"] == $aDay )'

testTitle 'Memorial Day'
echo "${GOT_2023}" | checkJson --argjson aDay "${aMemorialDay}" 'select ( .["May"]["27"] == $aDay )'



testTitle '---- Church Year 2024 ----'; echo

testTitle 'Thanksgiving Day'
echo "${GOT_2024}" | checkJson --argjson aDay "${aThanksgivingDay}" 'select ( .["November"]["28"] == $aDay )'

testTitle 'New Year'
echo "${GOT_2024}" | checkJson --argjson aDay "${aNewYearDay}"  'select ( .["January"]["1"] == $aDay )'

testTitle 'MLK'
echo "${GOT_2024}" | checkJson --argjson aDay "${aMLKDay}"      'select ( .["January"]["20"] == $aDay )'

testTitle 'Mother'"'"'s Day'
echo "${GOT_2024}" | checkJson --argjson aDay "${aMotherDay}"   'select ( .["May"]["11"] == $aDay )'

testTitle 'Memorial Day'
echo "${GOT_2024}" | checkJson --argjson aDay "${aMemorialDay}" 'select ( .["May"]["26"] == $aDay )'
