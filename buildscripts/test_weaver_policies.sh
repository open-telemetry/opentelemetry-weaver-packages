#!/bin/bash

# TODO - Figure out where to get weaver from
WEAVER=~/projects/open-telemetry/weaver/target/debug/weaver

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
#     1 - Observed Output file
#     2 - Expected Output file
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
  else
    echo "  ⚠️  SKIPPED: Missing expected file: $EXPECTED_FILE"
  fi
}

# Runs a policy test
run_policy_test() {
  TEST_DIR="$1"
  POLICY_PACKAGE_DIR="$2"
  TEST_NAME=$(realpath --relative-to="$POLICY_PACKAGE_DIR" "$TEST_DIR")
  echo "-> Running test [${TEST_NAME}] ..."
  OBSERVED_DIR="${POLICY_PACKAGE_DIR}/observed-output/${TEST_NAME}"
  rm -rf "${OBSERVED_DIR}"
  mkdir -p "${OBSERVED_DIR}"
  # Note: We force ourselves into test dir, so provenance of files is always consistently relative.
  pushd "${TEST_DIR}"
  echo "  -- stderr -- "
  ${WEAVER} registry check \
    -r current \
    --baseline-registry base \
    -p "${POLICY_PACKAGE_DIR}" \
    --v2 \
    --diagnostic-format json \
    --diagnostic-stdout \
    > "${OBSERVED_DIR}/diagnostic-output.json"
  echo "  -- /stderr -- "
  popd
  check_output "${OBSERVED_DIR}/diagnostic-output.json" "${TEST_DIR}/expected-diagnostic-output.json" "${TEST_NAME} - Diagnostic Output"
}

# Runs a set of policy tests for a given package.
# This is given the test directory
run_tests() {
  POLICY_PACKAGE_DIR="$1"
  TEST_DIR="$1/tests"
  if [ ! -d "$TEST_DIR" ]; then
      log_err "Error: Tests not found in '$TEST_DIR' for policy package: ${POLICY_PACKAGE_DIR}"
  fi
  for dir in ${TEST_DIR}/*; do
    if [ -d "${dir}" ]; then
      run_policy_test "${dir}" "${POLICY_PACKAGE_DIR}"
    fi
  done
}

# Run all the policy package tests in the root repository.
run_all_policy_package_tests() {
  CUR="${1}"
  if [ -d "policies" ]; then
    for package in ${CUR}/policies/check/*; do
      if [ -d "${package}" ]; then
        echo "---==== Policy Package - Check - ${package} ====---"
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
  run_all_policy_package_tests "${PWD}"
fi
