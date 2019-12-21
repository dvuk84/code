## Kubernetes cluster with Terraform and Ansible on AWS

Terraform plan will build a VPC and spin up three EC2 instances that will be used to create a Kubernetes cluster. Inside the VPC there will be a private subnet and a security group with a few firewall rules to allow the instances to talk to each other. Ansible playbook is used to deploy a Kubernetes cluster with Docker containers.

#### Build info

```bash
$ uname -a
Linux test 4.15.0-72-generic #81-Ubuntu SMP Tue Nov 26 12:20:02 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux

$ terraform -version
Terraform v0.12.18

$ aws --version
aws-cli/1.14.44 Python/3.6.9 Linux/4.15.0-72-generic botocore/1.8.48

$ ansible --version
ansible 2.5.1
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/home/bsd/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python2.7/dist-packages/ansible
  executable location = /usr/bin/ansible
  python version = 2.7.17 (default, Nov  7 2019, 10:07:09) [GCC 7.4.0]
```
#### Prerequisites

The following will need to be installed.

```
sudo apt update
sudo apt install unzip ansible -y
```
Download Terraform binary package for your platform from the official website https://www.terraform.io/downloads.html

```
unzip terraform*.zip
sudo mv terraform /usr/bin/
```

#### How to use

Add AWS API credentials in __aws.credentials__ file. Run Terraform with:

```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

When Terraform completes, you will see three public IP addresses in the output:

```bash
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

server_id = i-019d7d8e1167c3c66, i-05cee18a1d2fb16d5, i-06b64956bb30b1c43
server_ip = <PUBLIC_IP1>, <PUBLIC_IP2>, <PUBLIC_IP3>
```

Add the following to **/etc/ansible/hosts** and update the IP fields with the IP addresses from the Terraform output. The order of IP addresses is irrelevant.

```bash
[kubernetes-master]
kubernetes-master1 ansible_host=<PUBLIC_IP1> 	ansible_user=ubuntu

[kubernetes-workers]
kubernetes-worker1 ansible_host=<PUBLIC_IP2>     ansible_user=ubuntu
kubernetes-worker2 ansible_host=<PUBLIC_IP3>     ansible_user=ubuntu

[kubernetes:children]
kubernetes-master
kubernetes-workers

[kubernetes:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

Change working dir to ansible-playbooks folder and run Ansible with:

```bash
ansible-playbook setup-cluster.yml -e @group_vars/kubernetes.yml
```

Run kubectl on the master, you should see the following:

```
# kubectl get nodes
NAME            STATUS   ROLES    AGE   VERSION
ip-10-0-1-192   Ready    <none>   25m   v1.17.0
ip-10-0-1-234   Ready    <none>   25m   v1.17.0
ip-10-0-1-58    Ready    master   26m   v1.17.0
```

#### Additional options

To store the __terraform.tfstate__ file to an S3 bucket, it will need to be created beforehand and code uncommented in __terraform.tf__.

```bash
sudo apt install awscli -y
aws configure
aws s3api create-bucket --bucket terraform-kubernetes50056 --region us-east-1
```

#### TODO
- ~~create a vpc on aws~~
- ~~provision three EC2 instances~~
- ~~create a Terraform configuration~~
- ~~create a k8s cluster with Ansible~~
- write a setup script to automate building
- build a pipeline in Jenkins
