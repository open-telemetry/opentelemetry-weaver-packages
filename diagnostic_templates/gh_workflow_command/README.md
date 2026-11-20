# GitHub Actions Workflow Command Diagnostic Template

Formats Weaver diagnostic output as [GitHub Actions workflow commands](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions) so that policy violations and other errors appear as inline annotations on pull requests.

Stability: Development
Owners: @open-telemetry/weaver-package-maintainers

## Usage

Pass this template to `weaver registry check` with `--diagnostic`:

```bash
weaver registry check \
  --registry ./model \
  --diagnostic 'https://github.com/open-telemetry/opentelemetry-weaver-packages.git@main[diagnostic_templates/gh_workflow_command]'
```

Or reference a pinned commit for reproducible CI output:

```bash
weaver registry check \
  --registry ./model \
  --diagnostic 'https://github.com/open-telemetry/opentelemetry-weaver-packages.git@<commit>[diagnostic_templates/gh_workflow_command]'
```

## Output

- **Policy violations** are emitted as `::error` commands, which GitHub turns into
  pull-request annotations pointing at the file and line where the violation
  occurred.
- **Other diagnostics** (e.g. `MissingRequirementLevel`) are emitted inside a
  foldable `::group::Diagnostic report` block so they are visible in the CI log
  but do not clutter the annotation panel.
- **`UnstableFileFormat` advisories** are filtered out. These are emitted by
  Weaver once per `file_format: definition/2` file and reflect the experimental
  status of the v2 format spec, not a real authoring error.

## Example output

```
::group::Policy violation report
::error file=model/myapp/metrics.yaml,title=semconv_attribute_required::message=Attribute 'myapp.request.id' must have requirement_level set
::endgroup::

::group::Diagnostic report
  Warning: myapp.event (myapp/events.yaml:12): MissingRequirementLevel
::endgroup::
```
