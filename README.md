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

## 1. Configuring rsyslog to Collect User Input and Send it to a Remote Server
This method uses rsyslog to capture and forward terminal input.
**Steps:**
1. Configure rsyslog on the client to capture user input from the terminal.
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

 - [x] Configuring rsyslog to collect user input and send it to a remote server:
   - [x] Client-side rsyslog configuration for capturing input.
   - [x] Server-side rsyslog configuration for receiving and sorting logs.
   - [x] Firewall setup for secure communication.
 - [x] Collecting user input via auditd and sending logs to a remote server:
   - [x] Configuring auditd on the client for input collection.
   - [x] Configuring auditd on the server to receive logs.
 - [x]Using a script to collect history data and send it via rsync:
   - [x] Script creation for collecting terminal history.
   - [x] Configuring the server to receive logs via rsync.



# The demonstration video

# How to Contribute
Feel free to submit pull requests or raise issues if you encounter any problems or have suggestions for improvement.

# License
This project is licensed under the MIT License.
