package after_resolution

import rego.v1

# An attribute ending with `_ref` must have a counterpart attribute without `_ref`.
deny contains finding if {
    some attr in input.registry.attributes
    endswith(attr.key, "_ref")
    base_key := trim_suffix(attr.key, "_ref")
    not registry_attribute_exists(base_key)

    finding := {
        "id": "naming_convention_attribute_ref_counterpart_missing",
        "message": sprintf("Attribute '%s' ends with '_ref' but counterpart attribute '%s' does not exist.", [attr.key, base_key]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "base_key": base_key,
        },
    }
}

# An attribute ending with `_ref` must have type `string`.
deny contains finding if {
    some attr in input.registry.attributes
    endswith(attr.key, "_ref")
    attr.type != "string"

    finding := {
        "id": "naming_convention_attribute_ref_type_violation",
        "message": sprintf("Attribute '%s' ends with '_ref' and must have type 'string', but got '%v'.", [attr.key, attr.type]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "attribute_type": attr.type,
        },
    }
}

registry_attribute_exists(key) if {
    some a in input.registry.attributes
    a.key == key
}
