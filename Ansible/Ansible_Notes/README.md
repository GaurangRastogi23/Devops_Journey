# Ansible A-to-Z Notes

These notes document my Ansible learning journey from basic concepts to AWS automation and a real-time project.

---

# 1. What is Ansible?

Ansible is an open-source automation and configuration management tool.

It can be used for:

- Configuration Management
- Application Deployment
- Server Automation
- Orchestration
- Provisioning cloud resources
- Package installation
- Service management
- File management

Ansible is mainly written in Python.

---

# 2. Why Ansible?

Suppose we have 100 servers and need to install Nginx.

Without automation:

```text
SSH Server 1 → Install Nginx
SSH Server 2 → Install Nginx
SSH Server 3 → Install Nginx
...
SSH Server 100 → Install Nginx
```

With Ansible:

```text
                 Ansible Control Node
                         |
             -------------------------
             |           |           |
          Server 1    Server 2    Server 3
```

One command/playbook can configure multiple servers.

---

# 3. Ansible Architecture

```text
Control Node
    |
    | SSH
    |
    +------ Managed Node 1
    +------ Managed Node 2
    +------ Managed Node 3
```

## Control Node

Machine where Ansible is installed and commands/playbooks are executed.

## Managed Nodes

Servers managed by Ansible.

## Important Feature

Ansible is **agentless**.

We normally don't need to install an Ansible agent on every target server.

For Linux servers, Ansible generally communicates using SSH.

---

# 4. Ansible Installation

Check installation:

```bash
ansible --version
```

---

# 5. Inventory

Inventory tells Ansible which machines it manages.

Example:

```ini
[webservers]
192.168.1.10
192.168.1.11

[dbservers]
192.168.1.20
```

With SSH details:

```ini
[ubuntu]
PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=/home/user/.ssh/key.pem

[amazon_linux]
PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=/home/user/.ssh/key.pem
```

Check inventory:

```bash
ansible-inventory -i inventory --list
```

---

# 6. Test Ansible Connectivity

```bash
ansible all -i inventory -m ping
```

Expected:

```text
SUCCESS
ping: pong
```

Important:

Ansible `ping` is NOT the same as network ICMP ping.

It verifies that Ansible can connect to the target and execute Python.

---

# 7. Ad-Hoc Commands

Ad-hoc commands are one-line Ansible commands used for quick tasks.

General syntax:

```bash
ansible <hosts> -i <inventory> -m <module> -a "<arguments>"
```

Example:

```bash
ansible all -i inventory -m ping
```

Run shell command:

```bash
ansible all -i inventory -m shell -a "uptime"
```

Check disk:

```bash
ansible all -i inventory -m command -a "df -h"
```

Copy file:

```bash
ansible all -i inventory -m copy -a "src=test.txt dest=/tmp/test.txt"
```

Install package:

```bash
ansible all -i inventory -b -m apt -a "name=nginx state=present update_cache=yes"
```

---

# 8. Ansible Modules

Modules perform actual operations on managed nodes.

Examples:

```text
ping
command
shell
copy
file
apt
yum/dnf
service
user
setup
template
debug
```

Example:

```yaml
ansible.builtin.apt:
  name: nginx
  state: present
```

Important concept:

```text
Playbook
   ↓
Task
   ↓
Module
   ↓
Action on target server
```

---

# 9. command vs shell

## command

```yaml
ansible.builtin.command: ls -l
```

Does not use a shell.

Shell-specific features such as:

```text
|
>
>>
&&
```

generally require the `shell` module.

## shell

```yaml
ansible.builtin.shell: "cat /var/log/syslog | grep error"
```

Use `command` when shell features aren't required.

---

# 10. YAML Basics

Ansible playbooks are written in YAML.

Important:

- Indentation matters.
- Use spaces, not tabs.
- Lists start with `-`.
- Key/value syntax uses `:`.

Example:

```yaml
---
- name: Example play
  hosts: all

  tasks:
    - name: Print message
      debug:
        msg: "Hello Ansible"
```

---

# 11. Playbooks

Playbooks contain automation instructions.

Example:

```yaml
---
- name: Install and start Nginx
  hosts: all
  become: true

  tasks:
    - name: Update apt cache
      apt:
        update_cache: true

    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: true
```

Run:

```bash
ansible-playbook -i inventory playbook.yml
```

Syntax check:

```bash
ansible-playbook -i inventory playbook.yml --syntax-check
```

---

# 12. become

`become` is used for privilege escalation.

Correct:

```yaml
become: true
```

Incorrect:

```yaml
become: root
```

If a specific user is required:

```yaml
become: true
become_user: root
```

Conceptually similar to using `sudo`.

---

# 13. Tasks

Tasks define individual actions inside a play.

```yaml
tasks:
  - name: Install nginx
    apt:
      name: nginx
      state: present

  - name: Start nginx
    service:
      name: nginx
      state: started
```

Tasks execute from top to bottom.

---

# 14. Variables

Variables prevent repeated hardcoding.

Example:

```yaml
vars:
  package_name: nginx
```

Use:

```yaml
tasks:
  - name: Install package
    apt:
      name: "{{ package_name }}"
      state: present
```

Jinja expression:

```text
{{ variable_name }}
```

---

# 15. Inventory Variables

Variables can also be defined in inventory.

Example:

```ini
[webservers]
192.168.1.10 package_name=nginx
```

Then:

```yaml
name: "{{ package_name }}"
```

---

# 16. Facts

Facts are information Ansible gathers from managed nodes.

Examples:

- OS distribution
- IP addresses
- Hostname
- Architecture
- Memory
- CPU information

View facts:

```bash
ansible all -i inventory -m setup
```

Filter facts:

```bash
ansible all -i inventory -m setup -a "filter=ansible_distribution"
```

Modern syntax:

```yaml
ansible_facts['distribution']
```

Example:

```yaml
debug:
  msg: "{{ ansible_facts['distribution'] }}"
```

---

# 17. gather_facts

By default:

```yaml
gather_facts: true
```

If facts aren't needed:

```yaml
gather_facts: false
```

This can make a play faster.

---

# 18. Conditionals

Conditionals execute tasks only when a condition is true.

Keyword:

```yaml
when:
```

Example:

```yaml
- name: Install nginx only on Ubuntu
  apt:
    name: nginx
    state: present
  when: ansible_facts['distribution'] == "Ubuntu"
```

Logic:

```text
Ubuntu?
  |
 YES → execute
 NO  → skip
```

---

# 19. Loops

Loops repeat the same task for multiple items.

Example:

```yaml
- name: Install packages
  apt:
    name: "{{ item }}"
    state: present

  loop:
    - nginx
    - curl
    - git
```

Ansible executes:

```text
item = nginx
item = curl
item = git
```

---

# 20. Loop with Variables

```yaml
vars:
  packages:
    - nginx
    - curl
    - git

tasks:
  - name: Install packages
    apt:
      name: "{{ item }}"
      state: present
    loop: "{{ packages }}"
```

---

# 21. Loop with Dictionaries

Useful when each item has multiple values.

```yaml
loop:
  - name: server1
    ami: ami-xxxx

  - name: server2
    ami: ami-yyyy
```

Access:

```yaml
name: "{{ item.name }}"
image_id: "{{ item.ami }}"
```

This was used in the AWS EC2 project.

---

# 22. Handlers

Handlers execute only when notified by another changed task.

Example:

```yaml
tasks:
  - name: Copy nginx config
    copy:
      src: nginx.conf
      dest: /etc/nginx/nginx.conf
    notify: Restart nginx

handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted
```

Flow:

```text
Configuration changed
       ↓
notify
       ↓
Handler
       ↓
Restart nginx
```

If the task doesn't report a change, the handler normally doesn't run.

---

# 23. Templates — Jinja2

Templates allow dynamic configuration files.

Template:

```text
app.conf.j2
```

Example:

```jinja2
Application={{ app_name }}
Environment={{ app_environment }}
Port={{ app_port }}
Hostname={{ ansible_facts['hostname'] }}
```

Playbook:

```yaml
vars:
  app_name: payment-service
  app_environment: production
  app_port: 8080

tasks:
  - name: Generate application configuration
    template:
      src: app.conf.j2
      dest: /etc/app.conf
```

One template can therefore generate different configuration for different environments.

Example:

```text
Development → port 8080
Testing     → port 8081
Production  → port 80
```

---

# 24. Roles

Roles organize large Ansible projects into reusable structures.

Create role:

```bash
ansible-galaxy init nginx
```

Structure:

```text
nginx/
├── defaults/
├── files/
├── handlers/
├── meta/
├── tasks/
├── templates/
├── tests/
└── vars/
```

Main tasks:

```text
roles/nginx/tasks/main.yml
```

Handlers:

```text
roles/nginx/handlers/main.yml
```

Templates:

```text
roles/nginx/templates/
```

---

# 25. Using a Role

```yaml
---
- name: Configure web server
  hosts: all
  become: true

  roles:
    - nginx
```

---

# 26. defaults vs vars in Roles

Both can store variables.

## defaults

```text
roles/nginx/defaults/main.yml
```

Lowest precedence.

Best for values users are expected to override.

Example:

```yaml
nginx_port: 80
```

## vars

```text
roles/nginx/vars/main.yml
```

Higher precedence.

Use for values that generally should not be easily overridden.

Simple rule:

```text
defaults → customizable values
vars     → stronger role-specific values
```

---

# 27. Ansible Vault

Vault protects sensitive Ansible data.

Examples:

- passwords
- API secrets
- tokens
- database credentials

Create encrypted file:

```bash
ansible-vault create secrets.yml
```

View:

```bash
ansible-vault view secrets.yml
```

Edit:

```bash
ansible-vault edit secrets.yml
```

Encrypt existing file:

```bash
ansible-vault encrypt secrets.yml
```

Decrypt:

```bash
ansible-vault decrypt secrets.yml
```

Run playbook with Vault:

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

Important:

Vault encrypts secrets stored in Ansible files. It doesn't mean every credential should automatically be stored in a Vault file; cloud-native credential mechanisms/IAM roles are often preferable for AWS authentication.

---

# 28. Ansible Galaxy

Ansible Galaxy provides reusable collections and roles.

Search/install collections:

```bash
ansible-galaxy collection install amazon.aws
```

List:

```bash
ansible-galaxy collection list
```

Example AWS collection:

```text
amazon.aws
```

Example module:

```yaml
amazon.aws.ec2_instance:
```

---

# 29. Collections

Collections package:

- modules
- plugins
- roles
- documentation

Fully Qualified Collection Name example:

```yaml
ansible.builtin.copy:
```

AWS:

```yaml
amazon.aws.ec2_instance:
```

Community:

```yaml
community.general.shutdown:
```

---

# 30. register

`register` stores a task's result in a variable.

Example:

```yaml
- name: Check uptime
  command: uptime
  register: uptime_result

- name: Print result
  debug:
    var: uptime_result
```

Specific output:

```yaml
debug:
  msg: "{{ uptime_result.stdout }}"
```

---

# 31. debug

Used to print information while executing a playbook.

```yaml
- name: Print message
  debug:
    msg: "Nginx installed"
```

Variable:

```yaml
debug:
  var: variable_name
```

Useful for troubleshooting.

---

# 32. Idempotency

One of the most important Ansible concepts.

> Running the same playbook multiple times should produce the same desired state without unnecessarily repeating changes.

First run:

```text
changed
```

Second run:

```text
ok
```

Example:

```yaml
apt:
  name: nginx
  state: present
```

If Nginx is already installed, Ansible normally doesn't install it again.

---

# 33. state

Many Ansible modules use `state`.

Examples:

```yaml
state: present
state: absent
state: started
state: stopped
state: restarted
```

Examples:

```yaml
apt:
  name: nginx
  state: present
```

```yaml
service:
  name: nginx
  state: started
```

---

# 34. Provisioning vs Configuration Management

## Provisioning

Creating infrastructure.

Examples:

```text
Create EC2
Create VPC
Create subnet
Create load balancer
```

## Configuration Management

Configuring infrastructure after it exists.

Examples:

```text
Install Nginx
Create users
Deploy config files
Start services
Install application
```

Ansible can do both, but configuration management is one of its major strengths.

Terraform is primarily designed for Infrastructure as Code/provisioning.

---

# 35. AWS Automation with Ansible

Flow:

```text
Ansible Playbook
       ↓
amazon.aws module
       ↓
boto3 / botocore
       ↓
AWS API
       ↓
AWS Resource
```

---

# 36. boto3

Boto3 is the AWS SDK for Python.

Install inside a virtual environment:

```bash
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate

pip install boto3 botocore
```

Verify:

```bash
python -c "import boto3; print(boto3.__version__)"
```

---

# 37. AWS CLI Setup

Verify:

```bash
aws --version
```

Configure:

```bash
aws configure
```

Verify identity:

```bash
aws sts get-caller-identity
```

Never commit:

```text
Access Key
Secret Access Key
Session Token
```

---

# 38. connection: local

Normally Ansible connects to remote machines.

But while creating EC2 instances:

```yaml
hosts: localhost
connection: local
```

means execute the module on the Ansible controller.

Flow:

```text
Ansible Controller
       ↓
AWS Python SDK
       ↓
AWS API
       ↓
Create EC2
```

There is no EC2 to SSH into before it has been created.

---

# 39. EC2 Provisioning Using Loop

Example:

```yaml
- name: Create EC2 instances
  amazon.aws.ec2_instance:
    name: "{{ item.name }}"
    region: "{{ aws_region }}"
    instance_type: t3.micro
    image_id: "{{ item.ami }}"
    state: present

  loop:
    - name: ubuntu-1
      ami: UBUNTU_AMI

    - name: ubuntu-2
      ami: UBUNTU_AMI

    - name: amazon-linux
      ami: AMAZON_LINUX_AMI
```

---

# 40. Finding AWS Resources

These commands don't need to be memorized.

Understand what information is required and use documentation/CLI help when necessary.

## Security Groups

```bash
aws ec2 describe-security-groups
```

## Subnets

```bash
aws ec2 describe-subnets
```

## Key Pairs

```bash
aws ec2 describe-key-pairs
```

## AMIs

```bash
aws ec2 describe-images
```

Concept matters more than memorizing long `--query` and `--filter` expressions.

---

# 41. SSH Authentication

EC2 commonly uses SSH key-based authentication.

Ubuntu:

```bash
ssh -i key.pem ubuntu@PUBLIC_IP
```

Amazon Linux:

```bash
ssh -i key.pem ec2-user@PUBLIC_IP
```

---

# 42. Private Key Permissions

Private SSH keys must have restrictive permissions.

```bash
chmod 400 ~/.ssh/My_key_pair.pem
```

If permissions are too open:

```text
WARNING: UNPROTECTED PRIVATE KEY FILE
```

SSH can refuse to use the key.

---

# 43. WSL and PEM Permission Issue

A key stored under:

```text
/mnt/c/Users/...
```

is on the Windows-mounted filesystem.

Linux permissions may not behave exactly as expected.

Better:

```bash
mkdir -p ~/.ssh
cp My_key_pair.pem ~/.ssh/
chmod 400 ~/.ssh/My_key_pair.pem
```

Then use:

```text
/home/USER/.ssh/My_key_pair.pem
```

---

# 44. Security Groups and SSH

SSH requires:

```text
Protocol: TCP
Port: 22
Source: My IP
```

If multiple EC2 instances use the same Security Group, modifying that SG affects every attached instance.

```text
Security Group
     |
     +---- EC2-1
     +---- EC2-2
     +---- EC2-3
```

---

# 45. Useful SSH Errors

## Connection timed out

```text
ssh: connect to host ... port 22: Connection timed out
```

Investigate:

- Security Group
- NACL
- Routing
- Public IP
- Firewall
- Network connectivity

## Permission denied

```text
Permission denied (publickey)
```

Investigate:

- Wrong SSH user
- Wrong private key
- Key permissions
- Key pair mismatch

## Connection refused

Host is reachable, but the target port/service isn't accepting the connection.

---

# 46. Host Key Verification

First SSH connection may show:

```text
The authenticity of host cannot be established.
Are you sure you want to continue connecting?
```

After verification and accepting the host key, SSH stores it in:

```text
~/.ssh/known_hosts
```

---

# 47. Conditional Shutdown Project

Goal:

```text
Ubuntu-1      → Shutdown
Ubuntu-2      → Shutdown
Amazon Linux  → Skip
```

Facts:

```bash
ansible all -i inventory.txt -m setup -a "filter=ansible_distribution"
```

Playbook:

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

Logic:

```text
Gather facts
     ↓
Check distribution
     ↓
Is Ubuntu?
   /     \
 YES      NO
  ↓        ↓
Shutdown  Skip
```

---

# 48. Important Troubleshooting Commands

Check playbook syntax:

```bash
ansible-playbook playbook.yml --syntax-check
```

Verbose:

```bash
ansible-playbook playbook.yml -v
```

More detail:

```bash
ansible-playbook playbook.yml -vvv
```

Check inventory:

```bash
ansible-inventory -i inventory --list
```

Connectivity:

```bash
ansible all -i inventory -m ping
```

Facts:

```bash
ansible all -i inventory -m setup
```

Check running process:

```bash
ps -ef
```

Specific PID:

```bash
ps -p PID -f
```

---

# 49. apt Lock Issue Encountered

An Ansible apt task became stuck and another apt operation reported a lock.

The process was identified using:

```bash
ps -p PID -f
```

This showed an Ansible Python apt process.

Important lesson:

Do NOT blindly delete apt lock files.

First determine which process owns the lock.

---

# 50. apt 404 Error Encountered

Nginx installation returned package download `404 Not Found`.

Reason:

Local apt package metadata referenced package versions no longer available on the mirror.

Solution:

```bash
sudo apt update
```

Then run the playbook again.

Ansible version:

```yaml
- name: Update apt cache
  apt:
    update_cache: true
```

---

# 51. Common YAML Errors Encountered

## Missing `-`

Wrong task list structure can cause:

```text
did not find expected '-' indicator
```

Correct:

```yaml
tasks:
  - name: Install nginx
```

## Wrong `hosts`

Wrong:

```yaml
host: all
```

Correct:

```yaml
hosts: all
```

## Wrong become value

Wrong:

```yaml
become: root
```

Correct:

```yaml
become: true
```

---

# 52. Handler Error Encountered

Example:

```text
Could not find requested service ngnix
```

Cause:

Typo:

```text
ngnix
```

Correct service:

```text
nginx
```

Also, the name used by `notify` must match the intended handler/listener.

---

# 53. Loop Error Encountered

Wrong keyword:

```yaml
loops:
```

Correct:

```yaml
loop:
```

A malformed task can cause errors such as:

```text
conflicting action statements
```

---

# 54. Template Variable Warning

Avoid using reserved/special variable names where possible.

Instead of generic names like:

```yaml
environment:
port:
```

prefer:

```yaml
app_environment:
app_port:
```

This makes variables clearer and avoids collisions.

---

# 55. Role Structure

Example:

```text
roles/
└── nginx/
    ├── defaults/
    │   └── main.yml
    ├── files/
    ├── handlers/
    │   └── main.yml
    ├── meta/
    │   └── main.yml
    ├── tasks/
    │   └── main.yml
    ├── templates/
    ├── tests/
    └── vars/
        └── main.yml
```

Roles make automation:

- reusable
- maintainable
- organized
- easier to share

---

# 56. Useful Ansible Commands

Version:

```bash
ansible --version
```

Ping:

```bash
ansible all -i inventory -m ping
```

Playbook:

```bash
ansible-playbook -i inventory playbook.yml
```

Syntax:

```bash
ansible-playbook -i inventory playbook.yml --syntax-check
```

Inventory:

```bash
ansible-inventory -i inventory --list
```

Facts:

```bash
ansible all -i inventory -m setup
```

Collections:

```bash
ansible-galaxy collection list
```

Create role:

```bash
ansible-galaxy init ROLE_NAME
```

Vault:

```bash
ansible-vault create secrets.yml
ansible-vault view secrets.yml
ansible-vault edit secrets.yml
```

---

# 57. What Should I Memorize?

Do NOT try to memorize every command.

Remember the concepts:

```text
Inventory → Which servers?

Ad-hoc → Quick one-time automation

Module → What action?

Playbook → Automation instructions

Task → Individual operation

Variable → Reusable value

Fact → Information about target

Handler → Run after notified change

Conditional → Run based on condition

Loop → Repeat task

Template → Dynamic configuration

Role → Reusable project structure

Vault → Protect sensitive Ansible data

Galaxy → Reusable Ansible content

Provisioning → Create infrastructure

Configuration Management → Configure infrastructure
```

For complicated syntax, use documentation.

---

# 58. Interview Questions

## What is Ansible?

An agentless automation and configuration management tool used to automate infrastructure and server configuration.

## Is Ansible agentless?

Yes. Linux managed nodes generally don't require a dedicated Ansible agent; SSH is commonly used.

## What is inventory?

A file/source defining managed hosts and groups.

## What is a playbook?

A YAML file describing automation tasks to execute against hosts.

## What is a module?

Reusable code that performs a particular operation such as installing a package or copying a file.

## What is idempotency?

Repeated execution should maintain the desired state without unnecessary changes.

## What is a handler?

A special task triggered through `notify`, commonly used for operations such as service restart after configuration changes.

## What are facts?

Information gathered by Ansible about managed nodes.

## What is `when`?

A conditional statement controlling whether a task executes.

## What is Ansible Vault?

A feature used to encrypt sensitive Ansible data.

## What are roles?

A standard structure for organizing reusable Ansible automation.

## What is Ansible Galaxy?

An ecosystem/tool for discovering, installing and sharing Ansible roles and collections.

## Terraform vs Ansible?

```text
Terraform
→ Primarily infrastructure provisioning / Infrastructure as Code

Ansible
→ Primarily configuration management and automation
```

They are often used together.

---

# 59. Terraform + Ansible

Typical real-world flow:

```text
Terraform
    ↓
Create VPC
Create Subnets
Create Security Groups
Create EC2
Create Load Balancer
    ↓
Infrastructure Ready
    ↓
Ansible
    ↓
Install packages
Configure Nginx
Deploy application
Configure services
```

Terraform creates infrastructure.

Ansible configures it.

---

# 60. Final Learning Path Completed

```text
Inventory            ✅
Ad-hoc Commands      ✅
Modules              ✅
Variables            ✅
Facts                ✅
Playbooks            ✅
Tasks                ✅
Handlers             ✅
Conditionals         ✅
Loops                ✅
Templates / Jinja2   ✅
Roles                ✅
Vault                ✅
Ansible Galaxy       ✅
AWS Provisioning     ✅
SSH Authentication   ✅
Real-time Project    ✅
Troubleshooting      ✅
```

---

# Final Takeaway

Ansible is not about memorizing YAML or commands.

The important skills are:

1. Understand the desired state.
2. Select the correct module.
3. Write readable and reusable automation.
4. Understand inventory and SSH connectivity.
5. Use variables instead of excessive hardcoding.
6. Use facts and conditionals for dynamic automation.
7. Use roles to organize larger projects.
8. Protect sensitive information.
9. Read error messages carefully.
10. Troubleshoot layer by layer.

```text
Ansible
   ↓
SSH / Local Execution
   ↓
Python / Modules
   ↓
Operating System or Cloud API
   ↓
Desired State
```

The goal is not:

> "I remember every Ansible command."

The goal is:

> "I understand what needs to be automated, which Ansible concept/module can solve it, and how to troubleshoot it when it fails."