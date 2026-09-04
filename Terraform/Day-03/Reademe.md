# 🚀 Terraform Multi-Region EC2 Deployment Using Reusable Modules

> **Terraform Day-03 Project** — Building reusable infrastructure using Terraform Modules, AWS Provider Aliases, Data Sources, Variables, Count, and Outputs.

---

## 📌 Project Overview

In this project, I created a reusable Terraform EC2 module and used it to deploy EC2 instances across multiple AWS regions.

Instead of writing separate EC2 resource blocks for every region, I created a **child module** containing reusable EC2 creation logic.

The **root module** is responsible for:

- Configuring AWS providers
- Selecting AWS regions
- Finding AMIs dynamically
- Calling the reusable EC2 module
- Passing values to the child module
- Displaying outputs

The **child EC2 module** is responsible for:

- Creating EC2 instances
- Accepting configuration through variables
- Creating multiple instances using `count`
- Returning instance IDs and IP addresses

---

# 🏗️ Architecture

```text
                         ROOT MODULE
                              |
               +--------------+--------------+
               |                             |
               v                             v
         AWS Provider                  AWS Provider
          aws.south                      aws.east
               |                             |
               v                             v
         ap-south-1                    Second Region
               |                             |
               v                             v
        Ubuntu AMI Data               Ubuntu AMI Data
            Source                        Source
               |                             |
               +-------------+---------------+
                             |
                             v
                      Reusable EC2 Module
                       modules/ec2/
                             |
                  +----------+----------+
                  |                     |
                  v                     v
            South EC2s              East EC2
```

In my test deployment:

```text
South Module
├── south-web-1
└── south-web-2

East Module
└── east-web-1
```

Total infrastructure created:

```text
3 EC2 Instances
```

---

# 📂 Project Structure

```text
Day-03/
│
├── main.tf
├── variables.tf
├── terraform.tfvars
├── data.tf
├── output.tf
│
└── modules/
    └── ec2/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

### Root Module

The files inside `Day-03/` form the **root module**.

The root module decides:

```text
WHAT should be deployed
WHERE it should be deployed
WHAT values should be passed
WHICH provider should be used
```

### Child Module

The directory:

```text
modules/ec2/
```

is the reusable **child module**.

It defines:

```text
HOW an EC2 instance should be created.
```

---

# 🧠 Concepts Covered

This project demonstrates:

- Infrastructure as Code
- Terraform Root Modules
- Terraform Child Modules
- Module Inputs
- Module Outputs
- AWS Provider Aliases
- Multiple AWS Regions
- Terraform Variables
- `terraform.tfvars`
- AWS AMI Data Sources
- Dynamic AMI Discovery
- `count`
- `count.index`
- Terraform Outputs
- Resource References
- Provider Passing to Child Modules
- Terraform State
- Reusable Infrastructure

---

# 1️⃣ AWS Provider Configuration

Multiple AWS provider configurations are created using aliases.

Example:

```hcl
provider "aws" {
  alias  = "south"
  region = var.south_region
}

provider "aws" {
  alias  = "east"
  region = var.east_region
}
```

Provider aliases allow the same AWS provider to be configured multiple times.

For example:

```text
aws.south
   ↓
AWS Region 1

aws.east
   ↓
AWS Region 2
```

This allows Terraform to deploy infrastructure across multiple AWS regions from the same root configuration.

---

# 2️⃣ Why Regions Are Stored in Variables

Instead of hardcoding regions inside the provider:

```hcl
region = "ap-south-1"
```

I use:

```hcl
region = var.south_region
```

The actual value can then be provided through `terraform.tfvars`.

Example:

```hcl
south_region = "ap-south-1"
east_region  = "us-east-1"
```

This makes the configuration easier to modify and reuse.

---

# 3️⃣ Dynamic AMI Discovery Using Data Sources

AMI IDs are region-specific.

Hardcoding an AMI like:

```hcl
ami = "ami-xxxxxxxx"
```

can cause problems when deploying infrastructure in another AWS region.

Instead, this project uses the Terraform `aws_ami` data source.

Example:

```hcl
data "aws_ami" "ubuntu_south" {
  provider = aws.south

  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

The same logic is used with the second provider:

```hcl
data "aws_ami" "ubuntu_east" {
  provider = aws.east

  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

The owner:

```text
099720109477
```

is used to restrict the lookup to Canonical's official Ubuntu AMIs.

---

# 🔄 Data Source Flow

```text
AWS Region
     ↓
AWS Provider Alias
     ↓
aws_ami Data Source
     ↓
Search Ubuntu Images
     ↓
Filter by Owner
     ↓
Filter by Name
     ↓
most_recent = true
     ↓
Latest Matching AMI
     ↓
AMI ID
     ↓
EC2 Module
```

Therefore, instead of manually maintaining:

```hcl
ami = "ami-xxxx"
```

the module receives:

```hcl
ami_id = data.aws_ami.ubuntu_south.id
```

---

# 4️⃣ Creating the Reusable EC2 Module

The reusable EC2 module is located at:

```text
modules/ec2/
```

Its main resource is:

```hcl
resource "aws_instance" "this" {
  count = var.instance_count

  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "${var.instance_name}-${count.index + 1}"
  }
}
```

The module does not contain region-specific values.

For example, it does NOT hardcode:

```hcl
provider = aws.south
```

This keeps the module reusable.

---

# 5️⃣ Child Module Variables

The module receives its configuration through variables.

Example:

```hcl
variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "instance_name" {
  description = "EC2 instance name"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}
```

This means the child module knows **how to create EC2**, but the root module decides the actual configuration.

---

# 6️⃣ Calling Child Module From Root Module

The South EC2 module can be called like:

```hcl
module "south_ec2" {
  source = "./modules/ec2"

  providers = {
    aws = aws.south
  }

  ami_id         = data.aws_ami.ubuntu_south.id
  instance_type  = var.instance_type
  instance_name  = "south-web"
  instance_count = var.instance_count
}
```

The second region uses the **same module**:

```hcl
module "east_ec2" {
  source = "./modules/ec2"

  providers = {
    aws = aws.east
  }

  ami_id         = data.aws_ami.ubuntu_east.id
  instance_type  = var.instance_type
  instance_name  = "east-web"
  instance_count = 1
}
```

This demonstrates the main advantage of Terraform modules:

```text
WRITE ONCE
    ↓
REUSE MULTIPLE TIMES
```

---

# 7️⃣ Passing Providers to Modules

The following block:

```hcl
providers = {
  aws = aws.south
}
```

means:

```text
Root Provider
aws.south
    ↓
Passed to Child Module
    ↓
Child's local "aws" provider
    ↓
EC2 created in South region
```

For the second module:

```hcl
providers = {
  aws = aws.east
}
```

the EC2 instance is created using the second provider configuration.

---

# 8️⃣ Child Module Provider Requirement

The child module explicitly declares its provider requirement.

`modules/ec2/versions.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
```

This tells Terraform that the child module expects a provider named:

```text
aws
```

from:

```text
hashicorp/aws
```

---

# 9️⃣ Using `count` Inside the Module

To create multiple EC2 instances:

```hcl
count = var.instance_count
```

For example:

```hcl
instance_count = 2
```

results in:

```text
aws_instance.this[0]
aws_instance.this[1]
```

Using:

```hcl
Name = "${var.instance_name}-${count.index + 1}"
```

creates names like:

```text
south-web-1
south-web-2
```

---

# 🔟 Module Outputs

Because `count` creates multiple resources, outputs are returned as lists.

Child module `outputs.tf`:

```hcl
output "instance_ids" {
  value = aws_instance.this[*].id
}

output "public_ips" {
  value = aws_instance.this[*].public_ip
}

output "private_ips" {
  value = aws_instance.this[*].private_ip
}
```

The `[*]` expression retrieves the attribute from all created EC2 instances.

Example:

```hcl
aws_instance.this[*].id
```

Conceptually:

```text
aws_instance.this[0].id
aws_instance.this[1].id
        ↓
      List
```

---

# 1️⃣1️⃣ Accessing Child Module Outputs From Root

The root module accesses child module outputs using:

```text
module.<module_name>.<output_name>
```

Example:

```hcl
output "south_instance_ids" {
  value = module.south_ec2.instance_ids
}

output "south_public_ips" {
  value = module.south_ec2.public_ips
}

output "south_private_ips" {
  value = module.south_ec2.private_ips
}

output "east_instance_ids" {
  value = module.east_ec2.instance_ids
}

output "east_public_ips" {
  value = module.east_ec2.public_ips
}

output "east_private_ips" {
  value = module.east_ec2.private_ips
}
```

Flow:

```text
EC2 Resource
     ↓
Child Module Output
     ↓
module.south_ec2.public_ips
     ↓
Root Module Output
     ↓
Terminal
```

---

# 🔗 Complete Variable Flow

One of the most important concepts learned in this project:

```text
terraform.tfvars
       ↓
Root variables.tf
       ↓
var.instance_count
       ↓
module "south_ec2"
       ↓
instance_count = var.instance_count
       ↓
Child variables.tf
       ↓
var.instance_count
       ↓
aws_instance.this
       ↓
count = var.instance_count
       ↓
Multiple EC2 Instances
```

---

# 🛠️ Terraform Commands Used

## Format Terraform Files

```bash
terraform fmt -recursive
```

Formats Terraform files in the root module and child modules.

---

## Initialize Terraform

```bash
terraform init
```

Downloads providers and initializes modules/backend.

When a new module is added, running `terraform init` again is useful to initialize the updated configuration.

---

## Validate Configuration

```bash
terraform validate
```

Checks whether the Terraform configuration is syntactically and internally valid.

---

## Preview Infrastructure Changes

```bash
terraform plan
```

Shows what Terraform intends to:

```text
CREATE
UPDATE
DESTROY
```

before making changes.

---

## Create Infrastructure

```bash
terraform apply
```

Applies the Terraform configuration.

---

## View Outputs

```bash
terraform output
```

Displays configured output values.

---

## Destroy Infrastructure

```bash
terraform destroy
```

Deletes infrastructure managed by the Terraform configuration.

This is especially important for learning projects to avoid unnecessary AWS costs.

---

# 🐛 Problems Faced and Solutions

## Problem 1 — Incorrect EC2 Resource Type

Initially the EC2 resource was referenced using:

```hcl
aws_instances
```

Terraform EC2 resource type is actually:

```hcl
aws_instance
```

### Fix

```hcl
resource "aws_instance" "web" {
}
```

### Learning

Terraform resource addresses must exactly match the resource type and local name.

---

# 🐛 Problem 2 — Duplicate Resource Names

Two resources originally had the same Terraform address.

Example:

```hcl
resource "aws_instance" "Web" {
}

resource "aws_instance" "Web" {
}
```

Terraform resource addresses must be unique within the same module.

### Fix

Use different resource names or, even better, create a reusable module.

---

# 🐛 Problem 3 — Multiple Regions Stored as One String

Incorrect:

```hcl
aws_region = "ap-south-1, ap-east-1"
```

Terraform sees this as **one string**, not two AWS regions.

### Fix

Use separate variables:

```hcl
south_region = "ap-south-1"
east_region  = "us-east-1"
```

Then configure separate provider aliases.

---

# 🐛 Problem 4 — Region-Specific AMI IDs

An AMI ID cannot simply be assumed to work across AWS regions.

### Solution

Use:

```hcl
data "aws_ami"
```

with the appropriate provider alias.

This dynamically discovers a matching AMI in each region.

---

# 🐛 Problem 5 — Data Source Not Declared

Error encountered:

```text
Reference to undeclared resource

A data resource "aws_ami" "ubuntu_east"
has not been declared in the root module.
```

### Cause

`main.tf` referenced:

```hcl
data.aws_ami.ubuntu_east.id
```

but Terraform could not find the corresponding data source in that module.

### Fix

Declare:

```hcl
data "aws_ami" "ubuntu_east" {
  ...
}
```

inside the root module.

### Learning

Terraform modules are isolated.

A resource/data source must exist in the correct module before it can be referenced directly.

---

# 🐛 Problem 6 — Undefined Provider Warning in Child Module

Warning:

```text
Reference to undefined provider
```

Terraform explained that the child module did not explicitly declare the local provider name `aws`.

### Fix

Created:

```text
modules/ec2/versions.tf
```

with:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
```

### Learning

The root module owns provider configurations, while the child module should declare which provider source it requires.

---

# 🐛 Problem 7 — Unsupported Module Output Attribute

Error:

```text
Unsupported attribute
```

The root module was trying to access:

```hcl
module.south_ec2.instance_id
```

but after introducing `count`, the child module output had been changed to:

```hcl
instance_ids
```

### Fix

Changed root reference to:

```hcl
module.south_ec2.instance_ids
```

### Learning

Module outputs form an interface.

If the child defines:

```hcl
output "instance_ids"
```

the parent accesses:

```hcl
module.module_name.instance_ids
```

The names must match.

---

# 🐛 Problem 8 — Only One EC2 Instance Was Created

The goal was to create two South-region instances, but only one was initially created.

### Cause

`instance_count` existed as a variable, but the EC2 resource was not using it with `count`.

### Fix

Added:

```hcl
count = var.instance_count
```

inside:

```hcl
resource "aws_instance" "this"
```

Then passed:

```hcl
instance_count = var.instance_count
```

from the root module.

After running:

```bash
terraform plan
```

Terraform correctly showed:

```text
module.south_ec2.aws_instance.this[0]
module.south_ec2.aws_instance.this[1]
```

---

# 🐛 Problem 9 — Existing Resource Changed After Adding Count

Before using `count`, Terraform tracked:

```text
module.south_ec2.aws_instance.this
```

After introducing `count`, the resource became:

```text
module.south_ec2.aws_instance.this[0]
```

Terraform recognized the existing resource and showed it as moved to the indexed address.

It also updated the Name tag:

```text
south-web
    ↓
south-web-1
```

The second instance became:

```text
south-web-2
```

This demonstrated how Terraform tracks resource addresses through state.

---

# ✅ Final Terraform Plan

After fixing the configuration, Terraform showed the desired result:

```text
South Region
├── south-web-1
└── south-web-2

Second Region
└── east-web-1
```

Terraform successfully created the additional instance without destroying the existing instances unnecessarily.

---

# 🎯 Key Learnings

### Terraform Module

A Terraform module is a collection of Terraform configuration files used together as a reusable infrastructure component.

---

### Root Module

The directory where Terraform commands are executed is the root module.

Example:

```bash
terraform plan
terraform apply
```

---

### Child Module

A module called by another module is a child module.

Example:

```hcl
module "south_ec2" {
  source = "./modules/ec2"
}
```

---

### Module Input

Values are passed from root to child:

```hcl
instance_type = var.instance_type
```

---

### Module Output

Values can be returned from child to root:

```hcl
module.south_ec2.public_ips
```

---

### Data Source

A data source reads information that already exists or is available from a provider.

In this project it was used to dynamically discover Ubuntu AMIs.

---

### Provider Alias

Provider aliases allow multiple configurations of the same provider.

Example:

```text
aws.south
aws.east
```

---

### Count

`count` creates multiple instances of a resource.

```hcl
count = 2
```

creates indexed resources:

```text
resource[0]
resource[1]
```

---

# 💼 Interview Questions From This Project

### What is a Terraform module?

A Terraform module is a reusable collection of Terraform configuration files that can be called from other Terraform configurations.

### What is the difference between a root module and a child module?

The root module is the configuration where Terraform is executed. A child module is called by another module using a `module` block.

### Why use Terraform modules?

Modules reduce code duplication, improve maintainability, standardize infrastructure, and allow infrastructure components to be reused.

### How do you pass values to a Terraform module?

Using module arguments:

```hcl
module "ec2" {
  source = "./modules/ec2"

  instance_type = "t3.micro"
}
```

### How do you access module outputs?

Using:

```text
module.<module_name>.<output_name>
```

Example:

```hcl
module.south_ec2.public_ips
```

### What is a Terraform data source?

A data source allows Terraform to read information from an existing system or provider without creating that object.

### Why use a data source for AMIs?

AMI IDs are region-specific and can change as new images are released. A data source allows Terraform to dynamically find an appropriate AMI.

### What is a provider alias?

A provider alias allows multiple configurations of the same provider, which is useful for multi-region or multi-account infrastructure.

### What happens when `count` is used?

Terraform creates multiple indexed instances:

```text
resource[0]
resource[1]
resource[2]
```

### Why shouldn't infrastructure values always be hardcoded?

Hardcoding makes configurations difficult to reuse across environments and regions. Variables, data sources, locals, and modules make infrastructure more flexible.

---

# 🔐 Git Security

Terraform-generated and sensitive files should not be pushed blindly to Git.

Example `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.pem
crash.log
```

The `.terraform/` directory is especially important because it contains downloaded provider binaries and can be extremely large.

A safe pattern is to provide:

```text
terraform.tfvars.example
```

instead of committing environment-specific `terraform.tfvars`.

---

# 🏁 Final Result

This project successfully demonstrated:

```text
Variables
   +
Provider Aliases
   +
Data Sources
   +
Reusable Modules
   +
Count
   +
Module Inputs/Outputs
   ↓
Reusable Multi-Region AWS Infrastructure
```

Instead of duplicating EC2 configuration for each region, the infrastructure now uses one reusable EC2 child module.

The final design separates responsibilities:

```text
ROOT MODULE
"What and where should I deploy?"

           ↓

CHILD MODULE
"How should I create the EC2 resource?"
```

This makes the Terraform configuration cleaner, reusable, and easier to maintain.

---

# 📚 Terraform Learning Journey

### Day-01
Terraform fundamentals, provider configuration, lifecycle commands, first AWS EC2 deployment, and Terraform state basics.

### Day-02
Variables, outputs, conditional expressions, functions, formatting, `count`, `for_each`, dependencies, and data sources.

### Day-03
Terraform modules, root and child modules, module inputs/outputs, provider aliases, dynamic AMI discovery, multi-region infrastructure, and reusable EC2 deployment.

---

## 🚀 Next: Day-04

Next topics:

- Terraform State Management
- Remote Backend
- S3 Backend
- State Locking
- Team Collaboration
- Protecting Terraform State
