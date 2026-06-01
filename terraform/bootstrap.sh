#!/bin/bash

set -euo pipefail

# Usage
usage() {
  echo "Usage: $0 -b <bucket-name> [-r <region>]"
  echo "  -b  Bucket name (required)"
  echo "  -r  Region (default: us-east-1)"
  exit 1
}

# Defaults
REGION="us-east-1"
BUCKET=""

# Parse args
while getopts "b:r:" opt; do
  case $opt in
    b) BUCKET="$OPTARG" ;;
    r) REGION="$OPTARG" ;;
    *) usage ;;
  esac
done

# Validate
if [[ -z "$BUCKET" ]]; then
  echo "Error: bucket name is required"
  usage
fi

echo "Creating S3 bucket: $BUCKET in $REGION"

# Create the bucket
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION"

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Done — bucket $BUCKET is ready for Terraform state"
