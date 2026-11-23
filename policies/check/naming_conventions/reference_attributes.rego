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

# An attribute ending with `_ref` requires its counterpart attribute to have `annotations.value.unbounded_size: true`.
deny contains finding if {
    some attr in input.registry.attributes
    not ref_is_deprecated(attr)
    endswith(attr.key, "_ref")
    base_key := trim_suffix(attr.key, "_ref")
    some base_attr in input.registry.attributes
    base_attr.key == base_key
    not ref_is_unbounded(base_attr)

    finding := {
        "id": "naming_convention_attribute_ref_counterpart_not_unbounded",
        "message": sprintf("Attribute '%s' ends with '_ref' and requires counterpart attribute '%s' to set annotations.value.unbounded_size: true.", [attr.key, base_key]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "base_key": base_key,
        },
    }
}

# A non-deprecated span, event, or refinement that includes a `_ref` attribute must also include its base attribute.
deny contains finding if {
    some signal in ref_checked_signals
    some attr in signal.attributes
    not ref_is_deprecated(attr)
    endswith(attr.key, "_ref")
    base_key := trim_suffix(attr.key, "_ref")
    ref_base_expected(attr.key, base_key)
    not ref_signal_has_attribute(signal, base_key)

    finding := {
        "id": "naming_convention_signal_ref_missing_base",
        "message": sprintf("%s '%s' includes reference attribute '%s' and must also include '%s'.", [signal.signal_type, signal.signal_name, attr.key, base_key]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "base_key": base_key,
        },
        "signal_type": signal.signal_type,
        "signal_name": signal.signal_name,
    }
}

registry_attribute_exists(key) if {
    some a in input.registry.attributes
    a.key == key
}

ref_base_expected(_, base_key) if {
    registry_attribute_exists(base_key)
}

ref_base_expected(attr_key, _) if {
    not registry_attribute_exists(attr_key)
}

ref_is_deprecated(obj) if {
    object.get(obj, "deprecated", null) != null
}

ref_is_unbounded(attr) if {
    annotations := object.get(attr, "annotations", {})
    val_annotations := object.get(annotations, "value", {})
    object.get(val_annotations, "unbounded_size", false) == true
}

ref_signal_has_attribute(signal, key) if {
    some a in signal.attributes
    a.key == key
}

ref_base_span_exists(id) if {
    some s in input.registry.spans
    s.type == id
}

ref_base_event_exists(id) if {
    some e in input.registry.events
    e.name == id
}

ref_checked_signals contains entry if {
    some span in input.registry.spans
    not ref_is_deprecated(span)
    entry := {"signal_type": "span", "signal_name": span.type, "attributes": object.get(span, "attributes", [])}
}

ref_checked_signals contains entry if {
    some event in input.registry.events
    not ref_is_deprecated(event)
    entry := {"signal_type": "event", "signal_name": event.name, "attributes": object.get(event, "attributes", [])}
}

ref_checked_signals contains entry if {
    some span in object.get(object.get(input, "refinements", {}), "spans", [])
    not ref_base_span_exists(span.id)
    not ref_is_deprecated(span)
    entry := {"signal_type": "span", "signal_name": span.id, "attributes": object.get(span, "attributes", [])}
}

ref_checked_signals contains entry if {
    some event in object.get(object.get(input, "refinements", {}), "events", [])
    not ref_base_event_exists(event.id)
    not ref_is_deprecated(event)
    entry := {"signal_type": "event", "signal_name": event.id, "attributes": object.get(event, "attributes", [])}
}
