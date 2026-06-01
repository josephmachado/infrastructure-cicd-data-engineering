variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev or prod). Set per env in tfvars."
  type        = string
}

variable "input_bucket" {
  description = "Name of the input S3 bucket. Must be globally unique per env."
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
