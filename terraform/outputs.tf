output "docs_site_url" {
  description = "Public URL of the dbt docs static site."
  value       = aws_s3_bucket_website_configuration.docs.website_endpoint
}

output "dashboard_url" {
  description = "Public URL of the Streamlit dashboard on EC2."
  value       = "http://${aws_instance.streamlit.public_ip}"
}

output "ec2_public_ip" {
  value = aws_instance.streamlit.public_ip
}

output "data_bucket" {
  value = aws_s3_bucket.data.bucket
}
