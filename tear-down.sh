#!/usr/bin/env bash
set -euo pipefail

echo "Destroying dev, prod, then bootstrap..."

# dev
terraform -chdir=terraform init -reconfigure -input=false -backend-config="key=dev/terraform.tfstate"
terraform -chdir=terraform destroy -var-file=envs/dev.tfvars

# prod
terraform -chdir=terraform init -reconfigure -input=false -backend-config="key=prod/terraform.tfstate"
terraform -chdir=terraform destroy -var-file=envs/prod.tfvars

# bootstrap (local state)
terraform -chdir=terraform/bootstrap init -input=false
terraform -chdir=terraform/bootstrap destroy 
