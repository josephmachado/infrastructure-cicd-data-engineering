##  infra changes with CI/CD for data engineering

Bootstrap 

```bash 
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap apply
terraform -chdir=terraform/bootstrap output
```

Create a repo secret as AWS_ROLE_ARN
![Create Repo Secret](actions-secret.png)

Format tf files 
```bash 
terraform -chdir=terraform fmt -recursive
```

