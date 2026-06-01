variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "input_bucket" {
  type    = string
  default = "some-bucket"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
