terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

}

provider "aws" {
  region = "us-east-1"
}

# ----------------------------------------
# OIDC Provider
# ----------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9514f4ed3c841c96c43def0f0acbf177405ded12"]
}

# ----------------------------------------
# IAM Role for GitHub Actions
# ----------------------------------------

resource "aws_iam_role" "github_actions" {
  name = "github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:josephmachado/infrastructure-cicd-data-engineering:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:*",
        "s3:*",
        "iam:*",
        "ssm:*"
      ]
      Resource = "*"
    }]
  })
}

# ----------------------------------------
# S3 bucket for Terraform remote state
# ----------------------------------------
# Created here in bootstrap so the MAIN infra (the terraform/ dir) can use it
# as its backend. Bootstrap itself uses a local backend to avoid chicken-and-egg.

resource "aws_s3_bucket" "tf_state" {
  bucket = "jkm-cicd-iac-state"
}

# Versioning lets you recover a previous state file if one gets corrupted.
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest (state can contain sensitive values).
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State must never be public.
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------------
# Outputs
# ----------------------------------------

output "tf_state_bucket" {
  description = "S3 bucket for storing Terraform state."
  value       = aws_s3_bucket.tf_state.id
}

output "aws_role_arn" {
  description = "Paste this into GitHub as the AWS_ROLE_ARN secret."
  value       = aws_iam_role.github_actions.arn
}

resource "local_file" "outputs" {
  filename = "${path.module}/outputs.txt"
  content  = <<-EOT
    aws_role_arn    = ${aws_iam_role.github_actions.arn}
    tf_state_bucket = ${aws_s3_bucket.tf_state.id}
  EOT
}
