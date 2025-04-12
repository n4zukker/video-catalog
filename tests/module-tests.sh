#!/bin/bash

# Instruct bash to be strict about error checking.
set -e          # stop if an error happens
set -u          # stop if an undefined variable is referenced
set -o pipefail # stop if any command within a pipe fails
set -o posix    # extra error checking

declare -r SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare -r MODULE_DIR="$( cd "${SOURCE_DIR}/../src" && pwd )"

declare -r commandFile="$(mktemp)"
declare -r inputFile="$(mktemp)"
declare -r outputFile="$(mktemp)"

declare -rx logFile="$(mktemp)"
if [ -z "${fdLog:-}" ]; then
  exec {fdLog}>"${logFile}"
fi
declare -r -x fdLog

declare -r SINGLE_TEST="${1:-}"

function runTests () {
  local -r moduleName="$1"
  local -r fileUnderTest="$2"
  local -r testRunner="$3"

  if [[ -n "${SINGLE_TEST}" ]]; then
    if [[ ! ( "${moduleName}" -ef "${SINGLE_TEST}" ) ]]; then
      return	    
    fi
  fi

  (
    cd "${MODULE_DIR}"
    rm -f "${commandFile}" "${inputFile}" "${outputFile}"
    echo -n "${moduleName}: "
    sed -n -f "${SOURCE_DIR}/module-tests.sed" "${fileUnderTest}" | awk \
      -v commandFile="${commandFile}" \
      -v inputFile="${inputFile}" \
      -v outputFile="${outputFile}" \
      -v testScript="${testRunner}" \
      -f "${SOURCE_DIR}/module-tests.awk" || rc="$?"
    echo
  )
}

rc='0'

JQ_MODULES=( )
SED_MODULES=( )
SH_MODULES=( )
SH_ENV_MODULES=( )
YQ_MODULES=( )

# Comment out lines below to skip tests when debugging

JQ_MODULES=(
  "${SOURCE_DIR}/compare-results"
  $( find "${MODULE_DIR}" -name '*.jq' | sed -e 's/[.]jq//' | sort )
)

for module in "${JQ_MODULES[@]}" ; do
  export MODPATH="$(dirname "${module}")"
  export MODULE="$(basename "${module}")"
  runTests "${module}.jq" "${module}.jq" "${SOURCE_DIR}/module-one-jq-test.sh"
done

for module in "${SED_MODULES[@]}" ; do
  export MODPATH="$(dirname "${MODULE_DIR}/${module}")"
  export MODULE="$(basename "${module}")"
  runTests "${module}" "${MODPATH}/${MODULE}" "${SOURCE_DIR}/module-one-sed-test.sh"
done

for module in "${SH_MODULES[@]}" ; do
  export MODPATH="$(dirname "${MODULE_DIR}/${module}")"
  export MODULE="$(basename "${module}")"
  runTests "${module}" "${MODPATH}/${MODULE}" "${SOURCE_DIR}/module-one-sh-test.sh"
done

for module in "${SH_ENV_MODULES[@]}" ; do
  export MODPATH="$(dirname "${MODULE_DIR}/${module}")"
  export MODULE="$(basename "${module}")"
  runTests "${module}" "${MODPATH}/${MODULE}" "${SOURCE_DIR}/module-one-sh-env-test.sh"
done

for module in "${YQ_MODULES[@]}" ; do
  export MODPATH="$(dirname "${MODULE_DIR}/${module}")"
  export MODULE="$(basename "${module}")"
  runTests "${module}" "${MODPATH}/${MODULE}" "${SOURCE_DIR}/module-one-yq-test.sh"
done

rm -f "${commandFile}" "${inputFile}" "${outputFile}" "${logFile}"
exit "${rc}"
