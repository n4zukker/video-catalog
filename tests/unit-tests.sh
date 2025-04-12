#!/bin/bash

set -e

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare -r SOURCE_DIR

SCRIPT_DIR="$( cd "${SOURCE_DIR}/.." && pwd )"
declare -r SCRIPT_DIR
declare -r TEST_DIR="${SOURCE_DIR}"

TEMP_DIR="$(mktemp -d)"

rcTests='0'
(
  echo "$(date): Running unit tests"
  cd "${SCRIPT_DIR}"
  "${TEST_DIR}/civil-holidays.sh"
) || rcTests="$?"
echo "$(date): Tests completed, rc=${rcTests}"

rm -rf "${TEMP_DIR}"
exit "${rcTests}"
