Kubernetes cluster with Terraform and Ansible provisioner on AWS.

```bash
$ terraform -version
Terraform v0.12.18
```

```bash
$ aws --version
aws-cli/1.14.44 Python/3.6.9 Linux/4.15.0-72-generic botocore/1.8.48
```

To store the __terraform.tfstate__ file to an S3 bucket, it will need to be created beforehand and code uncommented in __terraform.tf__.

```bash
aws configure
aws s3api create-bucket --bucket terraform-kubernetes50056 --region us-east-1
```

Before running Terraform, add AWS API credentials in __aws.credentials__ file. Run with:

```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

**TODO:**
- ~~create a vpc on aws~~
- ~~provision three EC2 instances~~
- ~~create a Terraform configuration~~
- create a k8s cluster with Ansible
- set up pods
