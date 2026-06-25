# GRC Engineering Club — 6 Week Challenge

Six weeks of hands-on GRC engineering: build compliant infrastructure, automate the proof, and wire it into a pipeline that reads, gates, signs, or maps what you ship.

Part of the [GRC Engineering Club](https://www.patreon.com/GRCEngineeringClub) challenge series.

## The pipeline

Each week adds one brick. Later weeks consume what earlier weeks produce.

```
Week 1  Build     →  Compliant Terraform + plan.json evidence
Week 2  Gate      →  Rego policies judge the plan (Conftest)
Week 3  Automate  →  CI runs the gate on every change
Week 4  Sign      →  Evidence vault, integrity, retention
Week 5  Map       →  OSCAL component definition + control links
Week 6  Ship      →  Portfolio piece, end-to-end demo
```

## Weeks

| Week | Folder | Focus | Status |
|------|--------|-------|--------|
| 1 | [`week-1/`](week-1/) | Your first compliant resource (Terraform + evidence) | Complete |
| 2 | [`week-2/`](week-2/) | Make the rules executable (Rego + Conftest) | Complete |
| 3 | [`week-3/`](week-3/) | Run the gate in CI (GitHub Actions) | Not started |
| 4 | [`week-4/`](week-4/) | Evidence as an artifact (capture, sign, store) | Not started |
| 5 | [`week-5/`](week-5/) | Map controls in OSCAL | Not started |
| 6 | [`week-6/`](week-6/) | Portfolio capstone (full story, public repo) | Not started |

## Controls (Weeks 1–2 foundation)

| Control | Week 1 (Terraform) | Week 2 (Policy) |
|---------|-------------------|-----------------|
| **SC-28** | AES-256 on both buckets | `sc28_encryption_aws.rego` |
| **AC-3** | Public access block, four flags | `ac3_no_public_aws.rego` |
| **CM-6** | Versioning + `default_tags` | `cm6_required_tags_aws.rego` |
| **AU-3 / AU-6** | Access logging chain | (Terraform evidence in plan) |

## Quick verify (completed weeks)

**Week 1** — from `week-1/`:

```bash
export AWS_PROFILE=grcengtest-1
terraform validate
# evidence/plan.json holds machine-readable proof
```

**Week 2** — from `week-2/`:

```bash
opa test policies/ -v
conftest test --policy policies --namespace compliance.sc28_aws ../week-1/plan.json
conftest test --policy policies --namespace compliance.ac3_aws  ../week-1/plan.json
conftest test --policy policies --namespace compliance.cm6_aws  ../week-1/plan.json
```

## Repo layout

```
6 Week Challenge/
├── README.md           ← you are here
├── .gitignore
├── week-1/             ← Terraform + evidence/plan.json
├── week-2/             ← policies/ + Conftest
├── week-3/             ← CI workflow (coming)
├── week-4/             ← evidence pipeline (coming)
├── week-5/             ← OSCAL (coming)
└── week-6/             ← portfolio capstone (coming)
```

## Author

Tiffany Walker-Roper — [#GRCEngClubChallenge](https://www.linkedin.com/)
