# METADATA
# title: SC-28 - Encryption at Rest (AWS S3)
# description: Every aws_s3_bucket must have a matching server-side encryption configuration.
# custom:
#   control_id: SC-28
#   framework: nist-800-53
#   severity: high
#   remediation: Add aws_s3_bucket_server_side_encryption_configuration referencing the bucket.
package compliance.sc28_aws

import rego.v1

# YOUR BUILD: deny any aws_s3_bucket that has no matching
# aws_s3_bucket_server_side_encryption_configuration.
#
# Technique: at plan time the bucket name is unknown, so match by reference, not
# value. Bucket addresses live in input.configuration.root_module.resources[]
# (type == "aws_s3_bucket"). The encryption resource references its bucket in
# .expressions.bucket.references (strings like "aws_s3_bucket.primary.id").
#
# Make the two tests in sc28_encryption_aws_test.rego pass. The stub below keeps
# `deny` defined so the tests load. Replace it.

bucket_addresses contains addr if {
    some r in input.configuration.root_module.resources
    r.type == "aws_s3_bucket"
    addr := sprintf("aws_s3_bucket.%s", [r.name])
}

has_encryption(bucket_addr) if {
    some r in input.configuration.root_module.resources
    r.type == "aws_s3_bucket_server_side_encryption_configuration"
    some ref in r.expressions.bucket.references
    references_bucket(ref, bucket_addr)
}

references_bucket(ref, bucket_addr) if ref == bucket_addr
references_bucket(ref, bucket_addr) if ref == sprintf("%s.id", [bucket_addr])

deny contains msg if {
    bucket := bucket_addresses[_]
    not has_encryption(bucket)
    msg := sprintf(
        "[SC-28] %s: no matching aws_s3_bucket_server_side_encryption_configuration. Remediation: add one referencing this bucket.",
        [bucket],
    )
}