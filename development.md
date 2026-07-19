# 🛤️ Development Track: AWS Cloud Foundations

This is a rebuild of a cloud bootcamp exercise (AWS account, IAM, S3 static hosting, EC2 + Streamlit),
repositioned to serve real AE-01 output instead of tutorial data, and to use Terraform plus
least-privilege IAM instead of console clicks and an admin user.

**Status:** Phases 0-3 complete and verified locally. Phase 4, the real AWS deploy, is a handoff, since
this environment has no working AWS credentials for a personal account.

---

## Phase 0: Source material and scoping

- [x] Read the original bootcamp material (Notion: "AWS - INTRODUCTION", Jornada de Dados), covering
      account setup, IAM/MFA, cost control, S3 static websites, and EC2 + Streamlit reading a CSV from S3
- [x] Decided the reuse angle: serve AE-01's dbt docs site (S3 static) and AE-01's market mart (S3 to
      EC2 to Streamlit) instead of a placeholder page and the tutorial's NYC Uber dataset
- [x] Confirmed no AWS credentials are available in this environment (`aws sts get-caller-identity`
      returns no credentials, and `~/.aws/config` only has an unrelated Supabase ECR profile), so the
      project is scoped as build-and-verify-locally plus a precise handoff, not a live deploy

## Phase 1: Data path (read-only against AE-01)

- [x] `scripts/export_marts_to_csv.py` connects to AE-01's `warehouse.duckdb` in `read_only` mode,
      joins `fct_daily_prices` to `dim_tickers`, and writes `data/market_prices.csv`
- [x] Ran it for real: **5,010 rows** written, matching AE-01's published count exactly
- [x] Committed the CSV so the app runs the same way with or without AWS

**Checkpoint:** ✅ export script proven against real data, output row count cross-checked against AE-01's
own README (5,010).

## Phase 2: Streamlit app

- [x] `streamlit_app/app.py`: sector/ticker filters, a KPI row, and price/volume charts, with the data
      source read from a `MARKET_DATA_URL` env var (a local CSV path or an `s3://` URI, same code either
      way)
- [x] Installed deps with `uv`, ran `streamlit run streamlit_app/app.py --server.port 8532` locally
- [x] Screenshotted with Playwright (`docs/screenshots/streamlit-local.png`), confirming the app loads
      real data, the filters work, and the charts render (AAPL: 501 trading days, $314.86 latest close,
      +34.3% period return, all pulled live from the CSV, not hardcoded)

**Checkpoint:** ✅ app verified end-to-end locally, screenshotted, process cleanly killed afterward.

## Phase 3: Infrastructure as code

- [x] `terraform/budgets.tf`: an AWS Budgets alert, deliberately with **no dependency** on any other
      resource, so it can be applied alone, first (CLAUDE.md rule 6: billing alert before provisioning)
- [x] `terraform/s3.tf`: a docs bucket (public static website, public-access block scoped to allow only
      the bucket policy) and a data bucket (private, default `AES256` encryption, full public-access
      block)
- [x] `terraform/iam.tf`: an EC2 instance role scoped to `s3:GetObject` and `s3:ListBucket` on the data
      bucket only, with no `AdministratorAccess`, no IAM user, and no console access
- [x] `terraform/ec2.tf`: a `t3.micro` (Free Tier eligible), a security group open only on 22 (a single
      trusted CIDR, not `0.0.0.0/0`) and 80, and `user_data` that installs the app as a systemd service
- [x] `terraform/user_data.sh.tftpl`: embeds `streamlit_app/app.py` verbatim via
      `file("${path.module}/../streamlit_app/app.py")` and runs it on port 80, so the public IP alone
      reaches the dashboard
- [x] Hand-reviewed every `.tf` file for consistency, confirming the variable names match between
      `ec2.tf`'s `templatefile()` call and the `.tftpl` placeholders. There's no `terraform` CLI in this
      environment, so `terraform validate`/`plan` couldn't be run; that's flagged as the first step of
      the real deploy.
- [ ] `terraform validate` / `terraform plan` against a real AWS account (Phase 4)

**Checkpoint:** ✅ IaC complete and internally consistent by inspection, though not yet validated against
the real Terraform AWS provider.

## Phase 4: Real AWS deploy (handoff, not done)

Full checklist in [`docs/aws_deploy_handoff.md`](docs/aws_deploy_handoff.md). Summary:

- [ ] Apply the budget alert alone first, confirm the email subscription
- [ ] `terraform apply` the rest (S3 x 2, EC2, IAM, security group)
- [ ] Upload `data/market_prices.csv` to the data bucket
- [ ] Run `scripts/deploy_dbt_docs.sh` to regenerate and sync the dbt docs site
- [ ] Screenshot both live URLs, verify both resolve logged out (`curl` returning 200)
- [ ] Update the README status, site card, and project page from "In progress" to "Live"
- [ ] Run `terraform destroy` once evidence is captured; there's no reason to keep it running

## Concepts to master

- **Least-privilege IAM roles vs. IAM users.** An EC2 instance role scoped to one bucket and one action
  is a materially different security posture than an admin user with a long-lived access key, and it's
  worth being able to explain the difference out loud.
- **S3 static website hosting vs. a private bucket behind an app.** These are two different access
  models, a public bucket policy versus no public access at all mediated by IAM, for two different
  content types.
- **Terraform dependency ordering.** Why `budgets.tf` has zero references to any other resource, and
  why that's what makes `-target` safe to use for it alone.

## Common pitfalls (found or deliberately avoided here)

- **Applying everything at once skips the billing-alert-first requirement.** Using `-target` on the
  budget resource is the whole point of keeping it dependency-free.
- **A public data bucket is the easy way to make the bootcamp's exact Streamlit code work**
  (`pd.read_csv` over a plain HTTPS URL, no auth). It was rejected here specifically so the IAM role
  does real work instead of being decorative.
- **Committing `terraform.tfstate`.** Never do this: it can contain resource attributes verging on
  sensitive, and it always drifts from reality if two people, or two machines, run apply. `.gitignore`
  excludes it from commit #1, the same rule as every other project in this portfolio.
