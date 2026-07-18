variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name/tag every resource this project creates."
  type        = string
  default     = "ae05-aws-cloud-foundations"
}

variable "docs_bucket_name" {
  description = "Globally-unique S3 bucket name for the dbt docs static site. Must be set explicitly (bucket names are global across all AWS accounts)."
  type        = string
}

variable "data_bucket_name" {
  description = "Globally-unique S3 bucket name for the market_prices.csv the Streamlit app reads."
  type        = string
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access. Create one in the console or with `aws ec2 create-key-pair` before applying."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the EC2 instance. Default is a placeholder — set to your own IP/32 before applying, never 0.0.0.0/0."
  type        = string
  default     = "203.0.113.1/32"
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is Free Tier eligible in most accounts."
  type        = string
  default     = "t3.micro"
}

variable "budget_limit_usd" {
  description = "Monthly budget threshold in USD that triggers the billing alert (CLAUDE.md rule 6: set this before provisioning anything else)."
  type        = string
  default     = "10"
}

variable "budget_alert_email" {
  description = "Email address that receives the AWS Budgets alert."
  type        = string
}
