terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  backend "s3" {
    bucket  = "jkm-cicd-iac-state"
    key     = "infra/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
  required_version = ">= 1.2"
}

provider "aws" {
  region = "us-east-1"
}

# ----------------------------------------
# S3 Bucket
# ----------------------------------------

resource "aws_s3_bucket" "input_bucket" {
  bucket        = var.input_bucket
  force_destroy = true
}

# ----------------------------------------
# AMI
# ----------------------------------------

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----------------------------------------
# IAM Role (EC2 -> S3 access)
# Profile -> Role(s) -> Policy(s)
# ----------------------------------------

resource "aws_iam_role" "ec2" {
  name = "ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole" # Allow EC2 instances to use this IAM role
    }]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.input_bucket.arn,
        "${aws_s3_bucket.input_bucket.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-s3-profile"
  role = aws_iam_role.ec2.name
}

# ----------------------------------------
# EC2 Instance
# ----------------------------------------

resource "aws_instance" "this" {
  ami                  = data.aws_ami.debian.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip git

    pip3 install boto3 --break-system-packages
  EOF

}

