# AWS Deploy Handoff

Everything that can be built and verified without a real AWS account is done (see `development.md`).
What's left needs an actual AWS account — this environment has no working credentials for one (only
an unrelated Supabase ECR profile), so this is a precise checklist for running it yourself, the same
handoff pattern used for BA-02's Power Pivot session.

Follow the steps **in this order** — the billing alert has to exist before anything that can incur
cost (CLAUDE.md rule 6).

## 0. Prerequisites

- [ ] AWS account with billing/payment method configured.
- [ ] AWS CLI installed and configured (`aws configure`) with an IAM user that has permission to
      create S3 buckets, EC2 instances, IAM roles, and Budgets — **not** the root user.
- [ ] Terraform >= 1.7 installed (`terraform -version`).
- [ ] An EC2 key pair created in the target region (`aws ec2 create-key-pair --key-name ae05 --query 'KeyMaterial' --output text > ae05.pem && chmod 400 ae05.pem`).
- [ ] Your current public IP, for `ssh_allowed_cidr` (`curl -s https://checkip.amazonaws.com`).

## 1. Billing alert first

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# fill in docs_bucket_name / data_bucket_name (globally unique) / key_pair_name /
# ssh_allowed_cidr / budget_alert_email

terraform init
terraform apply -target=aws_budgets_budget.monthly
```

- [ ] Apply only the budget resource first.
- [ ] Confirm the SNS/email subscription (check your inbox for a confirmation link).
- [ ] Only proceed once the budget alert is active.

## 2. Provision everything else

```bash
terraform apply
```

- [ ] Review the plan — confirm exactly one S3 bucket for docs, one for data, one EC2 instance,
      one IAM role, one security group.
- [ ] Apply and record the outputs (`docs_site_url`, `dashboard_url`, `ec2_public_ip`).

## 3. Upload the data

```bash
cd ..
AE01_DUCKDB_PATH=../ae_01_modern_data_stack/warehouse.duckdb \
  python scripts/export_marts_to_csv.py
aws s3 cp data/market_prices.csv s3://<data_bucket_name>/market_prices.csv
```

- [ ] Confirm the object exists: `aws s3 ls s3://<data_bucket_name>/`.
- [ ] Wait ~1-2 min for the EC2 `user_data` script to finish installing and starting the systemd
      service, then open `dashboard_url` from the terraform output.

## 4. Deploy the dbt docs site

```bash
DOCS_BUCKET=<docs_bucket_name> ./scripts/deploy_dbt_docs.sh
```

- [ ] Open `docs_site_url` from the terraform output and confirm the dbt docs site loads.

## 5. Evidence

- [ ] Screenshot the live dashboard at `dashboard_url` → `docs/screenshots/dashboard-live.png`.
- [ ] Screenshot the live dbt docs site at `docs_site_url` → `docs/screenshots/dbt-docs-live.png`.
- [ ] Record both URLs in the README, replacing the "pending deploy" language.
- [ ] `curl -o /dev/null -s -w "%{http_code}\n"` both URLs to prove they resolve **logged out**
      (no auth, no VPN) — same verification bar as every other Live project in this portfolio.

## 6. Definition of Done

- [ ] Update `README.md` status from **In progress** to reflect a live deployment (only once steps 1-5
      are done with real evidence — no partial claims).
- [ ] Update the site card and project page (`site/index.html`,
      `site/projects/ae-05-aws-cloud-foundations.html`) to "Live" with the real URLs.
- [ ] Update `docs/pending_issues.md` and `docs/decisions.md` in the workspace root to close this out.

## 7. Tear down (avoid ongoing cost)

Once the screenshots are captured, this project doesn't need to stay running — a portfolio piece is
evidence of what was built, not a service that needs uptime.

```bash
terraform destroy
```

- [ ] Confirm the EC2 instance, both buckets, and the IAM role are gone
      (`aws ec2 describe-instances`, `aws s3 ls`).
- [ ] Optionally keep the budget alert (`terraform state rm` before destroy, or re-apply just that
      resource) since it costs nothing and is useful for the rest of the AWS-touching projects
      (DE-01, DE-04, DE-05) too.
