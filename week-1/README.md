# Week 1: Your First Compliant Resource

**Status: Complete**

Terraform that provisions a primary S3 bucket and a log bucket with five NIST SP 800-53 Rev. 5 controls encoded in infrastructure and proven with JSON evidence. This is brick one: everything in weeks 2–6 reads, gates, signs, or maps what you build here.

Part of the [GRC Engineering Club 6-Week Challenge](../README.md).

## What you built

A compliant AWS S3 pair (data + access logs) where controls live in code, not spreadsheets. Proof comes from `terraform show -json`, not screenshots.

## Controls enforced

| Control | Implementation |
|---------|----------------|
| **SC-28** | `aws_s3_bucket_server_side_encryption_configuration` on primary and log buckets (`AES256`) |
| **AC-3** | `aws_s3_bucket_public_access_block` on both buckets (all four flags `true`) |
| **CM-6** | Versioning on primary; `default_tags` on provider (`Project`, `Environment`, `ManagedBy`, `ComplianceScope`) |
| **AU-3 / AU-6** | `aws_s3_bucket_ownership_controls` + `log-delivery-write` ACL on log bucket; `aws_s3_bucket_logging` on primary |

See [WRITEUP.md](WRITEUP.md) for the one-paragraph portfolio summary.

## Prerequisites

- Terraform 1.6+
- AWS CLI v2 with a profile that can create S3 buckets (e.g. `grcengtest-1`)
- Region defaults to `us-east-1`

If you use SSO:

```bash
eval "$(aws configure export-credentials --profile grcengtest-1 --format env)"
export AWS_PROFILE=grcengtest-1
```

## Run it

```bash
cd week-1
export AWS_PROFILE=grcengtest-1

terraform init
terraform validate
terraform plan -var="project_name=grc-challenge" -var="environment=dev" -out=tfplan

mkdir -p evidence
terraform show -json tfplan > evidence/plan.json
cp evidence/plan.json plan.json   # optional; Week 2 Conftest reads this
```

Plan-only satisfies the challenge. To deploy and run live checks:

```bash
terraform apply tfplan
./verify.sh
terraform output encryption_algorithm   # SC-28 attestation → AES256
```

## Verify

**From `evidence/plan.json` (plan-only):**

- `"sse_algorithm": "AES256"` on both encryption resources (SC-28)
- All four public-access flags `true` (AC-3)
- `"status": "Enabled"` under versioning (CM-6)
- Four tags in `tags_all` on bucket resources (CM-6)
- `aws_s3_bucket_logging` with a `target_bucket` (AU-3)

**After apply:** `./verify.sh`

## Done when

- [x] `terraform validate` passes
- [x] `evidence/plan.json` contains all five controls
- [x] If applied: `verify.sh` shows AES256, versioning Enabled, four public-access flags true

## Tear down

Versioned buckets must be emptied before destroy:

```bash
export AWS_PROFILE=grcengtest-1
PRIMARY=$(terraform output -raw bucket_name)
LOG=$(terraform output -raw log_bucket_name)
aws s3 rm "s3://${PRIMARY}" --recursive
aws s3 rm "s3://${LOG}" --recursive
terraform destroy -var="project_name=grc-challenge" -var="environment=dev"
```

## Next week

[Week 2](../week-2/) writes Rego policies that **gate** this plan with Conftest before anything reaches AWS.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider, buckets, all five controls |
| `variables.tf` | `project_name`, `environment`, `region` |
| `outputs.tf` | Bucket names/ARNs + `encryption_algorithm` attestation |
| `verify.sh` | Live SC-28, CM-6, AC-3 checks after apply |
| `evidence/plan.json` | Machine-readable compliance proof |
| `plan.json` | Copy used by Week 2 Conftest |
