# --- Docs bucket: public static website hosting for `dbt docs generate` output (AE-01) ---
# Rebuilds the "static website in an S3 bucket" half of the AWS Introduction bootcamp, but the
# content is a real artifact (the dbt lineage/docs site) instead of a placeholder index.html.

resource "aws_s3_bucket" "docs" {
  bucket = var.docs_bucket_name

  tags = {
    Project = var.project_name
  }
}

resource "aws_s3_bucket_website_configuration" "docs" {
  bucket = aws_s3_bucket.docs.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "docs" {
  bucket = aws_s3_bucket.docs.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "docs_public_read" {
  bucket = aws_s3_bucket.docs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.docs.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.docs]
}

# --- Data bucket: private. Only the EC2 role (iam.tf) can read it. ---
# Bootcamp exercise made the bucket public to serve the CSV to the Streamlit app; here the app
# reads it through an IAM role instead, so the bucket stays private end to end.

resource "aws_s3_bucket" "data" {
  bucket = var.data_bucket_name

  tags = {
    Project = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
