package after_resolution

import rego.v1

# Rule: Check that metric briefs end with a period
deny contains finding if {
    some metric in input.registry.metrics
    brief := metric.brief
    
    # Remove trailing whitespace and check if it ends with period
    trimmed_brief := trim(brief, " \n")

    # Allow empty briefs - only check non-empty ones
    trimmed_brief != ""
    not endswith(trimmed_brief, ".")

    finding := {
        "id": "naming_convention_metric_brief_period",
        "context": {
            "brief": trimmed_brief,
        },
        "message": sprintf("Non-empty metric brief '%s' must end with a period (.).", [trimmed_brief]),
        "level": "violation",
        "signal_type": "metric",
        "signal_name": metric.name,
    }
}
