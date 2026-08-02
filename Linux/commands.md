# 🐧 Linux Commands

This document contains the basic Linux commands every DevOps Engineer should know.

---

# 1. pwd (Print Working Directory)

### Purpose
Displays the current working directory.

### Syntax
```bash
pwd
```

### Example
```bash
pwd
```

### Real DevOps Use Case
Used to verify the current directory before executing scripts.

---

# 2. ls (List Files and Directories)

### Purpose
Lists files and directories.

### Syntax
```bash
ls
ls -l
ls -la
```

### Example
```bash
ls -la
```

### Real DevOps Use Case
Used to verify deployment files and application directories.

---

# 3. cd (Change Directory)

### Purpose
Navigate between directories.

### Syntax
```bash
cd folder_name
cd ..
cd ~
```

### Example
```bash
cd /var/log
```

### Real DevOps Use Case
Used to navigate to application or log directories.

---

# 4. mkdir (Make Directory)

### Purpose
Creates a new directory.

### Syntax
```bash
mkdir directory_name
```

### Example
```bash
mkdir DevOps
```

### Real DevOps Use Case
Used to organize project files and logs.

---

# 5. touch

### Purpose
Creates an empty file.

### Syntax
```bash
touch filename
```

### Example
```bash
touch notes.txt
```

### Real DevOps Use Case
Used to create configuration or log files.

---

# 6. vim

### Purpose
Create or edit files.

### Syntax
```bash
vim filename
```

### Example
```bash
vim script.sh
```

### Real DevOps Use Case
Used to edit configuration files directly on Linux servers.

---

# 7. cp (Copy)

### Purpose
Copies files or directories.

### Syntax
```bash
cp source destination
```

### Example
```bash
cp file1.txt backup.txt
```

### Real DevOps Use Case
Used to create backups before modifying configuration files.

---

# 8. mv (Move)

### Purpose
Moves or renames files.

### Syntax
```bash
mv old_file new_file
```

### Example
```bash
mv app.log app_old.log
```

### Real DevOps Use Case
Used to rename log or configuration files.

---

# 9. rm (Remove)

### Purpose
Deletes files or directories.

### Syntax
```bash
rm filename
rm -r folder
```

### Example
```bash
rm test.txt
```

### Real DevOps Use Case
Used to remove temporary files and unused directories.

---

# 10. chmod

### Purpose
Changes file permissions.

### Syntax
```bash
chmod +x script.sh
chmod 755 script.sh
```

### Example
```bash
chmod +x deploy.sh
```

### Real DevOps Use Case
Makes shell scripts executable before running automation.

---

# 11. history

### Purpose
Shows previously executed commands.

### Syntax
```bash
history
```

### Example
```bash
history
```

### Real DevOps Use Case
Used to review previously executed commands while troubleshooting.

---

# 12. man

### Purpose
Displays the manual page of a command.

### Syntax
```bash
man command_name
```

### Example
```bash
man ls
```

### Real DevOps Use Case
Used to quickly understand command options on production servers.

---

# 13. top

### Purpose
Displays CPU, RAM and running processes.

### Syntax
```bash
top
```

### Example
```bash
top
```

### Real DevOps Use Case
Used to identify high CPU or memory usage during incidents.

---

# 14. ps

### Purpose
Displays running processes.

### Syntax
```bash
ps -ef
```

### Example
```bash
ps -ef
```

### Real DevOps Use Case
Used to verify whether an application or service is running.

---

# 15. grep

### Purpose
Searches for text inside files.

### Syntax
```bash
grep "text" filename
```

### Example
```bash
grep ERROR app.log
```

### Real DevOps Use Case
Used to search for errors in application log files.

---

# 16. find

### Purpose
Searches for files and directories.

### Syntax
```bash
find path -name filename
```

### Example
```bash
find . -name "*.log"
```

### Real DevOps Use Case
Used to locate log files, configuration files and scripts.

---

# 17. echo

### Purpose
Prints text or variable values.

### Syntax
```bash
echo "Hello World"
```

### Example
```bash
echo $HOME
```

### Real DevOps Use Case
Used for logging messages and debugging shell scripts.

---

# 18. cat

### Purpose
Displays file contents.

### Syntax
```bash
cat filename
```

### Example
```bash
cat app.log
```

### Real DevOps Use Case
Used to quickly read configuration and log files.

---

# 19. clear

### Purpose
Clears the terminal screen.

### Syntax
```bash
clear
```

### Real DevOps Use Case
Keeps the terminal clean while working.

---

# 20. whoami

### Purpose
Displays the current logged-in user.

### Syntax
```bash
whoami
```

### Example
```bash
whoami
```

### Real DevOps Use Case
Used to verify the current user before executing administrative commands.

---

## Summary

These commands are the foundation of Linux and are used daily by DevOps Engineers for:

- File Management
- Server Administration
- Process Monitoring
- Troubleshooting
- Automation
- Deployment
- Log Analysis
