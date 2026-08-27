# Terraform Learning Journey

This folder contains my Terraform learning notes, hands-on exercises, and projects.

## Day 01 — Terraform Fundamentals

### Topics Covered

* Infrastructure as Code (IaC)
* What is Terraform?
* Why Terraform instead of only shell scripting?
* Terraform vs Ansible
* Terraform installation and verification
* AWS authentication
* Terraform providers
* HCL basics
* Terraform resources
* `terraform init`
* `terraform fmt`
* `terraform validate`
* `terraform plan`
* `terraform apply`
* Creating an AWS EC2 instance
* Terraform state basics
* `terraform state list`
* `terraform destroy`

---

## Infrastructure as Code

Infrastructure as Code means defining and managing infrastructure using configuration files instead of manually creating resources from a cloud console.

```text
Without IaC

Human
  ↓
AWS Console
  ↓
Create Infrastructure Manually
```

```text
With IaC

Terraform Code
      ↓
Terraform
      ↓
AWS Provider
      ↓
AWS API
      ↓
Infrastructure
```

---

## Why Terraform?

Infrastructure can also be automated using shell scripts and AWS CLI.

However, Terraform provides features specifically designed for infrastructure management:

* Declarative configuration
* State management
* Dependency handling
* Change planning
* Reusable infrastructure code
* Multi-cloud provider ecosystem

Shell scripts generally describe the steps to execute.

Terraform describes the desired infrastructure state.

---

## Terraform vs Ansible

```text
Terraform
→ Primarily Infrastructure as Code / provisioning

Ansible
→ Primarily configuration management and automation
```

Typical real-world flow:

```text
Terraform
   ↓
Create VPC, Subnets, EC2, Load Balancer
   ↓
Infrastructure Ready
   ↓
Ansible
   ↓
Install packages
Configure services
Deploy applications
```

---

## Terraform Installation Verification

```bash
terraform -version
```

---

## AWS Authentication

AWS CLI credentials were already configured.

Verification:

```bash
aws sts get-caller-identity
```

Terraform can use AWS credentials through the standard AWS credential chain instead of hardcoding credentials inside `.tf` files.

Never hardcode AWS access keys or secret keys in Terraform code.

---

## Terraform Provider

A provider allows Terraform to communicate with an external platform such as AWS, Azure, or GCP.

Example:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
```

---

## First Terraform Resource

Example EC2 resource:

```hcl
resource "aws_instance" "my_ec2" {
  ami           = "AMI_ID"
  instance_type = "t3.micro"

  tags = {
    Name = "terraform-learning"
  }
}
```

Resource syntax:

```text
resource "RESOURCE_TYPE" "LOCAL_NAME"
```

Example:

```text
aws_instance → AWS EC2 resource type
my_ec2      → Terraform local resource name
```

---

## Terraform Lifecycle Commands

### Initialize

```bash
terraform init
```

Downloads required providers and initializes the Terraform working directory.

### Format

```bash
terraform fmt
```

Formats Terraform files using standard HCL formatting.

### Validate

```bash
terraform validate
```

Checks whether the Terraform configuration is valid.

### Plan

```bash
terraform plan
```

Shows proposed infrastructure changes before applying them.

Common plan symbols:

```text
+   Create
~   Update
-   Destroy
-/+ Replace
```

### Apply

```bash
terraform apply
```

Creates or modifies real infrastructure according to the Terraform configuration.

### Destroy

```bash
terraform destroy
```

Destroys infrastructure managed by the current Terraform configuration/state.

---

## Terraform State

Terraform maintains information about managed infrastructure in a state file:

```text
terraform.tfstate
```

Concept:

```text
main.tf
   ↓
Desired State

terraform.tfstate
   ↓
Terraform's mapping of managed resources

AWS
   ↓
Actual Infrastructure
```

Example:

```bash
terraform state list
```

This shows resources currently tracked in Terraform state.

---

## Desired State Example

If Terraform configuration contains:

```hcl
instance_type = "t3.micro"
```

and AWS already has the same managed instance configuration, running:

```bash
terraform plan
```

should show no infrastructure changes.

If the configuration changes, Terraform compares the desired configuration with the current managed infrastructure and proposes the required changes.

---

## First Hands-On Result

Successfully provisioned an AWS EC2 instance using Terraform.

Lifecycle used:

```text
terraform init
      ↓
terraform fmt
      ↓
terraform validate
      ↓
terraform plan
      ↓
terraform apply
      ↓
EC2 Created
      ↓
terraform state list
      ↓
terraform destroy
```

---

## Important Security Notes

Do not commit:

```text
terraform.tfstate
terraform.tfstate.backup
.terraform/
AWS credentials
Private keys
Secrets
```

Recommended `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.pem
*.key
.env
```

The Terraform dependency lock file:

```text
.terraform.lock.hcl
```

should normally be committed to version control.

---

## Day 01 Outcome

By the end of Day 01 I understood:

* What Infrastructure as Code means
* Why Terraform is useful
* Terraform vs shell scripting
* Terraform vs Ansible
* How providers work
* Basic HCL/resource syntax
* Terraform lifecycle
* How Terraform provisions AWS resources
* The purpose of Terraform state
* How to safely destroy managed infrastructure
