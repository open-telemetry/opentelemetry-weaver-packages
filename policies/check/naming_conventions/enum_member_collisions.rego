package after_resolution

import rego.v1

# Enforces uniqueness of enum members *within a single attribute*: member ids,
# member values, and generated constant names must each be unique.

# Member ids must be unique within an attribute.
deny contains finding if {
    some attr in input.registry.attributes
    some member in attr.type.members

    collisions := [m | some m in attr.type.members; m.id == member.id]
    count(collisions) > 1

    finding := enum_member_finding(
        sprintf("Member with id '%s' is defined more than once on attribute '%s'. Member ids must be unique.", [member.id, attr.key]),
        attr.key, member.id,
    )
}

# Member values must be unique within an attribute (deprecated members excluded).
deny contains finding if {
    some attr in input.registry.attributes
    some member in attr.type.members
    not member.deprecated

    collisions := [m |
        some m in attr.type.members
        not m.deprecated
        m.value == member.value
    ]
    count(collisions) > 1

    finding := enum_member_finding(
        sprintf("Member with value '%s' (id '%s') is defined more than once on attribute '%s'. Member values must be unique.", [member.value, member.id, attr.key]),
        attr.key, member.id,
    )
}

# Member constant names must be unique within an attribute
# (members excluded from code generation are ignored).
deny contains finding if {
    some attr in input.registry.attributes
    some member in attr.type.members
    not member.annotations.code_generation.exclude

    const_name := replace(member.id, ".", "_")

    collisions := [m |
        some m in attr.type.members
        replace(m.id, ".", "_") == const_name
        not m.annotations.code_generation.exclude
    ]
    count(collisions) > 1

    finding := enum_member_finding(
        sprintf("Member with constant name '%s' (id '%s') is defined more than once on attribute '%s'. Member constant names must be unique.", [const_name, member.id, attr.key]),
        attr.key, member.id,
    )
}

enum_member_finding(message, attr_key, member_id) := {
    "id": "naming_convention_enum_member_collision",
    "message": message,
    "level": "violation",
    "context": {
        "attribute_key": attr_key,
        "member_id": member_id,
    },
}
