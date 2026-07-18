data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "streamlit" {
  name        = "${var.project_name}-sg"
  description = "SSH from a single trusted CIDR; HTTP open for the public dashboard demo"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "Streamlit dashboard"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_instance" "streamlit" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.streamlit.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_streamlit.name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    app_py          = file("${path.module}/../streamlit_app/app.py")
    data_bucket_name = aws_s3_bucket.data.bucket
  })

  tags = {
    Name    = "${var.project_name}-streamlit"
    Project = var.project_name
  }
}
