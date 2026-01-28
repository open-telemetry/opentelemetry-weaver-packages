package comparison_after_resolution

import rego.v1

# Registry Compatibility Checker
#
# This file contains rules for checking backward compatibility
# between different versions of semantic convention registries.

# Common data structures
registry_attribute_keys := {attr.key |
    some attr in input.registry.attributes
}
registry_metric_names := { g.metric_name | some g in input.registry.metrics }
registry_resource_names := { g.name | some g in input.registry.entities }
registry_event_names := { g.name | some g in input.registry.events }


# Rules we enforce:
# - Attributes
#   - [x] Attributes cannot be removed
#   - [x] Attributes cannot "degrade" stability (stable->experimental)
#   - [x] Stable attributes cannot change type
#   - Enum members
#     - [x] Stable members cannot change stability
#     - [x] Values cannot change
#     - [x] ids cannot be removed
# - Metrics
#   - [x] metrics cannot be removed
#   - [x] Stable metrics cannot become unstable
#   - [x] Stable Metric units cannot change
#   - [x] Stable Metric instruments cannot change
#   - [x] Set of required/recommended attributes must remain the same
# - Resources
#   - [x] resources cannot be removed
#   - [x] Stable Resources cannot become unstable
#   - [x] Stable attributes cannot be dropped from stable resource
# - Events
#   - [x] events cannot be removed
#   - [x] Stable events cannot become unstable
#   - [x] Stable attributes cannot be dropped from stable event
# - Spans - no enforcement yet since id format is not finalized
#   - [ ] spans cannot be removed
#   - [ ] Stable spans cannot become unstable
#   - [ ] Stable attributes cannot be dropped from stable span

# Rule: Detect Removed Attributes
#
# This rule checks for attributes that existed in the baseline registry
# but are no longer present in the current registry. Removing attributes
# is considered a backward compatibility violation.
#
# In other words, we do not allow the removal of an attribute once added
# to the registry. It must exist SOMEWHERE in a group, but may be deprecated.
deny contains finding if {
    # Check if an attribute from the baseline is missing in the current registry
    attr := data.registry.attributes[_]
    not registry_attribute_keys[attr.key]
    true
    finding := {
        "id": "compatibility_removed_attribute",
        "context": {
            "attribute_key": attr.key,
        },
        "message": sprintf("Attribute '%s' no longer exists in the attribute registry", 
            [attr.key]),
        "level": "violation",
    }
}