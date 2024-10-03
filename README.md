> [!WARNING]
> This script is tailored for Fedora 38. It operates under root permissions. If you lack extensive Linux expertise, refrain from altering its contents. Take the time to thoroughly understand the script's functionality before deciding whether to execute it.


# Monitoring-Linux-terminal

**Introduction**

This project provides a comprehensive solution for monitoring and logging terminal input on Linux systems. It demonstrates how to collect and send user input from a client machine to a remote server for centralized logging and auditing. The solution leverages various tools, such as rsyslog, auditd, and rsync, offering multiple approaches depending on your needs. This setup is useful for system administrators who want to track user activities on terminals for security, auditing, or compliance purposes.

**Features**

. Collect terminal input using rsyslog, auditd, or shell history.
. Automatically send the collected logs to a remote server for centralized storage and analysis.
. Flexible setup options for different environments and security requirements.

# Methods of Collection

1. Configuring rsyslog to Collect User Input and Send it to a Remote Server
2. Collecting User Input Using auditd and Sending Logs to a Remote Server via rsyslog
3. Collecting User Input Using auditd and Sending Logs Directly via Audit
4. Using a Script to Collect History Data and Send it to a Remote Server via rsync

--------------------------------------------

## 1. Configuring rsyslog to Collect User Input and Send it to a Remote Server
This method uses rsyslog to capture and forward terminal input.
**Steps:**
1. Configure rsyslog on the client to capture user input from the terminal.
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

   - Rotation via UDP
   - Rotation via TCP
   - Rotation via RELP
   - Rotation over TLS


2. Set up rsyslog on the server to receive and categorize logs from the client.
 
   

## 2. Collecting User Input Using auditd and Sending Logs to a Remote Server via rsyslog
With auditd, the system's audit framework tracks user actions, and rsyslog sends these logs to the server.

**Steps:**

1. Configure auditd on the client to collect terminal input.
2. Set up rsyslog on the server to receive logs from the client.

   
## 3. Collecting User Input Using auditd and Sending Logs Directly via Audit
This approach uses auditd to collect input and directly sends logs to the remote server.

**Steps:**

1. Configure auditd on the client to track user input.
2. Configure auditd on the server to receive logs from the client.

## 4. Using a Script to Collect History Data and Send it to a Remote Server via rsync
This method collects terminal history using shell scripts and transfers logs using rsync.

**Steps:**

1. Create a script to capture the terminal history and save it to a file.
2. Set up the server to receive the history logs via rsync.

# Current state of the solution

The following functionalities are already implemented:

 - [ ] Configuring rsyslog to collect user input and send it to a remote server:
   - [ ] Client-side rsyslog configuration for capturing input.
   - [ ] Server-side rsyslog configuration for receiving and sorting logs.
   - [ ] Firewall setup for secure communication.
 - [ ] Collecting user input via auditd and sending logs to a remote server:
   - [ ] Configuring auditd on the client for input collection.
   - [ ] Configuring auditd on the server to receive logs.
 - [ ] Using a script to collect history data and send it via rsync:
   - [ ] Script creation for collecting terminal history.
   - [ ] Configuring the server to receive logs via rsync.



# The demonstration video

# How to Contribute
Feel free to submit pull requests or raise issues if you encounter any problems or have suggestions for improvement.

# License
This project is licensed under the MIT License.
