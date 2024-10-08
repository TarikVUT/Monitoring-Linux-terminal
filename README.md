> [!WARNING]
> This script is tailored for Fedora 40. It operates under root permissions. If you lack extensive Linux expertise, refrain from altering its contents. Take the time to thoroughly understand the script's functionality before deciding whether to execute it.


# Monitoring-Linux-terminal
![](https://github.com/TarikVUT/Monitoring-Linux-terminal/blob/main/images/UDP-rsyslog.png)




## **Introduction**

This project provides a comprehensive solution for monitoring and logging terminal input on Linux systems. It demonstrates how to collect and send user input from a client machine to a remote server for centralized logging and auditing. The solution leverages various tools, such as rsyslog, auditd, and rsync, offering multiple approaches depending on your needs. This setup is useful for system administrators who want to track user activities on terminals for security, auditing, or compliance purposes.

--------------------------------------------

## **Features**

 . Collect terminal input using rsyslog, auditd, or shell history.
 
 . Automatically send the collected logs to a remote server for centralized storage and analysis.
 
 . Flexible setup options for different environments and security requirements.

--------------------------------------------

## Methods of Collection

1. [**Configuring rsyslog to Collect User Input and Send it to a Remote Server**](#rsyslog-rsyslog)
2. [**Collecting User Input Using auditd and Sending Logs to a Remote Server via rsyslog**](#audit-rsyslog)
3. [**Collecting User Input Using auditd and Sending Logs Directly via Audit**](#audit-audit)
4. [**Using a Script to Collect History Data and Send it to a Remote Server via rsync**](#code-rsync)

--------------------------------------------

## 1. Configuring rsyslog to Collect User Input and Send it to a Remote Server
<a name="rsyslog-rsyslog"></a>
This method uses rsyslog to capture and forward terminal input.
<img src="https://github.com/TarikVUT/Monitoring-Linux-terminal/blob/main/images/rsyslog.png" width="700" />


**Steps:**
### 1. Configure rsyslog on the client to capture user input from the terminal.
   To install the rsyslog package in Fedora, use the following command:
   ```bash
   # dnf install -y rsyslog
   ```
   After the installation, start the rsyslog service:
   ```bash
   # systemctl start rsyslog
   ```
   And enable it to start the system:
   ```bash
   # systemctl enable rsyslog.
   ```
  - To log all bash history commands to the syslog add the below line to user ".bashrc" (for all bash session add it to "/etc/bashrc")
   ```bash
    shopt -s syslog_history
   ```
   - Write history logs to a separate file through Rsyslog
    Add the following entry in "/etc/rsyslog.conf" file before the line that sends events to /var/log/messages file or create a config file in "/etc/rsyslog.d" (for example "/etc/rsyslog.d/history.conf")

   ```bash
    if $programname == '-bash' or $programname == 'bash' and $msg contains 'HISTORY:' then {
     action(type="omfile" File="/var/log/history.log")
     stop
   }
   ```
   This will save all bash history for the user in "/var/log/history.log"

   **Send logs to another server** 

   When it comes to rotating logs to another server, you can configure rsyslog to forward logs to a remote server. To do this, you need to edit the /etc/rsyslog.conf configuration file or create a new configuration file in the /etc/rsyslog.d/ directory.
   There are several ways to send protocols from client to server.

   - Send via UDP
   - Send via TCP
   - Send via RELP
   - Send over TLS

   #### Send via UDP
   <a name="send-udp"></a>
  - Create file in "/etc/rsyslog.d/send_history.conf" and ad the below config
      
      ```bash
      $ModLoad imfile
      $InputFilePollInterval 3
      $InputFileName /var/log/history.log
      $InputFileTag test-error
      $InputFileStateFile stat-test-error
      $InputFileSeverity error
      $InputFileFacility local3
      $InputRunFileMonitor
      local3.* @test_server_IP:514
      ```
   Rsyslog will send the logs from log file "/var/log/history.log" to test_server_IP (server) via UPD, port 514. The sent logs have Facility "local3".

   > [!NOTE]  
   >To send via UDP use @, for TCP @@.

   - Restart the rsyslog service.
     
      ```bash
      # service rsyslog restart
      ```
     
#### The demonstration video

https://github.com/user-attachments/assets/321ac366-4409-43c5-a31b-a4095d3a6f0a

-------------------------

#### Send via TCP
- Create file in "/etc/rsyslog.d/send_history.conf" and ad the below config
  
  ```bash
      $ModLoad imfile
      $InputFilePollInterval 3
      $InputFileName /var/log/history.log
      $InputFileTag test-error
      $InputFileStateFile stat-test-error
      $InputFileSeverity error
      $InputFileFacility local3
      $InputRunFileMonitor
      local3.* @@test_server_IP:514
  ```
- Restart the rsyslog service.

    ```bash
        # service rsyslog restart
    ``` 
#### Send via RELP
#### Send over TLS

### 2. Set up rsyslog on the server to receive and categorize logs from the client.
<a name="receive_rsyslog_udp/tcp"></a>

1- Uncomment the following lines in the 'MODULES' section of /etc/rsyslog.conf:

```bash
$ModLoad imtcp
$InputTCPServerRun 514

Note: If using UDP then uncomment the following lines 

$ModLoad imudp
$UDPServerRun 514

```
2-  Configure the rsyslog server to receive events/logs from the client:

Add the following line "/etc/rsyslog.d/history_client.conf"

```bash
if ($syslogfacility-text == 'local3') then {
/var/log/histroy.log
stop
}
```
The config will save all received logs to "/var/log/histroy.log" on the server side
   
---------------------------

## 2. Collecting User Input Using auditd and Sending Logs to a Remote Server via rsyslog
<a name="audit-rsyslog"></a>
With auditd, the system's audit framework tracks user actions, and rsyslog sends these logs to the server.

<img src="https://github.com/TarikVUT/Monitoring-Linux-terminal/blob/main/images/audid.png" width="700" />


**Steps:**

### 1. Configure auditd on the client to collect terminal input.
You can create audit rules for tracking execve, which is the system call made whenever a command is executed.

1- Edit the audit rules file: Open /etc/audit/rules.d/audit.rules with your preferred editor:

```bash
# vi /etc/audit/rules.d/audit.rules
```

2- Add the following rules to capture execve calls for all users:

```bash
# Capture execve calls (commands executed in terminal)
-a always,exit -F arch=b64 -S execve -k user_commands
-a always,exit -F arch=b32 -S execve -k user_commands
```
> [!NOTE]  
> If you want to track only specific users or groups, you can add -F uid=<user_id> or -F gid=<group_id> to the rule.

3- Restart the auditd service to apply the new rules:

```bash
# service auditd restart
```
4- Set rsyslog to send the audit log to remote rsyslog remote server.
refer to [Send via UDP](#send-udp), with changing "$InputFileName /var/log/history.log" to "$InputFileName /var/log/audit/audit.log".


### 2. Set up rsyslog on the server to receive logs from the client.
   Refer to [Set up rsyslog on the server to receive and categorize logs from the client](#receive_rsyslog_udp/tcp)

### The demonstration video


https://github.com/user-attachments/assets/37a52888-7c08-45dc-b505-984b5562d9f3

-----------------------------------
   
## 3. Collecting User Input Using auditd and Sending Logs Directly via Audit
 <a name="audit-auditg"></a>
This approach uses auditd to collect input and directly sends logs to the remote server.

**Steps:**
**TODO**
### 1. Configure auditd on the client to track user input.
### 2. Configure auditd on the server to receive logs from the client.

## 4. Using a Script to Collect History Data and Send it to a Remote Server via rsync
 <a name="code-rsync"></a>
This method collects terminal history using shell scripts and transfers logs using rsync.

<img src="https://github.com/TarikVUT/Monitoring-Linux-terminal/blob/main/images/sync.png" width="700" />

**Steps:**

### 1. Create a script to capture the terminal history and save it to a file.
   1- Use PROMPT_COMMAND with history
   
   You can modify the PROMPT_COMMAND variable in your shell configuration file (~/.bashrc or ~/.bash_profile) to log every command executed by the user into a specific file.

   2- Add the following code at the end of the file (~/.bashrc or ~/.bash_profile):

   ```bash
   export LOGFILE="/home/user/user_history.txt"
   export PROMPT_COMMAND='RETRN_VAL=$?; echo "$(date "+%Y-%m-%d %H:%M:%S") $(whoami) $(history 1 | sed "s/^[ ]*[0-9]*[ ]*//")" >> $LOGFILE'
   ```
   3- To apply the changes immediately:
   
   ```bash
   source ~/.bashrc
   ```
   > [!NOTE]  
   > To collect the history for the root user, apply the above steps in "/etc/bashrc".

   #### The demonstration image
   
 
   <img src="https://github.com/TarikVUT/Monitoring-Linux-terminal/blob/main/images/output_of_bashrc_script.png" width="700" />

   
### 2. Set up the server to receive the history logs via rsync.
   1- Set Up SSH Authentication (if necessary)
   If you're copying files over SSH, it's better to use SSH keys for authentication rather than typing your password repeatedly.
       1. Generate an SSH key (on the client side):
      ```bash
        ssh-keygen -t rsa
      ```
      2. Copy the SSH key to the server:
      ```bash
        ssh-copy-id user@server_address
      ```
  2- Continuously Sync with a Loop
  To make this process continuous, you can use a loop in the terminal. Here's an example using a bash loop:
   ```bash
       #!/bin/bash
       while true; do
       rsync -avz /path/to/local/file user@server_address:/path/to/remote/destination
       sleep 5  # Wait for 5 seconds 
       done
   ```

> [!NOTE]  
> To run the bash script in the background, execute the following command "$ sh rsync_sender.sh  &> /dev/null &"


#### The demonstration video


https://github.com/user-attachments/assets/e36200e5-8f9c-4cd1-8d8c-f2c5376947f1



# Current state of the solution

The following functionalities are already implemented:

 - [x] Configuring rsyslog to collect user input and send it to a remote server:
   - [x] Client-side rsyslog configuration for capturing input.
   - [x] Server-side rsyslog configuration for receiving and sorting logs.
   - [x] Firewall setup for secure communication.
 - [x] Collecting user input via auditd and sending logs to a remote server:
   - [x] Configuring auditd on the client for input collection.
   - [x] Configuring auditd on the server to receive logs.
 - [x] Using a script to collect history data and send it via rsync:
   - [x] Script creation for collecting terminal history.
   - [x] Configuring the server to receive logs via rsync.



# The demonstration video

# How to Contribute
Feel free to submit pull requests or raise issues if you encounter any problems or have suggestions for improvement.

# License
This project is licensed under the MIT License.
