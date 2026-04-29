# Metrics: `some`

This document describes the `some` metrics.

## `some.metric.attrs` ![Stable](https://img.shields.io/badge/-stable-lightgreen)

this is a metric with attributes

**Instrument**: `counter`

**Unit**: `s`

### Attributes

| Attribute | Type | Requirement Level | Description |
|-----------|------|-------------------|-------------|
| `my.key` | `string` | Required | A key in my registry |

## `some.metric.items` ![Stable](https://img.shields.io/badge/-stable-lightgreen)

this is a metric with items

**Instrument**: `gauge`

**Unit**: `ms`

## `some.metric.with.note` ![Development](https://img.shields.io/badge/-development-blue)

this is a metric with a note

This is an additional note about the metric.

**Instrument**: `histogram`

**Unit**: `ms`

## `some.stable.metric` ![Stable](https://img.shields.io/badge/-stable-lightgreen)

this is a stable metric

**Instrument**: `counter`

**Unit**: `s`

