package after_resolution

import rego.v1

# Rule: Detect attribute constant name collisions
# check that attribute constant names do not collide
deny contains finding if {
    some attr in input.registry.attributes

    # ignore attributes that are excluded from code generation
    not attr.annotations["code_generation"]["exclude"]

    # Generate the constant name (weaver-style)
    const_name := replace(attr.key, ".", "_")

    # Look for collisions in registry attributes
    some other_attr in input.registry.attributes
    
    # Not the same attribute
    attr.key != other_attr.key
    
    # Colliding constant name
    replace(other_attr.key, ".", "_") == const_name

    # Not excluded - we support code_genration attribute for semconv.
    not other_attr.annotations["code_generation"]["exclude"]

    finding := {
        "id": "naming_convention_attribute_constant_collision",
        "context": {
            "attribute_key": attr.key,
            "colliding_attribute_key": other_attr.key,
            "constant_name": const_name,
        },
        "message": sprintf("Attribute '%s' has the same constant name '%s' as '%s'.", [attr.key, const_name, other_attr.key]),
        "level": "violation",
    }
}

# Rule: Detect attribute name collisions with namespaces
# check that attribute names do not collide with namespaces
deny contains finding if {
    some attr in input.registry.attributes

    # ignore deprecated attributes
    not attr.deprecated

    prefix := concat("", [attr.key, "."])

    some other_attr in input.registry.attributes

    not other_attr.deprecated
    attr.key != other_attr.key
    startswith(other_attr.key, prefix)

    finding := {
        "id": "naming_convention_attribute_namespace_collision",
        "context": {
            "attribute_key": attr.key,
            "colliding_attribute_key": other_attr.key,
        },
        "message": sprintf("Attribute '%s' name is used as a namespace in the following attribute '%s'.", [attr.key, other_attr.key]),
        "level": "violation",
    }
}
