# Terraform Day 02 — Advanced Terraform Configuration

Day 02 focuses on making Terraform configurations more dynamic, reusable, maintainable, and closer to real-world Infrastructure as Code practices.

In Day 01, I learned the basic Terraform workflow and provisioned my first AWS EC2 instance.

In Day 02, I learned how to remove hardcoded values, work with variables and outputs, use conditions and functions, create multiple resources, manage dependencies and lifecycle behavior, and dynamically fetch existing AWS information using data sources.

---

# 1. Providers and Resources

## What is a Provider?

A provider is a plugin that allows Terraform to communicate with an external platform or API.

Examples:

- AWS → `hashicorp/aws`
- Azure → `hashicorp/azurerm`
- GCP → `hashicorp/google`
- Kubernetes → `hashicorp/kubernetes`

Architecture:

```text
Terraform
    |
    v
Provider
    |
    v
Cloud/API
    |
    v
Infrastructure
```

Example AWS provider:

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

## `required_providers` vs `provider`

`required_providers` tells Terraform which provider/plugin is required.

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
```

The provider is downloaded when we run:

```bash
terraform init
```

The `provider` block configures that provider.

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

Simple understanding:

```text
required_providers
       |
       v
Which provider/plugin is required?

provider "aws"
       |
       v
How should the AWS provider be configured?
```

---

# 2. Resources

A resource represents infrastructure that Terraform creates or manages.

Example:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"
}
```

General syntax:

```hcl
resource "<RESOURCE_TYPE>" "<LOCAL_NAME>" {
  # configuration
}
```

For:

```hcl
resource "aws_instance" "web"
```

- `aws_instance` = AWS EC2 resource type
- `web` = Terraform local/logical resource name

The local resource name is not automatically the AWS EC2 Name tag.

AWS Name tag can be configured separately:

```hcl
tags = {
  Name = "web-server"
}
```

Resource attributes can be referenced using:

```hcl
aws_instance.web.public_ip
```

Structure:

```text
aws_instance.web.public_ip
     |        |       |
     |        |       +-- Attribute
     |        +---------- Local resource name
     +------------------- Resource type
```

---

# 3. Terraform Variables

Hardcoding values makes Terraform configurations difficult to reuse.

Example of hardcoding:

```hcl
instance_type = "t3.micro"
```

Instead, we can use an input variable:

```hcl
instance_type = var.instance_type
```

## Declaring a Variable

`variables.tf`:

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

Explanation:

```text
variable "instance_type"
        |
        +-- Variable name

description
        |
        +-- Explains the purpose of the variable

type
        |
        +-- Defines allowed value type

default
        |
        +-- Value used when another value is not provided
```

## Using a Variable

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

Variable reference syntax:

```text
var.<variable_name>
```

Example:

```hcl
var.instance_type
```

---

# 4. `terraform.tfvars`

`variables.tf` declares variables.

`terraform.tfvars` supplies values to those variables.

Example `variables.tf`:

```hcl
variable "aws_region" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_name" {
  type = string
}
```

Example `terraform.tfvars`:

```hcl
aws_region    = "ap-south-1"
instance_type = "t3.micro"
instance_name = "terraform-day02"
```

Then `main.tf` can consume them:

```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}
```

Flow:

```text
variables.tf
     |
     | Declares inputs
     v
terraform.tfvars
     |
     | Provides values
     v
main.tf
     |
     | Uses var.<name>
     v
Infrastructure
```

---

# 5. Variable Types

Terraform supports multiple variable types.

## String

```hcl
variable "region" {
  type = string
}
```

## Number

```hcl
variable "instance_count" {
  type    = number
  default = 2
}
```

## Boolean

```hcl
variable "enable_monitoring" {
  type    = bool
  default = true
}
```

## List

```hcl
variable "availability_zones" {
  type = list(string)

  default = [
    "ap-south-1a",
    "ap-south-1b"
  ]
}
```

Access a list element:

```hcl
var.availability_zones[0]
```

## Map

```hcl
variable "instance_types" {
  type = map(string)

  default = {
    dev  = "t3.micro"
    prod = "t3.medium"
  }
}
```

Access:

```hcl
var.instance_types["dev"]
```

Other Terraform types include:

```text
set
object
tuple
```

These become especially useful when building more complex configurations and modules.

---

# 6. Passing Variables from CLI

Variables can also be passed directly through the command line.

Example:

```bash
terraform plan -var="instance_type=t3.micro"
```

Terraform environment variables can also be used:

```bash
export TF_VAR_instance_type="t3.micro"
```

For normal learning and reusable configuration, `terraform.tfvars` is convenient.

---

# 7. Sensitive Variables

Terraform supports marking variables as sensitive.

Example:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

This helps prevent Terraform from displaying the value in normal CLI output.

However:

> `sensitive = true` does not mean the value is automatically encrypted or removed from Terraform state.

Secrets and Terraform state must still be protected properly.

---

# 8. Terraform Outputs

Outputs expose useful information from Terraform-managed infrastructure.

Examples:

- EC2 instance ID
- Public IP
- Private IP
- Load Balancer DNS
- RDS endpoint
- VPC ID

Example `outputs.tf`:

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.web.private_ip
}
```

After:

```bash
terraform apply
```

Terraform can display:

```text
Outputs:

instance_id = "i-xxxxxxxx"
public_ip   = "x.x.x.x"
private_ip  = "172.31.x.x"
```

Outputs can also be viewed later:

```bash
terraform output
```

Specific output:

```bash
terraform output public_ip
```

## Variables vs Outputs

```text
INPUT VARIABLE

User/config
    |
    v
Terraform
    |
    v
Infrastructure


OUTPUT

Infrastructure
    |
    v
Terraform
    |
    v
Useful information
```

Simple rule:

```text
Variable = Input to Terraform
Output   = Information returned/exposed by Terraform
```

---

# 9. Conditional Expressions

Terraform supports conditional expressions.

Syntax:

```hcl
condition ? true_value : false_value
```

Example:

```hcl
instance_type = var.environment == "production" ? "t3.medium" : "t3.micro"
```

If:

```hcl
environment = "production"
```

Terraform uses:

```text
t3.medium
```

Otherwise:

```text
t3.micro
```

Flow:

```text
Is environment production?
          |
     +----+----+
     |         |
    YES        NO
     |         |
     v         v
 t3.medium   t3.micro
```

Conditional expressions select values based on a condition.

---

# 10. Terraform Functions

Terraform provides built-in functions for transforming and processing values.

We do not need to memorize every function. Functions can be checked from Terraform documentation whenever required.

## `upper()`

```hcl
upper("terraform")
```

Result:

```text
TERRAFORM
```

## `lower()`

```hcl
lower("DEVOPS")
```

Result:

```text
devops
```

## `length()`

```hcl
length(["aws", "docker", "terraform"])
```

Result:

```text
3
```

## `concat()`

```hcl
concat(
  ["aws", "docker"],
  ["terraform"]
)
```

Result:

```text
["aws", "docker", "terraform"]
```

## `lookup()`

Example map:

```hcl
variable "instance_types" {
  type = map(string)

  default = {
    development = "t3.micro"
    production  = "t3.medium"
  }
}
```

Lookup:

```hcl
lookup(var.instance_types, "development", "t3.micro")
```

## `file()`

The `file()` function reads the contents of a file.

Example:

```hcl
user_data = file("install-nginx.sh")
```

This can be useful when providing startup scripts to EC2.

---

# 11. Terraform Console

Terraform provides an interactive console for testing expressions.

Start it using:

```bash
terraform console
```

Examples:

```hcl
> upper("terraform")
"TERRAFORM"
```

```hcl
> length(["aws", "docker", "terraform"])
3
```

```hcl
> var.environment == "production" ? "t3.medium" : "t3.micro"
"t3.micro"
```

Exit:

```text
exit
```

`terraform console` is useful for testing expressions, variables, and functions without applying infrastructure.

---

# 12. Debugging and Formatting

A useful Terraform workflow is:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

## `terraform fmt`

```bash
terraform fmt
```

Formats Terraform configuration according to standard HCL formatting.

Before:

```hcl
resource "aws_instance" "web" {
ami="ami-xxxx"
instance_type="t3.micro"
}
```

After:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-xxxx"
  instance_type = "t3.micro"
}
```

`terraform fmt` improves formatting. It does not prove that the infrastructure configuration is logically correct.

## `terraform validate`

```bash
terraform validate
```

Checks whether the Terraform configuration is syntactically and internally valid.

Example error:

```hcl
instance_type = var.instance_typo
```

when only:

```hcl
variable "instance_type" {}
```

was declared.

Terraform will report an undeclared variable reference.

## `terraform plan`

```bash
terraform plan
```

Plan is also an important troubleshooting and safety step.

It allows us to review proposed infrastructure changes before applying them.

For example:

```text
Plan: 2 to add, 1 to change, 14 to destroy
```

If 14 destroyed resources are unexpected, the plan should not be applied until the reason is understood.

---

# 13. Terraform Debug Logs

For more detailed troubleshooting:

```bash
TF_LOG=DEBUG terraform plan
```

Debug logging is very verbose and should normally only be used when normal Terraform error messages are not enough.

Sensitive information should be considered before storing or sharing debug logs.

---

# 14. `count`

`count` is a Terraform meta-argument used to create multiple instances of a resource or module.

Example:

```hcl
resource "aws_instance" "web" {
  count = 3

  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

Terraform creates resource instances addressed like:

```text
aws_instance.web[0]
aws_instance.web[1]
aws_instance.web[2]
```

## `count.index`

Terraform provides an index for every resource instance.

```hcl
tags = {
  Name = "web-${count.index + 1}"
}
```

Result:

```text
web-1
web-2
web-3
```

## Count using a Variable

```hcl
variable "instance_count" {
  type    = number
  default = 3
}
```

Resource:

```hcl
resource "aws_instance" "web" {
  count = var.instance_count

  ami           = var.ami_id
  instance_type = var.instance_type
}
```

## Conditional Resource Creation

`count` can also be combined with a conditional expression:

```hcl
variable "create_ec2" {
  type    = bool
  default = true
}
```

```hcl
resource "aws_instance" "web" {
  count = var.create_ec2 ? 1 : 0

  ami           = var.ami_id
  instance_type = var.instance_type
}
```

If:

```text
create_ec2 = true
```

then:

```text
count = 1
```

If:

```text
create_ec2 = false
```

then:

```text
count = 0
```

---

# 15. `for_each`

`for_each` is used when multiple resource instances have meaningful and stable unique keys.

Example:

```hcl
variable "servers" {
  type = map(string)

  default = {
    frontend = "t3.micro"
    backend  = "t3.small"
    database = "t3.medium"
  }
}
```

Resource:

```hcl
resource "aws_instance" "web" {
  for_each = var.servers

  ami           = var.ami_id
  instance_type = each.value

  tags = {
    Name = each.key
  }
}
```

Here:

```text
KEY          VALUE

frontend  -> t3.micro
backend   -> t3.small
database  -> t3.medium
```

Terraform resource addresses become:

```text
aws_instance.web["frontend"]
aws_instance.web["backend"]
aws_instance.web["database"]
```

## `each.key`

Returns the current key.

Example:

```hcl
each.key
```

can return:

```text
frontend
```

## `each.value`

Returns the value associated with the current key.

Example:

```hcl
each.value
```

can return:

```text
t3.micro
```

---

# 16. `count` vs `for_each`

Both are used to manage multiple resource instances.

`count`:

```text
aws_instance.web[0]
aws_instance.web[1]
aws_instance.web[2]
```

`for_each`:

```text
aws_instance.web["frontend"]
aws_instance.web["backend"]
aws_instance.web["database"]
```

General rule:

```text
Need a number of similar copies?
        |
        v
      count


Need resources with meaningful unique keys?
        |
        v
    for_each
```

`for_each` is often preferable when individual resources need stable identities.

---

# 17. `toset()`

`for_each` commonly works with a map or set of strings.

If we have a list:

```hcl
variable "server_names" {
  type = list(string)

  default = [
    "frontend",
    "backend"
  ]
}
```

We can convert it to a set:

```hcl
for_each = toset(var.server_names)
```

Example:

```hcl
resource "aws_instance" "web" {
  for_each = toset(var.server_names)

  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = each.value
  }
}
```

---

# 18. Terraform Dependencies

Terraform builds a dependency graph to understand the relationship between resources.

Example:

```text
VPC
 |
 v
Subnet
 |
 v
EC2
```

Terraform can automatically detect many dependencies through resource references.

---

# 19. Implicit Dependency

Example:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

Because:

```hcl
vpc_id = aws_vpc.main.id
```

references the VPC resource, Terraform automatically understands:

```text
aws_vpc.main
      |
      v
aws_subnet.public
```

This is an implicit dependency.

No explicit `depends_on` is required.

---

# 20. `depends_on`

Sometimes a real dependency exists but Terraform cannot infer it through a direct expression/reference.

In such cases we can explicitly define it:

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type

  depends_on = [
    aws_instance.database
  ]
}
```

Meaning:

```text
Database
   |
   v
Complete first
   |
   v
Application
```

`depends_on` should not be added everywhere.

Prefer implicit dependencies when Terraform can determine the relationship naturally.

---

# 21. Terraform Dependency Graph

Terraform uses resource relationships to determine execution order.

Example:

```text
              VPC
               |
        +------+------+
        |             |
        v             v
    Subnet-A       Subnet-B
        |             |
        v             v
      EC2-A         EC2-B
```

Independent operations may be performed in parallel when possible.

During destruction, dependencies generally work in reverse order:

```text
EC2
 |
 v
Subnet
 |
 v
VPC
```

This helps Terraform safely manage infrastructure relationships.

---

# 22. Lifecycle Meta-Argument

The `lifecycle` block changes how Terraform handles certain resource operations.

Important lifecycle rules learned:

- `create_before_destroy`
- `prevent_destroy`
- `ignore_changes`

---

# 23. `create_before_destroy`

Some changes require Terraform to replace a resource.

Without special lifecycle behavior, replacement can involve destroying an old resource and creating a new one according to the provider/resource behavior.

We can request:

```hcl
lifecycle {
  create_before_destroy = true
}
```

Example:

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}
```

Concept:

```text
Create new resource
        |
        v
New resource exists
        |
        v
Destroy old resource
```

This can help reduce downtime during replacements, although it does not automatically guarantee zero downtime.

---

# 24. `prevent_destroy`

Used to protect important Terraform-managed resources from accidental Terraform destruction.

Example:

```hcl
resource "aws_db_instance" "production" {
  # configuration

  lifecycle {
    prevent_destroy = true
  }
}
```

Concept:

```text
Terraform attempts destruction
          |
          v
prevent_destroy = true
          |
          v
Operation blocked
```

This is useful for critical infrastructure such as production databases.

It is not an AWS-level deletion lock. Someone with sufficient AWS permissions could still delete the resource outside Terraform.

---

# 25. `ignore_changes`

Terraform normally detects differences between configuration and actual infrastructure.

Sometimes a particular attribute is intentionally managed by another system.

Example:

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "web-server"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
```

Terraform will ignore selected changes to `tags` during ongoing update planning.

`ignore_changes` should be used carefully because excessive use can hide meaningful configuration drift.

---

# 26. Terraform Meta-Arguments

The following concepts learned in Day 02 are Terraform meta-arguments:

```text
count
for_each
depends_on
lifecycle
```

These are different from provider-specific resource arguments.

For example:

```hcl
ami = "..."
```

is specific to the AWS EC2 resource.

But:

```hcl
count
for_each
depends_on
lifecycle
```

control how Terraform manages resource instances and relationships.

---

# 27. Data Sources

A Terraform resource creates or manages infrastructure.

A data source reads information from an existing provider/API.

Simple difference:

```text
resource
   |
   v
CREATE / MANAGE


data
   |
   v
READ / FETCH
```

---

# 28. Dynamic Ubuntu AMI using Data Source

Instead of manually hardcoding an AMI:

```hcl
ami = "ami-xxxxxxxx"
```

Terraform can search AWS for an appropriate AMI.

Example:

```hcl
data "aws_ami" "ubuntu" {
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

Then EC2 can use:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}
```

Reference:

```text
data.aws_ami.ubuntu.id
 |      |      |    |
 |      |      |    +-- Attribute
 |      |      +------- Local name
 |      +-------------- Data source type
 +--------------------- Data source
```

Flow:

```text
Terraform
    |
    v
AWS Provider
    |
    v
Search matching Ubuntu AMIs
    |
    v
Select latest matching AMI
    |
    v
AMI ID
    |
    v
EC2 Resource
```

This removes the need to manually copy a fixed AMI ID into the EC2 resource.

---

# 29. Other Data Source Examples

## Existing Default VPC

```hcl
data "aws_vpc" "default" {
  default = true
}
```

Reference:

```hcl
data.aws_vpc.default.id
```

## Availability Zones

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

Reference:

```hcl
data.aws_availability_zones.available.names
```

Data sources are useful when Terraform needs information about infrastructure or provider data that already exists.

---

# 30. Resource vs Data Source

| Resource | Data Source |
|---|---|
| Creates/manages infrastructure | Reads information |
| Uses `resource` | Uses `data` |
| Example: `aws_instance` | Example: `aws_ami` |
| Terraform manages the resource | Terraform consumes information about the object/data |

---

# 31. Important Terraform Workflow

During Day 02, the standard workflow used was:

```bash
terraform fmt
terraform validate
terraform plan
```

When infrastructure actually needs to be created:

```bash
terraform apply
```

When learning/testing a configuration, it is often enough to inspect `terraform plan` without creating unnecessary AWS resources.

---

# 32. Important Git and Security Practices

Terraform generates files and directories that should not normally be committed to Git.

Do not commit:

```text
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfstate
*.tfstate.*
Private keys
AWS credentials
Secrets
```

Example `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.pem
*.key
.env
```

The `.terraform/` directory contains downloaded provider binaries and other generated files.

It can be recreated using:

```bash
terraform init
```

Therefore it should not be committed to Git.

The dependency lock file:

```text
.terraform.lock.hcl
```

should normally be committed because it records selected provider dependency versions/checksums and helps keep provider installation reproducible.

---

# 33. Issue Faced While Pushing to GitHub

While copying the Day 02 directory, the `.terraform/` directory was also copied.

It contained the AWS provider binary:

```text
terraform-provider-aws
```

which was hundreds of MB in size.

GitHub rejected the push because the file exceeded GitHub's normal file size limit.

The `.terraform/` directory was removed and added to `.gitignore`.

Important lesson:

```text
Terraform Source Code      -> Commit
variables.tf               -> Commit
outputs.tf                 -> Commit
README.md                  -> Commit
.terraform.lock.hcl        -> Usually commit

.terraform/                -> Do NOT commit
terraform.tfstate          -> Do NOT commit
Secrets / credentials      -> Do NOT commit
```

---

# 34. Day 02 Interview Revision

## What is a Terraform Provider?

A provider is a plugin that allows Terraform to interact with an external platform or API such as AWS, Azure, GCP, or Kubernetes.

## What is a Terraform Resource?

A resource represents an infrastructure object that Terraform creates or manages.

## What are Terraform Variables?

Variables parameterize Terraform configurations so that the same code can be reused with different input values.

## `variables.tf` vs `terraform.tfvars`

`variables.tf` commonly contains variable declarations.

`terraform.tfvars` supplies values for those variables.

## What are Outputs?

Outputs expose useful values from Terraform configuration or managed infrastructure.

## What is a Conditional Expression?

A conditional expression chooses between two values:

```hcl
condition ? true_value : false_value
```

## What is `count`?

`count` creates multiple resource/module instances identified using numeric indexes.

## What is `for_each`?

`for_each` creates multiple resource/module instances identified using keys.

## `count` vs `for_each`

Use `count` when numeric/indexed copies are suitable.

Use `for_each` when resources have meaningful and stable unique identities.

## What is `depends_on`?

`depends_on` explicitly defines a dependency when Terraform cannot infer the dependency automatically from references.

## What is an Implicit Dependency?

A dependency Terraform automatically understands because one resource expression references another resource's attributes.

## What is `lifecycle`?

`lifecycle` customizes how Terraform handles certain creation, replacement, update, and destruction behavior.

Important rules:

```text
create_before_destroy
prevent_destroy
ignore_changes
```

## What is a Data Source?

A data source reads information from an existing provider/API without Terraform managing that object as a resource.

---

# 35. Day 02 Final Summary

Day 02 moved from basic Terraform configuration to reusable and dynamic Infrastructure as Code.

```text
Provider & Resources
        |
        v
Variables
        |
        v
terraform.tfvars
        |
        v
Outputs
        |
        v
Conditional Expressions
        |
        v
Functions
        |
        v
Debugging / Formatting
        |
        v
count
        |
        v
for_each
        |
        v
Dependencies
        |
        v
depends_on
        |
        v
Lifecycle
        |
        v
Data Sources
```

## Day 02 Completed Topics

- Providers and Resources
- `required_providers` vs `provider`
- Input Variables
- Variable Types
- `terraform.tfvars`
- CLI Variables
- Sensitive Variables
- Outputs
- Conditional Expressions
- Built-in Functions
- Terraform Console
- `terraform fmt`
- `terraform validate`
- Debugging
- `count`
- `count.index`
- Conditional Resource Creation
- `for_each`
- `each.key`
- `each.value`
- `toset()`
- `count` vs `for_each`
- Implicit Dependencies
- Explicit Dependencies
- `depends_on`
- Dependency Graph
- `lifecycle`
- `create_before_destroy`
- `prevent_destroy`
- `ignore_changes`
- Data Sources
- Dynamic AMI Lookup
- Terraform Git/Security Best Practices

---

# Day 02 Outcome

After completing Day 02, I can write Terraform configurations that are more reusable and dynamic instead of relying on hardcoded infrastructure values.

I understand how Terraform accepts inputs, exposes outputs, evaluates expressions, creates multiple resource instances, tracks dependencies, controls resource lifecycle behavior, and reads existing cloud information using data sources.

The next step is **Terraform Modules**, where these concepts will be used to build reusable infrastructure components.
