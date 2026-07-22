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
  OBSERVED_FILE="$1"
  EXPECTED_FILE="$2"
  TEST_NAME="$3"
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
  TEMPLATES_ROOT_DIR=$(realpath "${TEMPLATE_PACKAGE_DIR}/../..")
  TEST_NAME="${TEST_DIR#${TEMPLATE_PACKAGE_DIR}/}"
  TEMPLATE_NAME="${TEMPLATE_PACKAGE_DIR#${TEMPLATES_ROOT_DIR}/}"
  echo "-> Running test [${TEST_NAME}] ..."
  OBSERVED_DIR="${TEMPLATE_PACKAGE_DIR}/observed-output/${TEST_NAME}"
  rm -rf "${OBSERVED_DIR}"
  mkdir -p "${OBSERVED_DIR}"
  if [ -d "${TEST_DIR}/markdown" ]; then
    # Snippet test: the package ships a snippet.md.j2 and the test provides a
    # `markdown/` directory of markdown files containing `<!-- weaver {jq} -->`
    # markers. We run `registry update-markdown`, which fills those markers in
    # place, then diff the result against `expected/`.
    run_snippet_test "${TEST_DIR}" "${TEMPLATE_PACKAGE_DIR}" "${OBSERVED_DIR}"
  else
    # Optional per-test template params (e.g. registry_base_url) via params.yaml.
    PARAMS_ARG=""
    if [ -f "${TEST_DIR}/params.yaml" ]; then
      PARAMS_ARG="--params ${TEST_DIR}/params.yaml"
    fi
    # Optional per-test template config (`acronyms`, `text_maps`, ...) that is
    # not expressible as a param. Users set these in their project's
    # `.weaver.toml`; that merge is not in the released weaver yet, so a test
    # runs against a throwaway copy of the templates root with its
    # `weaver-config.yaml` appended to the package's own weaver.yaml.
    RUN_TEMPLATES_ROOT="${TEMPLATES_ROOT_DIR}"
    if [ -f "${TEST_DIR}/weaver-config.yaml" ]; then
      RUN_TEMPLATES_ROOT=$(mktemp -d)/templates
      cp -r "${TEMPLATES_ROOT_DIR}" "${RUN_TEMPLATES_ROOT}"
      cat "${TEST_DIR}/weaver-config.yaml" >> "${RUN_TEMPLATES_ROOT}/${TEMPLATE_NAME}/weaver.yaml"
    fi
    # Note: We force ourselves into test dir, so provenance of files is always consistently relative.
    pushd "${TEST_DIR}"
    NO_COLOR=1 ${WEAVER} registry generate \
      -r registry \
      --v2 \
      --quiet \
      ${PARAMS_ARG} \
      --templates="${RUN_TEMPLATES_ROOT}" \
      ${TEMPLATE_NAME} \
      ${OBSERVED_DIR}
    popd
  fi
  # TODO - put errors / diagnostics into a file.
#   if [ $? -ne 0 ]; then
#     cat "${OBSERVED_DIR}/stderr"
#   fi
  check_output "${OBSERVED_DIR}" "${TEST_DIR}/expected" "${TEST_NAME} - Template Output"
}

# Runs a snippet (embed) test via `registry update-markdown`.
# `update-markdown` only looks for `{templates}/registry/{target}/snippet.md.j2`,
# so we stage the package under a temporary `registry/<target>` layout regardless
# of where the package actually lives (e.g. `templates/docs/markdown`).
# Args:
#     1 - Test directory (contains registry/, markdown/, expected/)
#     2 - Template package directory
#     3 - Observed output directory (seeded with a copy of markdown/)
run_snippet_test() {
  SNIP_TEST_DIR="$1"
  SNIP_PACKAGE_DIR="$2"
  SNIP_OBSERVED_DIR="$3"
  SNIP_TARGET=$(basename "${SNIP_PACKAGE_DIR}")
  SNIP_TEMPLATES=$(mktemp -d)
  mkdir -p "${SNIP_TEMPLATES}/registry/${SNIP_TARGET}"
  cp "${SNIP_PACKAGE_DIR}"/*.j2 "${SNIP_PACKAGE_DIR}"/weaver.yaml "${SNIP_TEMPLATES}/registry/${SNIP_TARGET}/"
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
    --templates="${SNIP_TEMPLATES}" \
    --target "${SNIP_TARGET}" \
    "${SNIP_OBSERVED_DIR}"
  popd
  rm -rf "${SNIP_TEMPLATES}"
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
