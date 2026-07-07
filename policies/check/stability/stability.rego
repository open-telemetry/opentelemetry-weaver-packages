package after_resolution

import rego.v1

# Helper to check if requirement level is opt_in
is_opt_in(level) if {
    level == "opt_in"
}
is_opt_in(level) if {
    level.opt_in
}

# Set of policy exceptions declared on a signal via
# `annotations.stability.policy_exceptions`. This mirrors the mechanism used by
# the naming_conventions package (`annotations.naming_conventions.policy_exceptions`):
# each check package reads exceptions from its own annotation namespace, and the
# exception keys are the finding ids with the leading `stability_` prefix dropped.
stability_policy_exceptions(signal) := {policy | some policy in signal.annotations.stability.policy_exceptions}

# Ranking of stability levels. Higher number == more stable.
stability_rank := {
    "development": 1,
    "experimental": 1,
    "alpha": 2,
    "beta": 3,
    "release_candidate": 4,
    "stable": 5,
}

# Rule: Stable entities must have identifying attributes.
deny contains finding if {
    some entity in input.registry.entities
    entity.stability == "stable"
    not entity.identity

    finding := {
        "id": "stability_entity_no_identity",
        "context": {},
        "message": sprintf("Stable entity '%s' has no identifying attributes", [entity.type]),
        "level": "violation",
        "signal_type": "entity",
        "signal_name": entity.type,
    }
}

deny contains finding if {
    some entity in input.registry.entities
    entity.stability == "stable"

    count(entity.identity) < 1

    finding := {
        "id": "stability_entity_no_identity",
        "context": {},
        "message": sprintf("Stable entity '%s' has no identifying attributes", [entity.type]),
        "level": "violation",
        "signal_type": "entity",
        "signal_name": entity.type,
    }
}

# Flattened view of every (signal, attribute) pair subject to the stability check.
# Entities contribute both their identity and description attributes.
signal_attribute contains item if {
    some metric in input.registry.metrics
    some attr in metric.attributes
    item := {"signal_type": "metric", "signal_name": metric.name, "signal": metric, "attr": attr}
}

signal_attribute contains item if {
    some event in input.registry.events
    some attr in event.attributes
    item := {"signal_type": "event", "signal_name": event.name, "signal": event, "attr": attr}
}

signal_attribute contains item if {
    some span in input.registry.spans
    some attr in span.attributes
    item := {"signal_type": "span", "signal_name": span.type, "signal": span, "attr": attr}
}

signal_attribute contains item if {
    some entity in input.registry.entities
    some list_name in ["identity", "description"]
    some attr in entity[list_name]
    item := {"signal_type": "entity", "signal_name": entity.type, "signal": entity, "attr": attr}
}

# Rule: A signal must not claim a higher stability than any attribute it
# references, unless that attribute is opt_in. The stable-signal case is the
# special case where the signal has the maximum rank; this rule also catches
# lower-stability mismatches such as a release_candidate signal referencing a
# development attribute.
deny contains finding if {
    some item in signal_attribute

    exception_key := sprintf("%s_lower_stability_attribute", [item.signal_type])
    not stability_policy_exceptions(item.signal)[exception_key]

    attr := item.attr
    not is_opt_in(attr.requirement_level)

    signal_rank := stability_rank[item.signal.stability]
    attr_rank := stability_rank[attr.stability]
    signal_rank > attr_rank

    finding := {
        "id": sprintf("stability_%s_lower_stability_attribute", [item.signal_type]),
        "message": sprintf("%s '%s' has stability '%s' which is higher than the stability '%s' of attribute '%s'; lower-stability attributes are only allowed at 'opt_in' requirement level", [item.signal_type, item.signal_name, item.signal.stability, attr.stability, attr.key]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "attribute_stability": attr.stability,
            "signal_stability": item.signal.stability,
        },
        "signal_type": item.signal_type,
        "signal_name": item.signal_name,
    }
}
