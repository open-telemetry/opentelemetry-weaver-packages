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
      
      # Filter out Weaver's unstable version warnings from observed file for comparison
      # We expect the expected file to ALREADY be clean of these warnings.
      VERSION_FILTER='map(select(.diagnostic.message | contains("is not yet stable") | not))'

      # Normalize empty/null/missing context so tests are robust to omitting context: {}.
      # Also strips the ", context={}" segment from the human-readable diagnostic message.
      NORMALIZE_FILTER='
        map(
          if (.error.violation | (has("context") | not))
              or .error.violation.context == {}
              or .error.violation.context == null
          then
            del(.error.violation.context) |
            .diagnostic.message |= gsub(", context=\\{}"; "")
          else . end
        )
      '

      jq -S "${VERSION_FILTER} | ${NORMALIZE_FILTER} | sort_by(.diagnostic.message)" "$OBSERVED_FILE" > "$TEMP_OBSERVED"
      jq -S "${NORMALIZE_FILTER} | sort_by(.diagnostic.message)" "$EXPECTED_FILE" > "$TEMP_EXPECTED"
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

# Validates that all findings in a diagnostic output file follow the signal naming convention:
#   - Signal identifiers (metric_name, event_name, span_type, entity_type, etc.) must NOT
#     appear as keys inside the `context` object — they belong at the top-level signal_type
#     and signal_name fields only.
#   - If signal_type is set, signal_name must also be set.
# Args:
#     1 - Observed Output file (JSON)
#     2 - Test name (for display)
validate_signal_conventions() {
  local OBSERVED_FILE="$1"
  local TEST_NAME="$2"

  if [[ ! -f "$OBSERVED_FILE" ]]; then
    return
  fi

  # Context keys that identify the signal itself must not appear — use top-level signal_type/signal_name.
  # Matches any key of the form <signal_type>[_.]<identifier>, e.g. metric_name, span.type, event_name.
  local SIGNAL_KEY_PATTERN='^(metric|event|span|entity)[_.](name|type)$'

  local VIOLATIONS
  VIOLATIONS=$(jq -r --arg pattern "$SIGNAL_KEY_PATTERN" '
    [.[] |
      select(.error.violation.context != null) |
      . as $finding |
      (.error.violation.context | keys | map(select(test($pattern)))) as $bad_keys |
      select($bad_keys | length > 0) |
      "  - id=\($finding.error.violation.id), forbidden context keys=\($bad_keys)"
    ] | .[]
  ' "$OBSERVED_FILE" 2>/dev/null)

  if [[ -n "$VIOLATIONS" ]]; then
    echo "  ❌ FAIL: $TEST_NAME - signal identifiers found in context (use top-level signal_type/signal_name instead):"
    echo "$VIOLATIONS"
    exit 1
  fi

  local MISSING_NAMES
  MISSING_NAMES=$(jq -r '
    [.[] |
      select(.error.violation.signal_type != null and .error.violation.signal_name == null) |
      "  - id=\(.error.violation.id), signal_type=\(.error.violation.signal_type)"
    ] | .[]
  ' "$OBSERVED_FILE" 2>/dev/null)

  if [[ -n "$MISSING_NAMES" ]]; then
    echo "  ❌ FAIL: $TEST_NAME - findings have signal_type set but signal_name is missing:"
    echo "$MISSING_NAMES"
    exit 1
  fi

  echo "  ✅ PASS: $TEST_NAME - signal conventions."
}

# Runs a policy test
run_policy_test() {
  TEST_DIR="$1"
  POLICY_PACKAGE_DIR="$2"
  TEST_NAME="${TEST_DIR#${POLICY_PACKAGE_DIR}/}"
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
  
  # Conditionally set baseline flag if 'base' directory exists
  BASELINE_FLAG=""
  if [ -d "base" ]; then
    BASELINE_FLAG="--baseline-registry base"
  fi

  # First make sure model files are correct.  Here diagnostic output will be about YAML model issues.
  RAW_CHECK_MODEL_OUTPUT="${OBSERVED_DIR}/model-check.stdout"
  ${WEAVER} registry check -r current ${BASELINE_FLAG} --quiet --v2 > "${RAW_CHECK_MODEL_OUTPUT}" 2>&1
  if [ $? -ne 0 ]; then
    echo "Test model in \"base\" or \"current\" is incorrect.  Invalid test configuration."
    cat "${RAW_CHECK_MODEL_OUTPUT}"
    exit 1
  fi
  # Now we run the policy and check the full output.
  RAW_DIAGNOSTIC_OUTPUT="${OBSERVED_DIR}/diagnostic-output.raw"
  NO_COLOR=1 ${WEAVER} registry check \
    -r current \
    ${BASELINE_FLAG} \
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
    # Also filter out Weaver's unstable version warnings
    # TODO - extract coverage report into separate file for display.
    JQ_FILTER='map(select(.diagnostic.message | contains("is not yet stable") | not))'
    sed -n '/^\[/,$p' "${RAW_DIAGNOSTIC_OUTPUT}" | jq -S "${JQ_FILTER}" > "${OBSERVED_DIR}/diagnostic-output.json"
  fi
  check_output "${OBSERVED_DIR}/diagnostic-output.json" "${TEST_DIR}/expected-diagnostic-output.json" "${TEST_NAME} - Diagnostic Output"
  validate_signal_conventions "${OBSERVED_DIR}/diagnostic-output.json" "${TEST_NAME}"
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
        PACKAGE_NAME="${package#${CUR}/policies/check/}"
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
