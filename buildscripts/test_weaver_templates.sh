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

# Tests the output of a test against expected value.
# With UPDATE_EXPECTED=1 the observed output replaces the expected one instead
# of being diffed against it (see `make update-test-output`).
# Args:
#     1 - Observed Output directory
#     2 - Expected Output directory
#     3 - Test name
check_output() {
  # `local`, so reporting one result does not clobber the caller's TEST_NAME.
  local OBSERVED_FILE="$1"
  local EXPECTED_FILE="$2"
  local TEST_NAME="$3"
  if [[ -n "$UPDATE_EXPECTED" ]]; then
    rm -rf "$EXPECTED_FILE"
    cp -R "$OBSERVED_FILE" "$EXPECTED_FILE"
    echo "  ♻️  UPDATED: $TEST_NAME expected output."
    return 0
  fi
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
  TEST_NAME="${TEST_DIR#${TEMPLATE_PACKAGE_DIR}/}"
  echo "-> Running test [${TEST_NAME}] ..."
  OBSERVED_DIR="${TEMPLATE_PACKAGE_DIR}/observed-output/${TEST_NAME}"
  rm -rf "${OBSERVED_DIR}"
  mkdir -p "${OBSERVED_DIR}"
  run_generate_test "${TEST_DIR}" "${TEMPLATE_PACKAGE_DIR}" "${OBSERVED_DIR}"
  # TODO - put errors / diagnostics into a file.
#   if [ $? -ne 0 ]; then
#     cat "${OBSERVED_DIR}/stderr"
#   fi
  check_output "${OBSERVED_DIR}" "${TEST_DIR}/expected" "${TEST_NAME} - Template Output"

  # A test that also ships a `markdown/` directory is rendered a second way: the
  # package's snippet.md.j2 fills the `<!-- weaver {jq} -->` markers in those
  # files. Running the same registry both ways is what keeps a definition
  # rendering identically on a generated page and in a snippet.
  if [ -d "${TEST_DIR}/markdown" ]; then
    OBSERVED_MD_DIR="${TEMPLATE_PACKAGE_DIR}/observed-output/${TEST_NAME}-markdown"
    rm -rf "${OBSERVED_MD_DIR}"
    mkdir -p "${OBSERVED_MD_DIR}"
    run_snippet_test "${TEST_DIR}" "${TEMPLATE_PACKAGE_DIR}" "${OBSERVED_MD_DIR}"
    check_output "${OBSERVED_MD_DIR}" "${TEST_DIR}/expected-markdown" "${TEST_NAME} - Snippet Output"
    check_snippet_consistency "${OBSERVED_MD_DIR}" "${OBSERVED_DIR}" "${TEST_NAME}"
  fi
}

# Asserts each definition renders the same as a snippet and on its generated
# page. Compares the *observed* output of both runs, so it fails on drift even
# when both expected trees were refreshed together (UPDATE_EXPECTED=1).
# Args:
#     1 - Observed `update-markdown` output directory
#     2 - Observed `generate` output directory
#     3 - Test name
check_snippet_consistency() {
  local OBSERVED_MD="$1"
  local OBSERVED_GEN="$2"
  local TEST_NAME="$3"
  if ! command -v python3 >/dev/null 2>&1; then
    log_err "Error: python3 not found; it is required to cross-check snippet output."
  fi
  echo "-> Cross-checking [${TEST_NAME}] snippet vs generated output ..."
  if ! python3 "$(dirname "$0")/check_snippet_consistency.py" "${OBSERVED_MD}" "${OBSERVED_GEN}"; then
    # TODO - We should try to accumulate errors and report status ONCE after all tests.
    exit 1
  fi
}

# Runs a full-registry test via `registry generate`.
# Args:
#     1 - Test directory (contains registry/, expected/)
#     2 - Template package directory
#     3 - Observed output directory
run_generate_test() {
  GEN_TEST_DIR="$1"
  GEN_PACKAGE_DIR="$2"
  GEN_OBSERVED_DIR="$3"
  GEN_TEMPLATES_ROOT=$(realpath "${GEN_PACKAGE_DIR}/../..")
  GEN_TARGET="${GEN_PACKAGE_DIR#${GEN_TEMPLATES_ROOT}/}"
  # Optional per-test template params (e.g. registry_base_url) via params.yaml.
  GEN_PARAMS_ARG=""
  if [ -f "${GEN_TEST_DIR}/params.yaml" ]; then
    GEN_PARAMS_ARG="--params ${GEN_TEST_DIR}/params.yaml"
  fi
  # Note: We force ourselves into test dir, so provenance of files is always consistently relative.
  # This also lets weaver discover a test's own `.weaver.toml` (`acronyms`,
  # `text_maps`, ...) by walking up from the registry.
  pushd "${GEN_TEST_DIR}"
  NO_COLOR=1 ${WEAVER} registry generate \
    -r registry \
    --v2 \
    --quiet \
    ${GEN_PARAMS_ARG} \
    --templates="${GEN_TEMPLATES_ROOT}" \
    "${GEN_TARGET}" \
    "${GEN_OBSERVED_DIR}"
  popd
}

# Runs a snippet (embed) test via `registry update-markdown`.
# Args:
#     1 - Test directory (contains registry/, markdown/, expected/)
#     2 - Template package directory
#     3 - Observed output directory (seeded with a copy of markdown/)
run_snippet_test() {
  SNIP_TEST_DIR="$1"
  SNIP_PACKAGE_DIR="$2"
  SNIP_OBSERVED_DIR="$3"
  SNIP_TEMPLATES_ROOT=$(realpath "${SNIP_PACKAGE_DIR}/../..")
  SNIP_TARGET="${SNIP_PACKAGE_DIR#${SNIP_TEMPLATES_ROOT}/}"
  # update-markdown edits the markdown in place; operate on a copy of markdown/.
  cp -r "${SNIP_TEST_DIR}/markdown/." "${SNIP_OBSERVED_DIR}/"
  # Optional per-test template params (e.g. registry_base_url) via params.yaml.
  SNIP_PARAMS_ARG=""
  if [ -f "${SNIP_TEST_DIR}/params.yaml" ]; then
    SNIP_PARAMS_ARG="--params ${SNIP_TEST_DIR}/params.yaml"
  fi
  pushd "${SNIP_TEST_DIR}"
  NO_COLOR=1 ${WEAVER} registry update-markdown \
    -r registry \
    --v2 \
    ${SNIP_PARAMS_ARG} \
    --templates="${SNIP_TEMPLATES_ROOT}" \
    --target "${SNIP_TARGET}" \
    "${SNIP_OBSERVED_DIR}"
  popd
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
        PACKAGE_NAME="${package#${CUR}/templates/}"
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
