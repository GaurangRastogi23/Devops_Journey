# 🚀 Terraform Day-05 — Provisioners: Local-Exec & Remote-Exec

## 📌 Project Overview

In Day-05 of my Terraform learning journey, I explored **Terraform Provisioners**.

The main goal of this project was to understand how Terraform can execute commands:

- On the local machine using `local-exec`
- On a remote EC2 instance using `remote-exec`
- Using SSH through the `connection` block
- During resource creation or destruction
- With different failure behaviors using `on_failure`

As part of the hands-on project, Terraform created an EC2 instance and Security Group, connected to the EC2 instance using SSH, installed Nginx using `remote-exec`, and verified the web server using `curl`.

---

# 🎯 Project Architecture

```text
                    Local Machine / WSL
                           |
                           |
                       Terraform
                           |
              +------------+------------+
              |                         |
              | AWS API                 | local-exec
              v                         v
        AWS EC2 Instance         public_ip.txt
              |
              |
          SSH Connection
              |
              v
         remote-exec
              |
              v
       Install Nginx
              |
              v
        Start Nginx
              |
              v
          HTTP :80
              |
              v
       Welcome to nginx!
```

---

# 🧠 What is a Terraform Provisioner?

Terraform provisioners allow commands or scripts to be executed as part of a resource's lifecycle.

For example:

```text
Terraform
    |
    v
Create EC2
    |
    v
Run Provisioner
    |
    v
Execute Command
```

Terraform is primarily designed for **infrastructure provisioning**, so provisioners should not normally be the first choice for configuration management.

They are useful when there is no better declarative mechanism available.

---

# 🏗️ Terraform vs Ansible

An important concept from this project is the difference between Terraform and configuration management tools.

```text
Terraform
    |
    v
Infrastructure Provisioning
    |
    +-- EC2
    +-- VPC
    +-- Security Groups
    +-- S3
    +-- Load Balancers


Ansible
    |
    v
Configuration Management
    |
    +-- Install Packages
    +-- Configure Applications
    +-- Manage Services
    +-- Deploy Configuration Files
```

A common architecture can therefore be:

```text
Terraform
    |
    v
Create Infrastructure
    |
    v
EC2 / VPC / SG
    |
    v
Ansible
    |
    v
Configure Servers
```

---

# 1️⃣ `local-exec` Provisioner

The `local-exec` provisioner executes commands on the **machine where Terraform itself is running**.

It does NOT execute the command inside the EC2 instance.

Example:

```hcl
provisioner "local-exec" {
  command = "echo ${self.public_ip} > public_ip.txt"
}
```

In my environment:

```text
Terraform running in WSL
        |
        v
local-exec
        |
        v
Command runs in WSL
        |
        v
public_ip.txt
```

---

# 🔍 Understanding `self`

Inside a provisioner:

```hcl
self.public_ip
```

refers to an attribute of the resource on which the provisioner is defined.

For example:

```hcl
resource "aws_instance" "web" {

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > public_ip.txt"
  }
}
```

Here:

```text
self.public_ip
      |
      v
Public IP of aws_instance.web
```

---

# 📄 Saving the EC2 Public IP

The following provisioner was used:

```hcl
provisioner "local-exec" {
  command = "echo ${self.public_ip} > public_ip.txt"
}
```

After Terraform created the instance:

```text
Day-05/
|
├── main.tf
└── public_ip.txt
```

The IP could be checked using:

```bash
cat public_ip.txt
```

---

# 2️⃣ `remote-exec` Provisioner

Unlike `local-exec`, `remote-exec` executes commands **on the remote machine**.

In this project:

```text
Terraform
    |
    v
Create EC2
    |
    v
SSH to EC2
    |
    v
remote-exec
    |
    +-- apt-get update
    +-- install nginx
    +-- enable nginx
    +-- start nginx
```

---

# 🔐 Security Group

The EC2 instance required network access for:

```text
SSH  → Port 22
HTTP → Port 80
```

Security Group:

```hcl
resource "aws_security_group" "day05_sg" {
  name = "terraform-day05-sg"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

> **Security Note:** Allowing SSH from `0.0.0.0/0` is acceptable only for temporary learning/testing scenarios. In production, SSH should be restricted to trusted IP ranges or replaced with more secure access mechanisms such as a bastion host or AWS Systems Manager Session Manager.

---

# 🖥️ EC2 Resource

The EC2 instance was configured with an existing AWS key pair:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-01a00762f46d584a1"
  instance_type = "t3.micro"
  key_name      = "My_key_pair"

  vpc_security_group_ids = [
    aws_security_group.day05_sg.id
  ]

  tags = {
    Name = "terraform-day05"
  }
}
```

The key pair allows Terraform to establish an SSH connection with the server.

---

# 🔗 Terraform `connection` Block

For `remote-exec`, Terraform needs to know how to connect to the remote server.

```hcl
connection {
  type        = "ssh"
  user        = "ubuntu"
  private_key = file("~/.ssh/My_key_pair.pem")
  host        = self.public_ip
}
```

---

# 🔍 Connection Block Explained

### Connection Type

```hcl
type = "ssh"
```

Terraform uses SSH.

### User

```hcl
user = "ubuntu"
```

The Ubuntu AMI uses the `ubuntu` SSH user.

### Private Key

```hcl
private_key = file("~/.ssh/My_key_pair.pem")
```

Terraform's `file()` function reads the private key file.

### Host

```hcl
host = self.public_ip
```

Terraform connects to the public IP of the newly created EC2 instance.

Flow:

```text
Terraform
    |
    | private key
    |
    | SSH :22
    v
EC2 Public IP
```

---

# 🌐 Installing Nginx with `remote-exec`

The following provisioner was used:

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y nginx",
    "sudo systemctl enable nginx",
    "sudo systemctl start nginx"
  ]
}
```

The `inline` argument contains commands that Terraform executes on the remote machine.

Execution:

```text
SSH Connection
      |
      v
sudo apt-get update
      |
      v
Install Nginx
      |
      v
Enable Nginx
      |
      v
Start Nginx
```

---

# 🧪 Testing Nginx

Because `local-exec` stored the IP inside:

```text
public_ip.txt
```

the web server could be tested using:

```bash
curl http://$(cat public_ip.txt)
```

Result:

```html
<h1>Welcome to nginx!</h1>
```

This confirmed that:

```text
EC2 Created            ✅
SSH Working            ✅
remote-exec Working    ✅
Nginx Installed        ✅
Nginx Running          ✅
Port 80 Accessible     ✅
```

---

# 🐛 Troubleshooting — `terraform output`

Initially I tried:

```bash
curl http://$(terraform output -raw public_ip)
```

and received:

```text
curl: (3) URL rejected: No host part in the URL
```

## Why?

There was no Terraform `output` block defined for `public_ip`.

Therefore:

```bash
terraform output -raw public_ip
```

could not provide the expected IP.

However, the `local-exec` provisioner had already stored the public IP in:

```text
public_ip.txt
```

So the correct command for the current configuration was:

```bash
curl http://$(cat public_ip.txt)
```

which successfully returned the Nginx page.

---

# 📤 Optional Terraform Output

Instead of depending on `public_ip.txt`, an output can also be defined:

```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

Then:

```bash
terraform apply
```

followed by:

```bash
terraform output -raw public_ip
```

can retrieve the IP.

Nginx can then be tested with:

```bash
curl http://$(terraform output -raw public_ip)
```

---

# ⏱️ Creation-Time Provisioners

Provisioners run at resource creation time by default.

Example:

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt-get install -y nginx"
  ]
}
```

Conceptually:

```text
terraform apply
      |
      v
Create Resource
      |
      v
Run Provisioner
```

No explicit `when = create` is required for normal creation-time behavior.

---

# 🗑️ Destroy-Time Provisioners

A provisioner can also run during resource destruction.

Example:

```hcl
provisioner "local-exec" {
  when    = destroy
  command = "echo EC2 is being destroyed"
}
```

Flow:

```text
terraform destroy
       |
       v
Destroy-Time Provisioner
       |
       v
Execute Command
       |
       v
Destroy Resource
```

This concept was studied but not required for the hands-on project.

---

# ❌ Provisioner Failure Handling

Terraform provides `on_failure` to control what should happen if a provisioner fails.

---

## `on_failure = fail`

Example:

```hcl
provisioner "remote-exec" {
  on_failure = fail

  inline = [
    "sudo apt-get install -y nginx"
  ]
}
```

If the command fails:

```text
Provisioner
    |
    v
FAILED ❌
    |
    v
Terraform operation reports failure
```

`fail` is the default behavior, so it usually does not need to be explicitly written.

---

# ➡️ `on_failure = continue`

Example:

```hcl
provisioner "local-exec" {
  command    = "echo something"
  on_failure = continue
}
```

If the provisioner fails:

```text
Provisioner
    |
    v
FAILED ❌
    |
    v
on_failure = continue
    |
    v
Terraform continues
```

This should only be used when failure of that command is acceptable.

---

# ⚠️ Why Provisioners Should Be Used Carefully

Provisioners are supported by Terraform, but they should generally be treated as a **last resort**.

Terraform works best when infrastructure is represented declaratively:

```text
Terraform Resource
       |
       v
Known Desired State
```

Arbitrary shell commands are harder for Terraform to model:

```text
Terraform
       |
       v
Run Shell Script
       |
       v
What exactly changed inside server?
```

Terraform may know:

```text
EC2 exists
```

but not fully understand every configuration change made by arbitrary commands inside the EC2 instance.

---

# ✅ Better Alternatives

Depending on the use case:

```text
Infrastructure
     |
     └── Terraform

Initial instance bootstrapping
     |
     └── user_data / cloud-init

Server configuration
     |
     └── Ansible

Secrets
     |
     └── Secrets Manager / Parameter Store

Application deployment
     |
     └── CI/CD / deployment tooling
```

Provisioners remain useful for cases where a better declarative mechanism is not available.

---

# 🛠️ Terraform Commands Used

Format Terraform configuration:

```bash
terraform fmt
```

Initialize:

```bash
terraform init
```

Validate:

```bash
terraform validate
```

Preview infrastructure:

```bash
terraform plan
```

Create infrastructure:

```bash
terraform apply
```

Check generated public IP:

```bash
cat public_ip.txt
```

Test Nginx:

```bash
curl http://$(cat public_ip.txt)
```

Destroy infrastructure when finished:

```bash
terraform destroy
```

---

# 📚 Important Interview Questions

## What is a Terraform provisioner?

A provisioner allows Terraform to execute commands or scripts associated with a resource's lifecycle.

---

## What is the difference between `local-exec` and `remote-exec`?

```text
local-exec
     |
Runs command on the machine
where Terraform is executing.


remote-exec
     |
Runs commands on a remote
resource through a connection.
```

---

## What is the `connection` block?

The `connection` block defines how Terraform connects to a remote resource for provisioners such as `remote-exec`.

For SSH it can contain:

```text
Host
Username
Private Key
Connection Type
```

---

## What does `self.public_ip` mean?

`self` refers to the resource on which the provisioner is currently defined.

Therefore:

```hcl
self.public_ip
```

refers to that resource's public IP.

---

## What is the `file()` function?

Terraform's `file()` function reads the contents of a file.

Example:

```hcl
private_key = file("~/.ssh/My_key_pair.pem")
```

---

## When does a provisioner run?

By default, a provisioner runs during resource creation.

A destroy-time provisioner can be configured using:

```hcl
when = destroy
```

---

## What is `on_failure`?

It controls Terraform's behavior when a provisioner fails.

Common values:

```text
fail
continue
```

`fail` is the default.

---

## Should Terraform provisioners be used for full server configuration?

Usually no.

For extensive server configuration, configuration-management or bootstrapping mechanisms such as Ansible or cloud-init/user data are generally better choices.

---

## Can Terraform and Ansible be used together?

Yes.

A common pattern is:

```text
Terraform
    |
Create Infrastructure
    |
    v
EC2 / Networking
    |
    v
Ansible
    |
Configure Servers
```

---

# 🎯 Key Learning

The biggest takeaway from Day-05:

```text
local-exec
     ↓
Runs locally


remote-exec
     ↓
Runs remotely


Terraform
     ↓
Best for infrastructure


Ansible
     ↓
Best suited for configuration management
```

---

# 🏁 Final Result

Successfully implemented:

- ✅ Terraform Provisioners
- ✅ `local-exec`
- ✅ `remote-exec`
- ✅ SSH `connection` block
- ✅ EC2 creation
- ✅ Security Group for SSH and HTTP
- ✅ Private key authentication
- ✅ `self` reference
- ✅ `file()` function
- ✅ Nginx installation through Terraform
- ✅ Nginx service startup
- ✅ HTTP verification using `curl`
- ✅ Creation-time provisioner concept
- ✅ Destroy-time provisioner concept
- ✅ `on_failure = fail`
- ✅ `on_failure = continue`
- ✅ Provisioner limitations and best practices

---

# 📚 Terraform Journey

```text
Day-01 → Terraform Fundamentals
Day-02 → Variables, Functions, count, for_each
Day-03 → Modules + Multi-Region Infrastructure
Day-04 → Remote State + S3 Backend + Locking
Day-05 → Provisioners + SSH + Nginx
```

---

## 🚀 Next Step

Continue to Day-06 and build on these Terraform concepts with more production-oriented infrastructure patterns.
