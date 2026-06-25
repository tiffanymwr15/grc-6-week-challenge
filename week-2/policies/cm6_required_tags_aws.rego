# METADATA
# title: CM-6 - Configuration Settings (AWS required tags)
# description: Taggable resources must carry the four required compliance tags.
# custom:
#   control_id: CM-6
#   framework: nist-800-53
#   severity: medium
#   remediation: Add the missing tags or rely on provider default_tags.
package compliance.cm6_aws

import rego.v1

required := {"Project", "Environment", "ManagedBy", "ComplianceScope"}

# TODO (your build): deny any taggable resource that is missing one or more
# required tags. With provider default_tags enabled, the merged set is in
# values.tags_all; fall back to values.tags. Read resources from
# input.planned_values.root_module.resources (and child_modules if you nest).
#
# The stub keeps `deny` defined (empty) so the test file loads. Replace it.

all_resources contains r if {
	some r in input.planned_values.root_module.resources
}

# Only resources that carry tags in a real plan. Sub-resources like encryption
# configs and public access blocks do not get default_tags in planned_values.
labelable_type(t) if t == "aws_s3_bucket"

tag_keys(resource) := keys if {
    resource.values.tags_all
    keys := {k | resource.values.tags_all[k]}
}

tag_keys(resource) := keys if {
    not resource.values.tags_all
    resource.values.tags
    keys := {k | resource.values.tags[k]}
}

tag_keys(resource) := set() if {
    not resource.values.tags_all
    not resource.values.tags
}
deny contains msg if {
	resource := all_resources[_]
	labelable_type(resource.type)
	provided := tag_keys(resource)
    missing := required - provided
    count(missing) > 0
    msg := sprintf(
        "[CM-6] %s: missing required tags %v. Remediation: add the missing tags or use provider default_tags.",
        [resource.address, sort([k | some k in missing])],
    )
}