# Agent Guide for OpenTelemetry Weaver Packages

This repository contains packages for [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver), categorized into `templates` and `policies`.

## Project Structure

- `templates/`: Contains Jinja templates for code and documentation generation.
    - `templates/docs/`: Documentation generation packages.
    - `templates/codegen/`: Code generation packages.
- `policies/`: Contains Rego policies for registry validation.
    - `policies/check/`: Policies used with `weaver registry check`.
- `diagnostic_templates/`: Shared templates used for policy error reporting.
- `buildscripts/`: Bash scripts for running tests.

## Development Workflow

### Tooling
- **OpenTelemetry Weaver**: All packages are designed to be used with the `weaver` CLI. Ensure it is installed and available in your PATH, or set the `WEAVER` environment variable.

### Templates
- Each template package must include:
    - `weaver.yaml`: Configuration for the package.
    - `*.j2`: Jinja templates.
    - `README.md`: Documentation for the package.
    - `tests/`: Directory containing test cases.
- **Test Structure**: `tests/<test_name>/registry/` (input registry) and `tests/<test_name>/expected/` (expected output files).

## Contribution Guidelines

- **Surgical Changes**: Avoid unrelated refactoring. Focus on the package or policy being modified.
- **Documentation**: Every new package must have a `README.md` explaining its purpose and usage.
- **CI Alignment**: Pull requests will trigger the `Checks` workflow, which runs both template and policy tests. Ensure all tests pass locally before submitting.
- **Code Style**: 
    - For Jinja templates, follow existing patterns in `templates/`.
    - For Rego policies, follow patterns in `policies/`.
