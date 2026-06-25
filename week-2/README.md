# Week 2: Make the Rules Executable

**Status: Complete**

Three Rego policies read a Terraform plan JSON and deny non-compliant changes. A control you can run beats a control you can describe. Week 2 replaces the human checklist with OPA + Conftest.

Part of the [GRC Engineering Club 6-Week Challenge](../README.md).

## What you built

| Policy | Package | Control |
|--------|---------|---------|
| `sc28_encryption_aws.rego` | `compliance.sc28_aws` | Every bucket has matching encryption config (by reference) |
| `ac3_no_public_aws.rego` | `compliance.ac3_aws` | Every bucket has a complete public access block |
| `cm6_required_tags_aws.rego` | `compliance.cm6_aws` | Taggable resources carry four required tags |

See [WRITEUP.md](WRITEUP.md) for the one-paragraph portfolio summary.

## Prerequisites

- [Open Policy Agent](https://www.openpolicyagent.org/) (`opa`)
- [Conftest](https://www.conftest.dev/)
- A compliant `plan.json` from [Week 1](../week-1/) (`terraform show -json`)

## Run unit tests

From this directory:

```bash
cd week-2
opa test policies/ -v
```

**Done when:** 6/6 tests pass (two per policy: compliant + broken fixture).

## Gate the real Week 1 plan

Generate or refresh the plan in Week 1, then run Conftest **from here**:

```bash
# Week 1 — if plan.json is missing or stale
cd ../week-1
export AWS_PROFILE=grcengtest-1
terraform plan -var="project_name=grc-challenge" -var="environment=dev" -out=tfplan
terraform show -json tfplan > plan.json

# Week 2 — gate it
cd ../week-2
conftest test --policy policies --namespace compliance.sc28_aws ../week-1/plan.json
conftest test --policy policies --namespace compliance.ac3_aws  ../week-1/plan.json
conftest test --policy policies --namespace compliance.cm6_aws  ../week-1/plan.json
```

Use forward slashes in Git Bash: `../week-1/plan.json` (not `..week-1\...`).

All three should pass against your compliant Week 1 plan.

## Prove the gate catches violations

Copy Week 1 to a scratch folder, remove the encryption block from `main.tf`, regenerate `plan.json`, and run SC-28 Conftest. It should fail with a message naming the resource and remediation.

## Key technique: match by reference

At plan time, bucket names are unknown (random suffix). Match encryption and public access block resources to buckets using `configuration.root_module.resources[].expressions.bucket.references`, not string bucket names. Read flag and tag **values** from `planned_values`.

## CM-6 note

Only check **taggable** resource types (e.g. `aws_s3_bucket`). Sub-resources like encryption configs do not receive `default_tags` in `planned_values` and will false-fail if you scan every resource.

## Done when

- [x] `opa test policies/ -v` → 6/6 pass
- [x] Conftest passes SC-28, AC-3, CM-6 against `../week-1/plan.json`
- [x] Deliberately broken plan fails SC-28 with a clear denial message

## Next week

[Week 3](../week-3/) runs this gate automatically in CI on every pull request.

## Files

| File | Purpose |
|------|---------|
| `policies/sc28_encryption_aws.rego` | SC-28 deny rule |
| `policies/ac3_no_public_aws.rego` | AC-3 deny rule |
| `policies/cm6_required_tags_aws.rego` | CM-6 deny rule |
| `policies/*_test.rego` | Spec fixtures (do not edit) |
| `evidence/opa-test-output.txt` | Captured `opa test` output for portfolio |

## Portfolio piece

This is a strong portfolio entry because most people have never seen compliance expressed as **testable code**. You are not describing controls in a spreadsheet. You wrote policies with passing unit tests that deny bad Terraform plans before they reach AWS.

### What to publish

- The `policies/` directory in a public repo, **all six tests green**
- This README (controls + test output + design note below)
- [WRITEUP.md](WRITEUP.md) one-paragraph summary for LinkedIn / resume

Pairs with [Week 1](../week-1/): infrastructure in Terraform, judgment in Rego.

### Controls under test

| NIST control | Policy file | What the deny rule checks |
|--------------|-------------|---------------------------|
| **SC-28** | `sc28_encryption_aws.rego` | Every `aws_s3_bucket` has a matching `aws_s3_bucket_server_side_encryption_configuration` |
| **AC-3** | `ac3_no_public_aws.rego` | Every bucket has a public access block with all four flags `true` |
| **CM-6** | `cm6_required_tags_aws.rego` | Taggable resources (e.g. S3 buckets) include `Project`, `Environment`, `ManagedBy`, `ComplianceScope` |

### Test output

```bash
cd week-2
opa test policies/ -v
```

```
policies\sc28_encryption_aws_test.rego:24:
data.compliance.sc28_aws.test_unencrypted_bucket_denied: PASS
policies\sc28_encryption_aws_test.rego:20:
data.compliance.sc28_aws.test_compliant_bucket_passes: PASS

policies\ac3_no_public_aws_test.rego:39:
data.compliance.ac3_aws.test_missing_pab_denied: PASS

policies\cm6_required_tags_aws_test.rego:24:
data.compliance.cm6_aws.test_all_tags_present_passes: PASS
policies\cm6_required_tags_aws_test.rego:28:
data.compliance.cm6_aws.test_missing_tags_denied: PASS

policies\ac3_no_public_aws_test.rego:35:
data.compliance.ac3_aws.test_complete_pab_passes: PASS
--------------------------------------------------------------------------------
PASS: 6/6
```

Also saved in [`evidence/opa-test-output.txt`](evidence/opa-test-output.txt).

### Design note: match by reference (for hiring managers)

At **plan time**, S3 bucket names are often `(known after apply)` because Terraform has not yet generated the random suffix. If you match encryption or public-access-block resources to buckets by **comparing bucket name strings**, the policy silently misses violations.

The fix: read `input.configuration.root_module.resources[].expressions.bucket.references`. Terraform records dependency strings like `aws_s3_bucket.primary.id`, not the final bucket name. SC-28 and AC-3 match on those references. Flag values (AC-3) and tags (CM-6) come from `planned_values`, where concrete booleans and tag maps appear after planning.

Explaining a non-obvious decision like this is exactly what separates "I ran Conftest once" from "I understand how plan-time policy works."

