##  infra changes with CI/CD for data engineering

Bootstrap 

```bash 
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap apply
terraform -chdir=terraform/bootstrap output
# you will see your S3 backend and AWS ARN
```

Create a repo secret as AWS_ROLE_ARN
![Create Repo Secret](actions-secret.png)

Format tf files 
```bash 
terraform -chdir=terraform fmt -recursive
```

Ensure `environment: production` requires manual approval.

![Create a production environment](./create-production-environment.png)

![Add a production review rule for manual review](,./production-review_rule.png)
