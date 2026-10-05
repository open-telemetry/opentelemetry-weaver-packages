
---
name: migrate-to-definitions-schema-v2
description: 'Use when writing semantic conventions v2 definition schema (file_format: definition/2*) or migrating v1 schema files to v2 for entities, spans, metrics, events, attribute groups, or signal refinements in any semantic-conventions registry. Enforces minimal attribute groups, internal-by-default visibility, flat structure, and refinement of generic signals over re-declaration.
---

# Migrate semantic conventions from current definition schema to v2

Use this skill when migrating from existing semantic convention (v1, `groups`)
defining attributes, spans, metrics, events, entities, attribute groups, or signal refinement;
to v2 (`file_format: definition/2` or `file_format: definition/2.*`).
Can also be used for new v2 semconv definitions.

## Goal

Produce a v2 definition that is minimal, flat, and resolvable by weaver
without errors.

This skill is not for deciding *whether* a convention should be added or
arguing about attribute names, requirement levels, or stability — those
are upstream design questions. It is also not a generator: bring the
names, descriptions, and examples; the skill shapes the structure around
them.

## Schema Reference

This skill encodes opinions, not the v2 grammar. For top-level sections,
required keys per signal, valid `kind` / `instrument` / `stability` /
`requirement_level` values, and override rules — read the doc directly:

- [Lifecycle and overview](https://raw.githubusercontent.com/open-telemetry/weaver/main/schemas/semconv-schemas.md)
- [Authoring syntax reference](https://raw.githubusercontent.com/open-telemetry/weaver/main/schemas/semconv-syntax.v2.md)
- [Reference of an old syntax](https://raw.githubusercontent.com/open-telemetry/weaver/main/schemas/semconv-syntax.md)

If anything here contradicts these docs, docs win.

## Weaver Commands

Paths (`./model`, `./templates`, etc.) are examples — adjust to the actual registry layout.

| Goal | Command |
|------|---------|
| Validate and package | `weaver registry package -r ./model --v2` |
| Check (no packaging) | `weaver registry check -r ./model --v2` |
| Check policies | `weaver registry check -r ./model --v2 -p https://github.com/open-telemetry/opentelemetry-weaver-packages.git[policies/check/naming_conventions]` |
| Generate registry docs | `weaver registry generate -r ./model --v2 -t ./templates/registry markdown ./docs/registry` |
| Refresh doc snippets | `weaver registry update-markdown -r ./model --v2 -t ./templates --target markdown docs` |

> `weaver registry resolve` is deprecated — always use `registry package` for validation.

Multiple `-p` flags can be combined in a single `check` invocation. When this skill says **package**, **check**, **generate-registry**, or **generate-docs**, it means the matching command above.

> **v2 compatibility:** Policies and templates must support v2. The policies in this repo ([opentelemetry-weaver-packages](https://github.com/open-telemetry/opentelemetry-weaver-packages)) do. For doc generation, confirm the project's templates are v2-aware before running **generate-registry** or **generate-docs**. If the templates are v1-only: skip doc regeneration steps in Procedure and Output Format, and note to the user that comparing **package** output before and after the change is still valid and sufficient for validation. Suggest adopting v2 templates from [semantic-conventions-genai/templates](https://github.com/open-telemetry/semantic-conventions-genai/tree/main/templates) as a starting point.

## Authoring Rules

### 1. Minimal attribute groups

Only create an `attribute_groups` entry when the *same exact set* of
attributes is reused by two or more signals. A group used by exactly
one signal is dead weight — inline the attributes on the signal
directly.

### 2. Visibility: structural vs. documented groups

The right visibility depends on whether the group carries documentation fields:

- **Structural groups** (no `brief` or `stability`, exist only to bundle `ref:` entries
  for use by signals) → `visibility: internal`.
- **Documented groups** (carry `brief` and/or `stability` to appear in generated docs,
  e.g. a reusable "these attributes may be used for X" group) → `visibility: public`.
  The schema enforces this: `check-policies` will reject `internal` when `brief` or
  `stability` are present.

Default to `internal` when writing a new structural group. Promote to `public` only
when the group needs a `brief`/`stability` of its own — that is a deliberate authoring
decision, not a default.

**Side-effect when migrating:** Promoting a group to `public` with a `brief` causes
the template to emit that description inside every `<!-- semconv <group-id> -->` block
in hand-authored docs. If a human already wrote that same text above the block, the
description will be duplicated after regeneration. See Procedure step 5a.

### 3. Flat structure

The [upstream syntax doc](https://github.com/open-telemetry/weaver/blob/main/schemas/semconv-syntax.v2.md#attribute-group-reference)
says it is *NOT RECOMMENDED* to use `ref_group` on another attribute
group. This is not always feasible and conflicts with minimalism and avoiding repetitions.

Do the middle-ground, keep the chain shallow:

- **One level** (`base group → signal`) is the default.
- **Two levels** (`base → composite → signal`) only when multiple signals
  share the same composite shape and inlining would duplicate briefs, notes, or other substantial blocks.
  Justify in review; do not add speculatively.
- **Three+ levels** — almost never. Treat as a refactor signal.

Within an `attributes:` list, list every `ref_group` entry before any
`ref` entry — the group's own attributes appear after the inherited
ones, not interleaved.

```yaml
attribute_groups:
  - id: attributes.<domain>.common         # level 1
    visibility: internal
    attributes:
      - ref: <attr.a>

  - id: attributes.<domain>.client         # level 2
    visibility: internal
    attributes:
      - ref_group: attributes.<domain>.common
      - ref: <attr.b>
```

### 4. Examples must be lists

In v2, `examples` values must always be YAML sequences, even for a single value.
Scalar literals from v1 must be wrapped:

```yaml
# v1
examples: 42
examples: main

# v2
examples: [42]
examples: ['main']
```

### 6. Refinement over redefinition

If the new signal is an implementation-specific variant of a generic
signal that already exists in this registry, declare it in the matching
`*_refinements` section and add only the delta.

Refinements inherit the parent's attributes — do **not** re-list them.
List an inherited attribute only to override its presentation (note,
brief, requirement_level, examples, sampling_relevant — see the syntax
doc for which keys are overridable per signal type).

Tempted to declare the variant in `spans:` and `ref_group:` the parent's
attribute group(s)? Stop and use a refinement. Same applies to implicit
signal groups (`ref_group: span.<parent>`) — see Rule 6.

### 7. Override on the signal, not on the attribute

For a different `requirement_level`, `note`, `brief`, etc. on an
inherited attribute, override at the reference site — do not edit the
underlying attribute definition. Don't duplicate the inherited
`brief` / `note` verbatim; leave them out so the inherited values show
through. Use `note: ""` only when you genuinely want to suppress an
inherited note.

### 8. Implicit signal groups

Weaver exposes each signal's full attribute set — every override and
every inlined ref — as an implicit group named `span.<type>`,
`metric.<name>`, or `event.<name>`. This is undocumented in the upstream
syntax doc; treat as undocumented behavior and verify with **[package](#weaver-commands)**
whenever you rely on it.

Legitimate use: **cross-signal mirroring**, e.g.
`gen_ai.client.inference.operation.details` (an event) uses
`ref_group: span.gen_ai.inference.client` so it picks up every override
the span declaration carries. Re-stating each `ref_group` and override
would drift the moment the span changes.

Do **not** use this inside a new signal under
`spans:` / `metrics:` / `events:` to clone a generic signal — that's
Rule 4's anti-pattern in different syntax. Use `*_refinements` instead.
Symptoms that you are about to drift:

- A `spans:` entry whose `attributes:` is `ref_group: span.<other_type>`
  followed by a small delta.
- A new internal `attributes.<provider>.<thing>` group whose only purpose
  is to hold that delta.

## Refinement Decision Tree

For every new signal, walk this before writing yaml:

1. **Implementation-specific variant of an existing signal?**
   → declare it in `*_refinements` with `ref:` to the parent. Delta only.
   Per-attribute overrides for any inherited attribute whose framing
   changes. Done.
2. **Shares its attribute set with a signal already in the registry?**
   → reuse the existing group via `ref_group`. Delta inline on the signal.
3. **Shares its attribute set with another signal in this same registry?**
   → one shared internal group. One level deep. No nesting.
4. **None of the above?** → inline the attributes on the signal. No group.

## Procedure

1. Identify what the change touches: spans, metrics, events, entities,
   attribute groups, refinements, or several.
2. **Capture a pre-change baseline.** Run **[package](#weaver-commands)** so the resolved-schema
   artifact reflects HEAD; you'll diff against this after editing.
   Skip if the user mentioned a baseline or the working tree is in sync.
3. If syntax for any touched section isn't obvious from surrounding
   files, fetch the v2 syntax reference (see Schema Reference).
4. Walk the Refinement Decision Tree for each new signal.
5. Write the yaml; satisfy the rules.
   - **5a. Documented-group duplicate check.** For every group you are
     migrating to `visibility: public` with a `brief`, grep `docs/` for
     `<!-- semconv <group-id> -->` and read the lines immediately before
     each hit. If there is hand-authored prose that paraphrases or copies
     the `brief`, remove it — the template will now emit it inside the
     autogenerated block, and leaving it outside creates a duplicate after
     regeneration.
6. Run validation (next section). Fix every error.
7. Re-read the diff for: groups used exactly once, `ref_group` chains
   deeper than two levels, `visibility: public` on a structural group that
   has no `brief`/`stability` (should be internal), `visibility: internal`
   on a documented group that carries `brief`/`stability` (policy will
   reject it), re-listed parent attributes on refinements,
   `ref_group: span.<...>` inside a new signal declaration. These are the
   common drifts.
8. Regenerate every committed artifact (see Output Format) and compare
   against the step-2 baseline.

## Validation

The non-negotiable gate: the resolved registry builds cleanly with zero
errors. Run **[package](#weaver-commands)**.

If a **[check](#weaver-commands)** command is configured with policies, run it — it catches
id collisions and naming-convention violations that `package` alone
does not.

## Output Format

Do not write a prose summary of what changed. Link the artifacts. Run in order — docs both consume
the resolved model that `package` produces:

1. **[package](#weaver-commands)** — builds the resolved schema and runs validation.
   Link the resolved schema file.
2. **Docs regeneration** — **[generate-registry](#weaver-commands)** rebuilds the
   per-namespace pages under `docs/registry/`; **[generate-docs](#weaver-commands)**
   refreshes the `<!-- semconv ... -->` snippet tables in hand-authored
   docs. Other registries may combine these under one command.

After running, link every file the regeneration changed:
regenerated `docs/registry/` pages, and any snippet refreshes elsewhere
under `docs/`.
