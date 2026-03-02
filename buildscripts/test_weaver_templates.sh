#!/bin/bash

# Debugging
# set -x

# Find weaver installation or warn it needs to exist.
if [[ -z "$WEAVER" ]]; then
  WEAVER=weaver
fi

if ! command -v "${WEAVER}" >/dev/null 2>&1; then
  echo weaver not found.
  echo Please set WEAVER environment variable or add it to your path.
  exit 1
fi

# Logs an error and exits
log_err() {
  echo "$1"
  exit 1
}

# Logs a warning
log_warn() {
  echo "$1"
}

# Tests the output of a test agianst expected value.
# Args:
#     1 - Observed Output directory
#     2 - Expected Output directory
#     3 - Test name
check_output() {
  OBSERVED_FILE="$1"
  EXPECTED_FILE="$2"
  TEST_NAME="$3"
  # Skip checking if we don't have an expected file.
  if [[ -f "$EXPECTED_FILE" ]]; then
    diff "$OBSERVED_FILE" "$EXPECTED_FILE" > /dev/null
    if [ $? -eq 0 ]; then
        echo "  ✅ PASS: $TEST_NAME matches expected output."
    else
        echo "  ❌ FAIL: $TEST_NAME differences found!"
        # Optional: Show the differences
        diff -u "$EXPECTED_FILE" "$OBSERVED_FILE"
        # TODO - We should try to accumulate errors and report status ONCE after all tests.
        exit 1
    fi
  elif [[ -d "$EXPECTED_FILE" ]]; then
    # diff the directories
    diff -r "$OBSERVED_FILE" "$EXPECTED_FILE" > /dev/null
    if [ $? -eq 0 ]; then
        echo "  ✅ PASS: $TEST_NAME matches expected output."
    else
        echo "  ❌ FAIL: $TEST_NAME differences found!"
        # Optional: Show the differences
        diff -r -u "$EXPECTED_FILE" "$OBSERVED_FILE"
        # TODO - We should try to accumulate errors and report status ONCE after all tests.
        exit 1
    fi
  else
    echo "  ⚠️  SKIPPED: Missing expected file or directory: $EXPECTED_FILE"
  fi
}

# Runs a template test
run_template_test() {
  TEST_DIR="$1"
  TEMPLATE_PACKAGE_DIR="$2"
  TEMPLATES_ROOT_DIR=$(realpath "${TEMPLATE_PACKAGE_DIR}/../..")
  TEST_NAME="${TEST_DIR#${TEMPLATE_PACKAGE_DIR}/}"
  TEMPLATE_NAME="${TEMPLATE_PACKAGE_DIR#${TEMPLATES_ROOT_DIR}/}"
  echo "-> Running test [${TEMPLATE_NAME}/${TEST_NAME}] ..."
  OBSERVED_DIR="${TEMPLATE_PACKAGE_DIR}/observed-output/${TEST_NAME}"
  rm -rf "${OBSERVED_DIR}"
  mkdir -p "${OBSERVED_DIR}"
  # Note: We force ourselves into test dir, so provenance of files is always consistently relative.
  pushd "${TEST_DIR}"
  echo "  Running: ${WEAVER} registry generate -r ${REGISTRY_PATH} --v2 --quiet --templates=${TEMPLATES_ROOT_DIR} ${TEMPLATE_NAME} ${OBSERVED_DIR}"
  NO_COLOR=1 ${WEAVER} registry generate \
    -r registry \
    --v2 \
    --quiet \
    --templates="${TEMPLATES_ROOT_DIR}" \
    ${TEMPLATE_NAME} \
    ${OBSERVED_DIR}
  popd
  # TODO - put errors / diagnostics into a file.
#   if [ $? -ne 0 ]; then
#     cat "${OBSERVED_DIR}/stderr"
#   fi
  check_output "${OBSERVED_DIR}" "${TEST_DIR}/expected" "${TEMPLATE_NAME}/${TEST_NAME} - Template Output"
}

# Runs a set of policy tests for a given package.
# This is given the test directory
run_tests() {
  TEMPLATE_PACKAGE_DIR="$1"
  TEST_DIR="$1/tests"
  if [ ! -d "$TEST_DIR" ]; then
      log_err "Error: Tests not found in '$TEST_DIR' for policy package: ${TEMPLATE_PACKAGE_DIR}"
  fi
  for dir in ${TEST_DIR}/*; do
    if [ -d "${dir}" ]; then
      run_template_test "${dir}" "${TEMPLATE_PACKAGE_DIR}"
    fi
  done
}

# Run all the policy package tests in the root repository.
run_all_policy_template_tests() {
  CUR="${1}"
  if [ -d "templates" ]; then
    for package in ${CUR}/templates/*/*; do
      if [ -d "${package}" ]; then
        PACKAGE_NAME="$(basename "$(dirname "${package}")")/$(basename "${package}")"
        echo "---==== Template Package - ${PACKAGE_NAME} ====---"
        if [ ! -f "${package}/README.md" ]; then
          log_warn "Missing README"
        fi
        if [ -d "${package}/tests" ]; then
          run_tests "${package}"
        else
          echo "⚠️  SKIPPED TESTS: No tests directory"
        fi
      fi
    done
  fi
}

# We check whether we are being run *inside* a package or from the root, and execute tests appropriately from there.
if [ -d "tests" ]; then
  echo "Running tests for ${PWD}..."
  run_tests "${PWD}"
else
  run_all_policy_template_tests "${PWD}"
fi
