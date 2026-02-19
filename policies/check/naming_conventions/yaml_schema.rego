package after_resolution

import rego.v1

# --- Regex Definitions ---

# not valid: '1foo.bar', 'foo.bar.', 'foo.bar_', 'foo..bar', 'foo._bar' ...
# valid: 'foo.bar', 'foo.1bar', 'foo.1_bar'
name_regex := "^[a-z][a-z0-9]*([._][a-z0-9]+)*$"

# must have at least one dot separating two alphanumeric segments
has_namespace_regex := "^[a-z0-9_]+\\.([a-z0-9._]+)+$"

invalid_name_helper := "must consist of lowercase alphanumeric characters separated by '_' and '.'"

# --- Attribute Rules ---

# Rule: Check attribute name format
deny contains finding if {
    some attr in input.registry.attributes
    not regex.match(name_regex, attr.key)

    finding := {
        "id": "naming_convention_attribute_name_format",
        "context": {
            "attribute_key": attr.key,
        },
        "message": sprintf("Attribute name '%s' is invalid. Attribute name %s", [attr.key, invalid_name_helper]),
        "level": "violation",
    }
}

# Rule: Check attribute name has a namespace
deny contains finding if {
    some attr in input.registry.attributes
    
    # some deprecated attributes have no namespace and need to be ignored
    not attr.deprecated
    not regex.match(has_namespace_regex, attr.key)

    finding := {
        "id": "naming_convention_attribute_name_namespace",
        "context": {
            "attribute_key": attr.key,
        },
        "message": sprintf("Attribute name '%s' should have a namespace. Attribute name %s", [attr.key, invalid_name_helper]),
        "level": "violation",
    }
}

# --- Metric Rules ---

# Rule: Check metric name format
deny contains finding if {
    some metric in input.registry.metrics
    not regex.match(name_regex, metric.name)

    finding := {
        "id": "naming_convention_metric_name_format",
        "context": {
            "metric_name": metric.name,
        },
        "message": sprintf("Metric name '%s' is invalid. Metric name %s", [metric.name, invalid_name_helper]),
        "level": "violation",
        "signal_type": "metric",
        "signal_name": metric.name,
    }
}

# --- Event Rules ---

# Rule: Check event name format
deny contains finding if {
    some event in input.registry.events
    not regex.match(name_regex, event.name)

    finding := {
        "id": "naming_convention_event_name_format",
        "context": {
            "event_name": event.name,
        },
        "message": sprintf("Event name '%s' is invalid. Event name %s", [event.name, invalid_name_helper]),
        "level": "violation",
        "signal_type": "event",
        "signal_name": event.name,
    }
}

# Rule: Check event.name is not referenced in event attributes
deny contains finding if {
    some event in input.registry.events
    some attr in event.attributes
    attr.key == "event.name"

    finding := {
        "id": "naming_convention_event_name_attribute_forbidden",
        "context": {
            "event_name": event.name,
        },
        "message": sprintf("Attribute 'event.name' is referenced on event '%s'. Event name must be provided in the 'name' property of the event.", [event.name]),
        "level": "violation",
        "signal_type": "event",
        "signal_name": event.name,
    }
}

# --- Entity (Resource) Rules ---

# Rule: Check entity type format
deny contains finding if {
    some entity in input.registry.entities
    not regex.match(name_regex, entity.type)

    finding := {
        "id": "naming_convention_entity_type_format",
        "context": {
            "entity_type": entity.type,
        },
        "message": sprintf("Entity type '%s' is invalid. Entity type %s", [entity.type, invalid_name_helper]),
        "level": "violation",
        "signal_type": "entity",
        "signal_name": entity.type,
    }
}

# --- Enum Member Rules ---

# Rule: Check attribute member id format
deny contains finding if {
    some attr in input.registry.attributes
    some member in attr.type.members
    not regex.match(name_regex, member.id)

    finding := {
        "id": "naming_convention_enum_member_id_format",
        "context": {
            "attribute_key": attr.key,
            "member_id": member.id,
        },
        "message": sprintf("Member id '%s' on attribute '%s' is invalid. Member id %s", [member.id, attr.key, invalid_name_helper]),
        "level": "violation",
    }
}
