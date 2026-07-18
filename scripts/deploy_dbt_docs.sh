#!/bin/bash
# Regenerates the AE-01 dbt docs site and syncs the static files to the AE-05 docs bucket.
# Read-only against AE-01: `dbt docs generate` only writes inside AE-01's own target/, never
# touches AE-01's warehouse or models.
#
# Usage: DOCS_BUCKET=ae05-dbt-docs-... ./scripts/deploy_dbt_docs.sh
set -euo pipefail

: "${DOCS_BUCKET:?Set DOCS_BUCKET to the S3 bucket created by terraform (see: terraform output docs_site_url)}"

AE01_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../ae_01_modern_data_stack" && pwd)"

echo "Regenerating dbt docs in AE-01 ($AE01_DIR)..."
(cd "$AE01_DIR/dbt_project" && source ../.venv/bin/activate && dbt docs generate --profiles-dir .)

echo "Syncing static site to s3://$DOCS_BUCKET ..."
aws s3 sync "$AE01_DIR/dbt_project/target" "s3://$DOCS_BUCKET" \
    --exclude "*" \
    --include "index.html" \
    --include "manifest.json" \
    --include "catalog.json" \
    --include "graph_summary.json" \
    --include "semantic_manifest.json"

echo "Done. Site should be live at the docs_site_url terraform output."
