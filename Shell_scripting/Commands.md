
# 🐚 Shell Scripting Commands

---

# 1. Shebang

### Purpose

Specifies which interpreter should execute the script.

### Syntax

```bash
#!/bin/bash
```

### Real DevOps Use Case

Ensures the script always runs using Bash.

---

# 2. Execute Script

```bash
bash script.sh
```

or

```bash
./script.sh
```

---

# 3. chmod

### Purpose

Makes a script executable.

```bash
chmod +x script.sh
```

---

# 4. echo

### Purpose

Prints text or variables.

```bash
echo "Hello DevOps"
```

```bash
echo $HOME
```

---

# 5. Variables

```bash
NAME="Gaurang"

echo $NAME
```

---

# 6. Read User Input

```bash
read NAME

echo $NAME
```

---

# 7. if else

```bash
if [ $AGE -ge 18 ]
then
    echo "Eligible"
else
    echo "Not Eligible"
fi
```

### Real DevOps Use Case

Check if a service is running before restarting it.

---

# 8. for loop

```bash
for i in {1..5}
do
    echo $i
done
```

### Real DevOps Use Case

Deploy applications to multiple servers.

---

# 9. ps

```bash
ps -ef
```

Purpose

Displays running processes.

---

# 10. grep

```bash
grep ERROR app.log
```

Purpose

Searches text inside files.

---

# 11. Pipe

```bash
ps -ef | grep nginx
```

Purpose

Passes output of one command as input to another.

---

# 12. awk

```bash
awk '{print $1}'
```

Purpose

Processes and formats text.

---

# 13. find

```bash
find . -name "*.log"
```

Purpose

Find files.

---

# 14. top

```bash
top
```

Purpose

Monitor CPU and Memory.

---

# 15. history

```bash
history
```

Purpose

Shows previously executed commands.

---

# 16. set -x

```bash
set -x
```

Purpose

Runs script in debug mode.

---

# 17. set -e

```bash
set -e
```

Purpose

Stops script immediately if a command fails.

---

# 18. set -o pipefail

```bash
set -o pipefail
```

Purpose

Returns failure if any command in a pipeline fails.

---

# 19. curl

```bash
curl https://example.com
```

Purpose

Transfers data from or to a server.

### Real DevOps Use Case

Check API health or application endpoint.

---

# 20. wget

```bash
wget https://example.com/file.zip
```

Purpose

Downloads files from the internet.

---

# 21. sudo

```bash
sudo apt update
```

Purpose

Execute commands with administrative privileges.

---

# 22. su

```bash
su
```

Purpose

Switch to another user.

---

# 23. crontab

```bash
crontab -e
```

Purpose

Schedules tasks to run automatically.

### Example

Run backup every day at midnight.

```text
0 0 * * * /home/user/backup.sh
```

---

# 24. Debug a Script

```bash
bash -x script.sh
```

Purpose

Runs a shell script in debug mode.

---

# Summary

Shell Scripting is widely used in DevOps for:

- Infrastructure Automation
- Server Monitoring
- Log Analysis
- CI/CD Pipelines
- Backup Automation
- Deployment Automation
- Cloud Resource Management
