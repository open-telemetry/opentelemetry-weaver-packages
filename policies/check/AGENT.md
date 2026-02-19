# Agent Guide for OpenTelemetry Weaver Check Policy Packages

This directory contains `weaver registry check` policy packages, usable via `weaver registry check -p {package}`.

## Policy Package Layout
- Each policy package must include:
    - `*.rego`: Policy logic.
    - `README.md`: Documentation for the package.
    - `tests/`: Directory containing test cases.
- **Test Structure**: `tests/<test_name>/base/` (baseline registry), `tests/<test_name>/current/` (current registry), and `expected-diagnostic-output.json` (expected findings).

## Testing and Validation

Verification is mandatory for all changes. Use the provided build scripts to run tests.

### Running Tests
- **Templates**: Run `./buildscripts/test_weaver_templates.sh`.
- **Policies**: Run `./buildscripts/test_weaver_policies.sh`.

You can run these scripts from the root to test all packages, or from within a specific package directory to test only that package.

### Regression Testing
When modifying a package:
1. Run the existing tests to ensure no regressions.
2. Add a new test case in the `tests/` directory if adding a new feature or fixing a bug.
3. Verify that `observed-output` matches `expected` output.

### Debugging and Diagnostics

When tests fail or policies don't trigger as expected, use the following techniques:

#### Running Specific Tests
To save time, run only the relevant test:
```bash
./buildscripts/test_weaver_policies.sh --test <test_name>
```

#### Coverage Reporting
Use the `--coverage` flag to verify if your Rego rules are being executed:
```bash
./buildscripts/test_weaver_policies.sh --test <test_name> --coverage
```
The script will display a "COVERAGE REPORT" showing which lines of your `.rego` files were hit.

#### Inspecting Observed Output
Actual results are written to:
    `policies/check/<package>/observed-output/tests/<test_name>/diagnostic-output.raw`

The test script automatically pretty-prints this JSON using `jq` for easier comparison.

### Rego Style
When creating a finding for a signal, use the `signal_type` and `signal_name` optional fields.

#### Rego Debugging
You can add temporary `deny` rules to dump the state of variables or the entire registry:
```rego
deny contains finding if {
    some entity in input.registry.entities
    finding := {
        "id": "debug_entity",
        "message": sprintf("entity: %s", [entity]),
        "level": "violation",
        "context": { "entity": entity }
    }
}
```

### Rego Policy Development (V2)

When developing policies for Weaver V2 (`package after_resolution`), use the following guidelines:

#### Input Schema
The policy input follows the `ForgeResolvedRegistry` schema. You can explore it using:

```bash
weaver registry json-schema -j forge-registry-v2
```

Key paths in `input`:
- `input.registry.attributes`: All attributes in the registry.
- `input.registry.metrics`: All metrics.
- `input.registry.spans`: All spans.
- `input.registry.events`: All events.
- `input.registry.entities`: All entities.
- `input.registry.attribute_groups`: All attribute groups.

#### V2 Test Models (`model.yaml`)
Models using `version: '2'` must strictly adhere to the V2 semantic convention structure. For example, `attribute_groups` require `id`, `stability`, `visibility`, `brief`, and `attributes`.

#### Handling V2 Schema Warnings
Weaver issues a warning for version 2 schema files: `Version '2' schema file format is not yet stable`. The test script **filters out** these warnings during comparison. Your `expected-diagnostic-output.json` should **not** include these warnings.

#### Diagnostic Output Formatting
- **Message Escaping**: The `message` field in `diagnostic` often contains a JSON-encoded string in the `context` segment. Ensure double quotes are correctly escaped in your `expected-diagnostic-output.json`.

