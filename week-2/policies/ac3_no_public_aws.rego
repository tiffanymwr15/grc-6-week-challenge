# METADATA
# title: AC-3 - Access Enforcement (AWS S3 public access block)
# description: Every aws_s3_bucket must have a public access block with all four flags true.
# custom:
#   control_id: AC-3
#   framework: nist-800-53
#   severity: critical
#   remediation: Add aws_s3_bucket_public_access_block referencing the bucket, all four flags true.
package compliance.ac3_aws

import rego.v1

# TODO (your build): deny any aws_s3_bucket that does not have a matching
# aws_s3_bucket_public_access_block with block_public_acls, block_public_policy,
# ignore_public_acls, and restrict_public_buckets all set to true.
#
# Match the bucket by reference the way sc28_encryption_aws.rego does, in
# input.configuration.root_module.resources[].expressions.bucket.references.
# Read the four flag values from input.planned_values.root_module.resources[]
# where .address is the public access block's address.
#
# The stub below keeps `deny` defined (empty) so the test file loads. Replace it.

bucket_addresses contains addr if {
    some r in input.configuration.root_module.resources
    r.type == "aws_s3_bucket"
    addr := sprintf("aws_s3_bucket.%s", [r.name])
}
pab_for(bucket_addr) := pab if {
    some r in input.configuration.root_module.resources
    r.type == "aws_s3_bucket_public_access_block"
    some ref in r.expressions.bucket.references
    pab_references_bucket(ref, bucket_addr)
    pab := {"address": sprintf("aws_s3_bucket_public_access_block.%s", [r.name])}
}
pab_planned_values(addr) := values if {
    some r in input.planned_values.root_module.resources
    r.address == addr
    values := r.values
}
has_complete_pab(bucket_addr) if {
    pab := pab_for(bucket_addr)                    # step 1: find PAB in configuration
    planned := pab_planned_values(pab.address)     # step 2: line 35 — read flags
    planned.block_public_acls == true
    planned.block_public_policy == true
    planned.ignore_public_acls == true
    planned.restrict_public_buckets == true
}

pab_references_bucket(ref, bucket_addr) if ref == bucket_addr
pab_references_bucket(ref, bucket_addr) if ref == sprintf("%s.id", [bucket_addr])

deny contains msg if {
    bucket := bucket_addresses[_]
    not has_complete_pab(bucket)
    msg := sprintf("[AC-3] %s: missing or incomplete public access block.", [bucket])
}