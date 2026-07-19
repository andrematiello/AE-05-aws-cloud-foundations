# Least-privilege IAM for the EC2 instance. This is the deliberate contrast with the bootcamp,
# which had the learner attach `AdministratorAccess` to a user. This role can do exactly one
# thing: read objects from the data bucket. Nothing else, no console access, no other service.

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_streamlit" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "s3_read_data_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.data.arn}/*"]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.data.arn]
  }
}

resource "aws_iam_role_policy" "s3_read_data_bucket" {
  name   = "${var.project_name}-s3-read-data"
  role   = aws_iam_role.ec2_streamlit.id
  policy = data.aws_iam_policy_document.s3_read_data_bucket.json
}

resource "aws_iam_instance_profile" "ec2_streamlit" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_streamlit.name
}
