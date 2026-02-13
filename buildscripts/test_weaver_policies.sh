#!/bin/bash

# We parse an array of tests to run.
test_filter=()

# parse arguments.
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            DEBUG=true
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --test)
          if [[ -n "$2" && "$2" != --* ]]; then
            test_filter+=("$2")
            shift 2             
          else
            echo "Error: --test requires an argument."
            exit 1
          fi
          ;;
        -h|--help)
            echo "Usage: test_weaver_policies.sh [--debug] [--coverage] [--test {name}]"
            exit 0
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
done

# Debugging
if [[ "${DEBUG:false}" == "true" ]]; then
  set -x
fi


# Find weaver installation or warn it needs to exist.
if [[ -z "$WEAVER" ]]; then
  WEAVER=weaver
fi

if ! command -v "${WEAVER}" >/dev/null 2>&1; then
  echo weaver not found.
  echo Please set WEAVER environment variable or add it to your path.
  exit 1
fi

# test_filter
matches_test_filter() {
  local search_term="$1"
  shift # Remove the search term from the argument list
  
  # Check if the remaining arguments (the array) are empty
  if [[ ${#test_filter[@]} -eq 0 ]]; then
    return 0
  fi

  # Otherwise, loop through to find a match
  for e in "${test_filter[@]}"; do 
    [[ "$e" == "$search_term" ]] && return 0
  done

  return 1
}


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
    if [[ "$EXPECTED_FILE" == *.json ]]; then
      # Pretty print both for comparison
      TEMP_OBSERVED=$(mktemp)
      TEMP_EXPECTED=$(mktemp)
      jq -S . "$OBSERVED_FILE" > "$TEMP_OBSERVED"
      jq -S . "$EXPECTED_FILE" > "$TEMP_EXPECTED"
      diff "$TEMP_OBSERVED" "$TEMP_EXPECTED" > /dev/null
      DIFF_RESULT=$?
      if [ $DIFF_RESULT -eq 0 ]; then
          echo "  ✅ PASS: $TEST_NAME matches expected output."
      else
          echo "  ❌ FAIL: $TEST_NAME differences found!"
          # Optional: Show the differences
          diff -u "$TEMP_EXPECTED" "$TEMP_OBSERVED"
          # TODO - We should try to accumulate errors and report status ONCE after all tests.
          rm "$TEMP_OBSERVED" "$TEMP_EXPECTED"
          exit 1
      fi
      rm "$TEMP_OBSERVED" "$TEMP_EXPECTED"
    else
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
  local short_test_name="${TEST_NAME#tests/}"
  if ! matches_test_filter "$short_test_name"; then
    return
  fi
  DIAGNOSTIC_WORKAROUND=$(realpath "${POLICY_PACKAGE_DIR}/../../../diagnostic_templates")
  COVERAGE_FLAG=""
  if [[ "${COVERAGE:false}" == "true" ]]; then
    COVERAGE_FLAG="--display-policy-coverage"
  fi
  echo "-> Running test [${TEST_NAME}] ..."
  OBSERVED_DIR="${POLICY_PACKAGE_DIR}/observed-output/${TEST_NAME}"
  rm -rf "${OBSERVED_DIR}"
  mkdir -p "${OBSERVED_DIR}"
  # Note: We force ourselves into test dir, so provenance of files is always consistently relative.
  pushd "${TEST_DIR}" > /dev/null 2>&1
  RAW_DIAGNOSTIC_OUTPUT="${OBSERVED_DIR}/diagnostic-output.raw.json"
  NO_COLOR=1 ${WEAVER} registry check \
    -r current \
    --baseline-registry base \
    -p "${POLICY_PACKAGE_DIR}" \
    --v2 \
    --quiet \
    ${COVERAGE_FLAG} \
    --diagnostic-template="${DIAGNOSTIC_WORKAROUND}" \
    --diagnostic-format json \
    --diagnostic-stdout \
    > "${RAW_DIAGNOSTIC_OUTPUT}" \
    2> "${OBSERVED_DIR}/stderr"
  popd > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    cat "${OBSERVED_DIR}/stderr"
  fi
  if [ -f "${RAW_DIAGNOSTIC_OUTPUT}" ]; then
    # Strip coverage report or any other non-JSON output before passing to jq
    sed -n '/^\[/,$p' "${RAW_DIAGNOSTIC_OUTPUT}" | jq -S . > "${OBSERVED_DIR}/diagnostic-output.json"
  fi
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
        PACKAGE_NAME=$(realpath --relative-to="$package/../.." "$package")
        echo "---==== Policy Package - ${PACKAGE_NAME} ====---"
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
