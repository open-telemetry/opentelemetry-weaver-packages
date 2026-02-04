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
# - Entities
#   - [x] Entities cannot be removed
#   - [x] Stable Entities cannot become unstable
#   - [x] Stable attributes cannot be dropped from stable entity
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
    some attr in data.registry.attributes
    not registry_attribute_keys[attr.key]
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


# Rule: Detect Stable Attributes moving to unstable
#
# This rule checks for attributes that were stable in the baseline registry
# but are no longer stable in the current registry. Once stable, attributes
# remain forever but may be deprecated.
deny contains finding if {
     # Find stable baseline attributes in latest registry.
     some attr in data.registry.attributes
     attr.stability == "stable"
     some nattr in input.registry.attributes
     attr.key == nattr.key

     # Enforce the policy
     attr.stability != nattr.stability

     # Generate human readable error.
     finding := {
        "id": "compatibility_stable_attribute_now_unstable",
        "context": {
            "attribute_key": attr.key,
        },
        "message": sprintf("Attribute '%s' was stable, but has new stability marker", 
            [attr.key]),
        "level": "violation",
    }
}


# Rule: Detect Stable Attributes changing type
#
# This rule checks for attributes that were stable in the baseline registry
# but are no longer stable in the current registry. Once stable, attributes
# remain forever but may be deprecated.
deny contains finding if {
     # Find stable baseline attributes in latest registry.
     some attr in data.registry.attributes
     attr.stability == "stable"
     some nattr in input.registry.attributes
     attr.key == nattr.key

     # Enforce the policy
     # TODO - deal with enum type changes, probably in enum sections
     not is_enum(attr)
     attr.type != nattr.type

     # Generate human readable error.
     attr_type_string := type_string(attr)
     nattr_type_string := type_string(nattr)
     finding := {
        "id": "compatibility_stable_attribute_changed_type",
        "context": {
            "attribute_key": attr.key,
            "attribute_type": nattr_type_string,
            "previous_attribute_type": attr_type_string,
        },
        "message": sprintf("Attribute '%s' was '%s', but has new type '%s'", [attr.key, attr_type_string, nattr_type_string]),
        "level": "violation",
    }
}


# Rule: Detect Stable enum Attributes changing type
#
# This rule checks for attributes that were stable in the baseline registry
# but are no longer stable in the current registry. Once stable, attributes
# remain forever but may be deprecated.
deny contains finding if {
     # Find stable baseline attributes in latest registry.
     some attr in data.registry.attributes
     attr.stability == "stable"
     some nattr in input.registry.attributes
     attr.key == nattr.key
     # Enforce the policy
     attr.type != nattr.type
     is_enum(attr)
     not is_enum(nattr)

     # Generate human readable error.
     nattr_type_string := type_string(nattr)
     finding := {
        "id": "compatibility_stable_attribute_changed_type",
        "context": {
            "attribute_key": attr.key,
            "attribute_type": nattr_type_string,
            "previous_attribute_type": "enum",
        },
        "message": sprintf("Attribute '%s' was enum, but has new type '%s'", [attr.key, nattr_type_string]),
        "level": "violation",
    }
}


# Rule: Detect Stable Enum members changing stability level
#
# This rule checks for enum values that were stable in the baseline registry
# but are no longer stable in the current registry.
deny contains finding if {
     # Find data we need to enforce: Enums in baseline/current.
     some attr in data.registry.attributes
     attr.stability == "stable"
     some nattr in  input.registry.attributes
     attr.key == nattr.key
     is_enum(attr)
     some member in attr.type.members
     some nmember in nattr.type.members
     member.id == nmember.id

     # Enforce the policy
     member.stability == "stable"
     nmember.stability != "stable"

     # Generate human readable error.
     finding := {
        "id": "compatibility_stable_enum_member_changed_from_stable",
        "context": {
            "attribute_key": attr.key,
            "enum_member_id": member.id,
        },
        "message": sprintf("Enum '%s' had stable member '%s', but is no longer stable", [attr.key, member.id]),
        "level": "violation",
    }
}


# Rule: Enum member values cannot change
#
# This rule checks for enum values that have the same id, but values
# are different.
deny contains finding if {
     # Find data we need to enforce: Enums in baseline/current.
     some attr in data.registry.attributes
     attr.stability == "stable"
     some nattr in input.registry.attributes
     attr.key == nattr.key
     is_enum(attr)
     some member in attr.type.members
     some nmember in nattr.type.members
     member.id == nmember.id

     # Enforce the policy
     member.value != nmember.value

     # Generate human readable error.
     finding := {
        "id": "compatibility_stable_enum_member_changed_from_stable",
        "context": {
            "attribute_key": attr.key,
            "previous_value": member.value,
            "current_value": member.value,
        },
        "message": sprintf("Enum '%s' had stable value '%s', but is now '%s'", [attr.key, member.value, nmember.value]),
        "level": "violation",
    }
}


# Rule: Detect missing Enum members
#
# This rule checks for missing enum values that were present in the baseline registry
# but no longer exist in the current registry. Once added, regardless of their stability,
# enum values must remain in the registry but may be marked as deprecated.
deny contains finding if {
     # Find data we need to enforce: Enums in baseline/current.
     some attr in data.registry.attributes
     some nattr in input.registry.attributes
     attr.key == nattr.key
     is_enum(attr)
     is_enum(nattr)
     current_member_ids := {member.id | some member in nattr.type.members}
     # Enforce the policy
     some member in attr.type.members
     not current_member_ids[member.id]

     # Generate human readable error.
     finding := {
        "id": "compatibility_stable_enum_member_missing",
        "context": {
            "attribute_key": attr.key,
            "member_id": member.id,
        },
        "message": sprintf("Enum '%s' had member '%s', but is no longer defined", [attr.key, member.id]),
        "level": "violation",
    }
}


# Helpers for enum values and type strings
is_enum(attr) := true if count(attr.type.members) > 0
type_string(attr) := attr.type if not is_enum(attr)
type_string(attr) := "enum" if is_enum(attr)
is_opt_in(attr) := true if attr.requirement_level == "opt_in"
