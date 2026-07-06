# Entity Associations Policy Package

Enforces referential integrity of entity associations for OpenTelemetry Semantic Conventions.

Stability: Development
Owners: @open-telemetry/specs-semconv-maintainers

## Usage

```bash
$ weaver registry check \
    --v2 \
    -p https://github.com/open-telemetry/opentelemetry-weaver-packages.git[policies/check/entity_associations] \
    -r {your repository}
```

## Details

This package ensures that every entity referenced by a signal via
`entity_associations` resolves to an entity that actually exists in the registry.
A signal that associates an unknown entity produces an
`entity_association_unknown_entity` violation.
