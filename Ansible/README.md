# Ansible AWS Real-Time Project

## Project Overview

This project demonstrates how Ansible can be used with AWS to provision and manage EC2 instances.

The project was completed in three major tasks:

1. Create three EC2 instances using Ansible loops.
2. Configure SSH key-based authentication between the Ansible control node and EC2 instances.
3. Gather operating system facts and shut down only Ubuntu instances using Ansible conditionals.

The Ansible control node used in this project was **Ubuntu running inside WSL2 through VS Code**.

---

# Architecture

```text
VS Code
   |
   v
WSL Ubuntu
   |
   | Ansible
   |
   +---- boto3 / botocore
   |
   +---- AWS CLI
   |
   v
AWS API
   |
   v
EC2 Instances
   |
   +---- Ubuntu Instance 1
   |
   +---- Ubuntu Instance 2
   |
   +---- Amazon Linux Instance
```

---

# Technologies Used

* Ansible
* AWS EC2
* AWS CLI
* Python
* boto3
* botocore
* WSL2 Ubuntu
* VS Code
* SSH
* Git and GitHub

---

# Task 1 — Create EC2 Instances Using Ansible Loops

The first goal was to create three EC2 instances:

```text
2 Ubuntu Instances
1 Amazon Linux Instance
```

---

## Step 1 — Install Python pip

Initially:

```bash
pip install boto3
```

failed because `pip` was not installed.

Installed pip:

```bash
sudo apt update
sudo apt install python3-pip
```

---

# Problem — sudo Password Was Forgotten

While installing packages, sudo authentication failed.

From Windows Command Prompt:

```powershell
wsl -u root
```

Then inside WSL:

```bash
passwd gaurang
```

After resetting the Linux user password:

```bash
exit
```

Then sudo commands started working normally.

---

# Problem — Externally Managed Python Environment

Running:

```bash
pip install boto3
```

returned:

```text
externally-managed-environment
```

Modern Ubuntu protects the system Python environment from direct pip modification.

Instead of using:

```bash
--break-system-packages
```

a Python virtual environment was created.

Install venv:

```bash
sudo apt install python3-venv -y
```

Create environment:

```bash
python3 -m venv ~/ansible-venv
```

Activate:

```bash
source ~/ansible-venv/bin/activate
```

Install AWS Python SDK dependencies:

```bash
pip install boto3 botocore
```

Verify boto3:

```bash
python -c "import boto3; print(boto3.__version__)"
```

---

# Why boto3?

`boto3` is the AWS SDK for Python.

The flow is:

```text
Ansible
   |
amazon.aws modules
   |
boto3 / botocore
   |
AWS API
   |
AWS Resources
```

Ansible AWS modules use the AWS SDK to communicate with AWS APIs.

---

# Step 2 — Verify Ansible

```bash
ansible --version
```

---

# Step 3 — Install AWS CLI

Initially:

```bash
sudo apt install awscli
```

failed because AWS CLI was unavailable from the configured Ubuntu repository.

AWS CLI v2 was installed using the official installer.

Download:

```bash
cd /tmp

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
-o "awscliv2.zip"
```

Install unzip:

```bash
sudo apt install unzip -y
```

Extract:

```bash
unzip awscliv2.zip
```

Install:

```bash
sudo ./aws/install
```

Verify:

```bash
aws --version
```

---

# Problem — Incomplete AWS CLI ZIP File

During the first download, `Ctrl+Z` accidentally stopped curl before the download completed.

Because the ZIP file was incomplete:

```bash
unzip awscliv2.zip
```

returned:

```text
End-of-central-directory signature not found
```

The incomplete file was removed:

```bash
rm -f /tmp/awscliv2.zip
```

Then the complete file was downloaded again.

---

# Step 4 — Configure AWS CLI

```bash
aws configure
```

Configured:

```text
AWS Access Key ID: ********
AWS Secret Access Key: ********
Default region: ap-south-1
Output format: json
```

Never store AWS credentials inside GitHub repositories.

Verify AWS authentication:

```bash
aws sts get-caller-identity
```

---

# Step 5 — Verify amazon.aws Collection

```bash
ansible-galaxy collection list | grep amazon.aws
```

If not available:

```bash
ansible-galaxy collection install amazon.aws
```

---

# Step 6 — Find AWS Resources

## Find Default Security Group

```bash
aws ec2 describe-security-groups \
  --region ap-south-1 \
  --query "SecurityGroups[?GroupName=='default'].[GroupId,VpcId,GroupName]" \
  --output table
```

---

## Find Default Subnets

```bash
aws ec2 describe-subnets \
  --region ap-south-1 \
  --filters Name=default-for-az,Values=true \
  --query "Subnets[*].[SubnetId,AvailabilityZone,VpcId]" \
  --output table
```

---

## Check Existing Key Pairs

```bash
aws ec2 describe-key-pairs \
  --region ap-south-1 \
  --query "KeyPairs[*].KeyName" \
  --output table
```

No key pair existed, so a new one was created.

```bash
aws ec2 create-key-pair \
  --key-name My_key_pair \
  --region ap-south-1 \
  --query "KeyMaterial" \
  --output text > My_key_pair.pem
```

The private key file must NEVER be committed to GitHub.

---

# Step 7 — Find Current Ubuntu AMI

AMI IDs are region-specific and can change over time.

Instead of blindly using an old AMI, the latest Ubuntu AMI was discovered using AWS CLI:

```bash
aws ec2 describe-images \
  --region ap-south-1 \
  --owners 099720109477 \
  --filters \
  "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
  "Name=state,Values=available" \
  --query "reverse(sort_by(Images,&CreationDate))[:3].[ImageId,Name,CreationDate]" \
  --output table
```

---

# Problem — InvalidAMIID.NotFound

The first playbook execution failed with:

```text
InvalidAMIID.NotFound
```

Reason:

The AMI IDs used in the playbook were outdated or unavailable in `ap-south-1`.

Solution:

Retrieve current AMI IDs from AWS instead of hardcoding old IDs.

---

# EC2 Creation Playbook

`create_ec2.yml`

```yaml
---
- name: Create 3 EC2 instances using Ansible
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    ansible_python_interpreter: /home/gaurang/ansible-venv/bin/python

    aws_region: ap-south-1
    instance_type: t3.micro

    key_name: My_key_pair
    security_group: YOUR_SECURITY_GROUP_ID
    subnet_id: YOUR_SUBNET_ID

  tasks:
    - name: Create EC2 instances
      amazon.aws.ec2_instance:
        name: "{{ item.name }}"
        region: "{{ aws_region }}"
        key_name: "{{ key_name }}"
        instance_type: "{{ instance_type }}"
        image_id: "{{ item.ami }}"
        security_group: "{{ security_group }}"
        vpc_subnet_id: "{{ subnet_id }}"

        network:
          assign_public_ip: true

        state: present
        wait: true

      loop:
        - name: ansible-ubuntu-1
          ami: YOUR_CURRENT_UBUNTU_AMI

        - name: ansible-ubuntu-2
          ami: YOUR_CURRENT_UBUNTU_AMI

        - name: ansible-aws-linux-3
          ami: YOUR_CURRENT_AMAZON_LINUX_AMI

      register: ec2_instances

    - name: Show created instances
      debug:
        msg: "Created instance: {{ item.item.name }}"
      loop: "{{ ec2_instances.results }}"
```

---

# Why `connection: local`?

Normally Ansible connects to target machines using SSH.

For EC2 provisioning there is no target server yet.

Therefore:

```yaml
hosts: localhost
connection: local
```

means:

```text
Ansible Controller
       |
       | Local Python execution
       |
       v
AWS API
       |
       v
Create EC2
```

---

# Why Loops?

Instead of writing three separate EC2 tasks:

```text
Create Ubuntu 1
Create Ubuntu 2
Create Amazon Linux
```

one task was repeated using:

```yaml
loop:
```

Each loop item contained its own instance name and AMI.

---

# Syntax Check

Before running the playbook:

```bash
ansible-playbook create_ec2.yml --syntax-check
```

Run:

```bash
ansible-playbook create_ec2.yml
```

---

# Problem — PendingVerification

Two Ubuntu instances were created successfully, but creation of the third instance initially failed with:

```text
PendingVerification
```

AWS was validating resource access for the region.

This was an AWS account-side issue, not an Ansible issue.

After AWS verification completed, the playbook was executed again and the third EC2 instance was created successfully.

---

# Task 2 — Configure SSH Authentication

After EC2 creation, Ansible needed SSH connectivity to the new servers.

The inventory was created:

`inventory.txt`

```ini
[Ubuntu]
UBUNTU_1_PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=/home/gaurang/.ssh/My_key_pair.pem
UBUNTU_2_PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=/home/gaurang/.ssh/My_key_pair.pem

[amazon_linux]
AMAZON_LINUX_PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=/home/gaurang/.ssh/My_key_pair.pem
```

Ubuntu default SSH user:

```text
ubuntu
```

Amazon Linux default SSH user:

```text
ec2-user
```

---

# Problem — Inventory File Not Parsed

The command initially used:

```bash
ansible all -i inventory -m ping
```

But the real filename was:

```text
inventory.txt
```

Correct command:

```bash
ansible all -i inventory.txt -m ping
```

---

# Problem — Invalid Inventory Group Name

Initially:

```ini
[amazon linux]
```

was used.

The space was removed:

```ini
[amazon_linux]
```

---

# Problem — SSH Port 22 Timeout

Ansible returned:

```text
connect to host ... port 22: Connection timed out
```

Reason:

SSH inbound traffic was not allowed in the EC2 Security Group.

An inbound rule was added:

```text
Protocol: TCP
Port: 22
Source: My IP
```

Because all three EC2 instances were attached to the same Security Group, changing the Security Group rule affected all three instances.

---

# Problem — Private Key Permissions

SSH returned:

```text
WARNING: UNPROTECTED PRIVATE KEY FILE!
Permissions 0555 are too open.
```

The `.pem` file was stored under:

```text
/mnt/c/Users/...
```

which is the Windows filesystem mounted inside WSL.

Linux permission handling on Windows-mounted files can behave differently.

The private key was copied to the native WSL filesystem:

```bash
mkdir -p ~/.ssh
cp My_key_pair.pem ~/.ssh/My_key_pair.pem
chmod 400 ~/.ssh/My_key_pair.pem
```

Verify:

```bash
ls -l ~/.ssh/My_key_pair.pem
```

Expected permission:

```text
-r--------
```

Manual SSH test:

```bash
ssh -i ~/.ssh/My_key_pair.pem ubuntu@UBUNTU_PUBLIC_IP
```

---

# Ansible Connectivity Test

```bash
ansible all -i inventory.txt -m ping
```

Successful result:

```text
ping: pong
```

This confirmed passwordless SSH key-based authentication.

---

# Task 3 — Shutdown Only Ubuntu Servers

First OS facts were checked:

```bash
ansible all \
  -i inventory.txt \
  -m setup \
  -a "filter=ansible_distribution"
```

Ansible discovered:

```text
Ubuntu Instance 1 → Ubuntu
Ubuntu Instance 2 → Ubuntu
Amazon Linux      → Amazon
```

---

# Shutdown Playbook

`shutdown.yml`

```yaml
---
- name: Shutdown Ubuntu instances only
  hosts: all
  become: true
  gather_facts: true

  tasks:
    - name: Shutdown Ubuntu server
      community.general.shutdown:
      when: ansible_facts['distribution'] == "Ubuntu"
```

The important condition is:

```yaml
when: ansible_facts['distribution'] == "Ubuntu"
```

Flow:

```text
Ubuntu
   |
condition = true
   |
Shutdown

Ubuntu
   |
condition = true
   |
Shutdown

Amazon Linux
   |
condition = false
   |
Skipped
```

---

# Syntax Check

```bash
ansible-playbook -i inventory.txt shutdown.yml --syntax-check
```

Run:

```bash
ansible-playbook -i inventory.txt shutdown.yml
```

Result:

```text
Ubuntu 1     → Shutdown
Ubuntu 2     → Shutdown
Amazon Linux → Skipped
```

---

# Important Ansible Concepts Used

## Inventory

Defines the servers managed by Ansible.

## Modules

Used modules such as:

```text
setup
ping
amazon.aws.ec2_instance
community.general.shutdown
```

## Variables

Values such as region, instance type, key name and subnet were stored in variables.

## Loops

Used to create multiple EC2 instances using one task.

## Facts

Ansible automatically gathered operating system information from target servers.

## Conditionals

The `when` condition was used to perform shutdown only when the operating system was Ubuntu.

## Provisioning

Creating infrastructure resources such as EC2 instances is called provisioning.

## Configuration Management

Managing software, files, services and configuration on existing servers is configuration management.

---

# Major Troubleshooting Lessons

During this project the following real-world issues were solved:

```text
pip missing
↓
Installed python3-pip

Forgotten sudo password
↓
Reset WSL Linux password using root

externally-managed-environment
↓
Created Python virtual environment

AWS CLI package unavailable
↓
Installed AWS CLI v2 manually

AWS CLI ZIP incomplete
↓
Redownloaded complete installer

AWS authentication
↓
Configured AWS CLI

Old AMI IDs
↓
Queried current AMIs through AWS CLI

Pending AWS verification
↓
Waited for account-side verification

Inventory parsing failure
↓
Corrected inventory filename and group syntax

SSH timeout on port 22
↓
Added Security Group SSH rule

PEM permissions too open
↓
Moved key from /mnt/c to ~/.ssh and used chmod 400

Unknown host fingerprint
↓
Accepted first SSH connection

Conditional execution
↓
Used gathered facts to shut down Ubuntu only
```

---

# Key Learning

The biggest lesson from this project was not memorizing commands.

The important skill was learning how to read an error, identify which layer was failing, and troubleshoot systematically.

```text
Ansible
   ↓
Python / boto3
   ↓
AWS Authentication
   ↓
AWS API
   ↓
Networking
   ↓
SSH
   ↓
Operating System
```

Understanding where the failure occurs makes DevOps troubleshooting much easier.

---

# Security Notes

Never commit the following to GitHub:

```text
AWS Access Keys
AWS Secret Keys
.pem private keys
Passwords
Tokens
Vault passwords
.env files containing secrets
```

The `.gitignore` file should include:

```gitignore
*.pem
*.key
.env
ansible-venv/
__pycache__/
*.retry
```

---

# Project Outcome

Successfully automated:

* Creation of three AWS EC2 instances using Ansible.
* Multi-instance provisioning using loops.
* SSH key-based authentication.
* Inventory management.
* AWS Security Group troubleshooting.
* OS detection using Ansible facts.
* Ubuntu-only shutdown using conditionals.

This project demonstrates the integration of **Ansible, AWS, Python SDKs, SSH and Linux** for infrastructure automation.
