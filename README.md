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

   - [Send via UDP](#udp)
   - [Send via TCP](#tcp)
   - [Send over TLS](#tls)

--------------------------------------------------

   ### Send via UDP
   <a name="udp"></a>

   - **Client side**
   
   <a name="send-udp"></a>
  1. Create file in "/etc/rsyslog.d/send_history.conf" and ad the below config
      
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
   > To send via UDP use @, for TCP @@.

   2. Restart the rsyslog service.
     
   ```bash
      # service rsyslog restart
   ```
      Set up rsyslog on the server to receive and categorize logs from the client.
<a name="receive_rsyslog_udp/tcp"></a>

- **Server side**

1. Uncomment the following lines in the 'MODULES' section of /etc/rsyslog.conf:

```bash
$ModLoad imudp
$UDPServerRun 514

```
2.  Configure the rsyslog server to receive events/logs from the client:

Add the following line "/etc/rsyslog.d/history_client.conf"

```bash
if ($syslogfacility-text == 'local3') then {
/var/log/histroy.log
stop
}
```
The config will save all received logs to "/var/log/histroy.log" on the server side
   
#### The demonstration video

https://github.com/user-attachments/assets/321ac366-4409-43c5-a31b-a4095d3a6f0a

-------------------------

### Send via TCP
<a name="tcp"></a>
- **Client side**
  
1. Create file in "/etc/rsyslog.d/send_history.conf" and ad the below config
  
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
2. Restart the rsyslog service.

    ```bash
        # service rsyslog restart
    ```
- **Server side**

1. Uncomment the following lines in the 'MODULES' section of /etc/rsyslog.conf:

```bash
$ModLoad imtcp
$InputTCPServerRun 514

```
2.  Configure the rsyslog server to receive events/logs from the client:

Add the following line "/etc/rsyslog.d/history_client.conf"

```bash
if ($syslogfacility-text == 'local3') then {
/var/log/histroy.log
stop
}
```
The config will save all received logs to "/var/log/histroy.log" on the server side
   
#### The demonstration video

TODO

----------------------------------------

### Send over TLS
<a name="tls"></a>
The below packages are required on client and server side:

```bash
# yum install rsyslog rsyslog-gnutls
```

- **CA configuration**
1. Create the CA key:
       
   ```bash
    # openssl genrsa 2048 > ca-key.pem
    ```
    
2. Create the CA certificate from this key:

   ```bash
    # openssl req -new -x509 -nodes -days 3600 -key ca-key.pem -out ca-cert.pem
    ```
       
3. Make sure both files (ca-cert.pem and ca-key.pem) are copied to each client and server.

   ```bash
    # scp ca-cert.pem ca-key.pem <user>@<system>:~
    ```
       
- **Server configuration**
  1. In the directory where the ca-key.pem and ca-cert.pem files are generate a signing request:

  ```bash
    # openssl req -newkey rsa:2048 -days 3600 -nodes -keyout server-key.pem -out server-req.pem
    ```
  
    In this step some information will be requested. Input them using the keyboard. There is one very important field that will be requested, make sure you complete is correctly:

    ```bash
    Common Name (eg, your name or your server's hostname) []: rsyslog-server.com
    ```
   The "Common Name" field will later be compared to the rsyslog configuration (specifically the $InputTCPServerStreamDriverPermittedPeer configuration field). If this field is incorrectly populated, two-way TLS authentication will fail.

  
 2. Check that the key is formatted correctly:

    ```bash
    # openssl rsa -in server-key.pem -out server-key.pem
    ```
    
 3. Use the key and CA certificate to sign the request you just created:

    ```bash
    # openssl x509 -req -in server-req.pem -days 3600 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
    ```
    
 4. Move the certificates and keys to the correct directories:

    ```bash
    # mv server-cert.pem ca-cert.pem /etc/pki/tls/certs/
    # mv server-key.pem ca-key.pem /etc/pki/tls/private/
    ```
  
    If you are using SELinux restore these files' context:

    ```bash
    # restorecon -RvF /etc/pki/tls/certs/{ca-cert.pem,server-cert.pem}
    # restorecon -RvF /etc/pki/tls/private/{ca-key.pem,server-key.pem}
    ```  
    
 5. Create a nested configuration file for TLS-related directives. In the example below, this is the file "/etc/rsyslog.d/tls.conf". Make sure it looks like this:

    ```bash
    [root@rsyslog-server ~]# vi /etc/rsyslog.d/tls.conf 
    $DefaultNetstreamDriver gtls
    $DefaultNetstreamDriverCAFile /etc/pki/tls/certs/ca-cert.pem
    $DefaultNetstreamDriverCertFile /etc/pki/tls/certs/server-cert.pem
    $DefaultNetstreamDriverKeyFile /etc/pki/tls/private/server-key.pem
    $ModLoad imtcp
    $InputTCPServerStreamDriverMode 1
    $InputTCPServerStreamDriverAuthMode x509/name
    $InputTCPServerStreamDriverPermittedPeer rsyslog-client.com
    $InputTCPServerRun 6514
    ```

Replace $InputTCPServerStreamDriverPermittedPeer with the client host name. You can also use the '*' character to match multiple names, e.g:
    
6. Restart rsyslog:

 ```bash
    # systemctl restart rsyslog
 ```

- **client configuration**
  
  1. In the directory where the ca-key.pem and ca-cert.pem files are generate a signing request:

  ```bash
    # openssl req -newkey rsa:2048 -days 3600 -nodes -keyout client-key.pem -out client-req.pem
    ```
  
    In this step some information will be requested. Input them using the keyboard. There is one very important field that will be requested, make sure you complete is correctly:

    ```bash
    Common Name (eg, your name or your server's hostname) []: rsyslog-client.com
    ```
   The "Common Name" field will later be compared to the rsyslog configuration (specifically the $InputTCPServerStreamDriverPermittedPeer configuration field). If this field is incorrectly populated, two-way TLS authentication will fail.

  
 2. Check that the key is formatted correctly:

    ```bash
    # openssl rsa -in client-key.pem -out client-key.pem
    ```
    
 3. Use the key and CA certificate to sign the request you just created:

    ```bash
    # openssl x509 -req -in client-req.pem -days 3600 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem
    ```
    
 4. Move the certificates and keys to the correct directories:

    ```bash
    # mv client-cert.pem ca-cert.pem /etc/pki/tls/certs/
    # mv client-key.pem ca-key.pem /etc/pki/tls/private/
    ```
  
    If you are using SELinux restore these files' context:

    ```bash
    # restorecon -RvF /etc/pki/tls/certs/{ca-cert.pem,client-cert.pem}
    # restorecon -RvF /etc/pki/tls/private/{ca-key.pem,client-key.pem}
    ```  
    
 5. Create a drop-in configuration file for the TLS-related directives. In the example below it's /etc/rsyslog.d/tls.conf. In this drop-in I'm also including a omfwd (output mode forward -- responsible for forwarding logs over the network) action that sends all logs to our server. Edit this to match your requirements. Replace "rsyslog-server.lab.com" occurrences with the server hostname in your environment.

    ```bash
    [root@rsyslog-server ~]# vi /etc/rsyslog.d/tls.conf 
    $DefaultNetstreamDriver gtls
    $DefaultNetstreamDriverCAFile /etc/pki/tls/certs/ca-cert.pem
    $DefaultNetstreamDriverCertFile /etc/pki/tls/certs/client-cert.pem
    $DefaultNetstreamDriverKeyFile /etc/pki/tls/private/client-key.pem
    $ModLoad imtcp
    $InputTCPServerStreamDriverMode 1
    $InputTCPServerStreamDriverAuthMode x509/name
    $InputTCPServerStreamDriverPermittedPeer rsyslog-server.com
    *.* @@rsyslog-server.com:6514
    ```
6. Restart rsyslog:

 ```bash
    # systemctl restart rsyslog
 ```
---------------------------
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

Kali code

```bash
export LOGFILE="/home/kali/user_history.txt"

# Variable to store the last exit status
LAST_EXIT_STATUS=0

# Pre-execution hook to store the command to be executed
preexec() {
    LAST_CMD=$1  # Store the command to be executed
}

# Precommand hook to log the last command and its status
precmd() {

    LAST_EXIT_STATUS=$?
    # Check if LAST_CMD is set
    if [[ -n $LAST_CMD ]]; then
        local cmd=$LAST_CMD
        # Log the command with its exit status after execution
        if [[ $LAST_EXIT_STATUS -eq 0 ]]; then
            status_message="SUCCESS"
        else
            status_message="FAILURE"
        fi

        # Log the command with its status
        echo "$(date "+%Y-%m-%d %H:%M:%S") $(whoami) $cmd - $status_message" >> "$LOGFILE"
    fi

    # Reset LAST_CMD for the next command
    unset LAST_CMD
    
}

# Bind the precmd and preexec functions
preexec_functions+=("preexec")


```


```bash
#!/bin/bash
# This script is used to sync configuration files between two servers

# Save the user in var user, and detect the real user in case the script runs using sudo
if [ "$SUDO_USER" ]; then
    user=$SUDO_USER
else
    user=$(whoami)
fi

echo "The real user is: $user"


# Check if sshd service is installed, if not, install it
if ! command -v sshd &> /dev/null; then
    echo "sshd is not installed. Installing..."
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y openssh-server
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y openssh-server
    else
        echo "Unsupported OS. Please install sshd manually."
        exit 1
    fi
else
    echo "sshd is already installed."
fi

# Enable and start the sshd service
sudo systemctl enable sshd
sudo systemctl start sshd



# List network interfaces with their IPv4 addresses
interfaces=$(ip -4 -o addr show | awk '{print $2, $4}' | cut -d/ -f1)

echo "Available network interfaces:"
echo "$interfaces"

# Ask the user to choose an interface
read -p "Enter the interface you want to use: " chosen_interface

echo "You chose interface: $chosen_interface"

# Extract the IPv4 address of the chosen interface
IPv4=$(echo "$interfaces" | grep "^$chosen_interface " | awk '{print $2}')

echo "IPv4 address: $IPv4"

if [ -z "$IPv4" ]; then
    echo "Invalid interface selected."
    exit 1
fi

echo "Selected interface: $chosen_interface with IP: $IPv4"



# Ask the user to enter the server IP
read -p "Enter the server IP: " server_ip

# Generate the SSH key if it doesn't exist
key_path="$HOME/.ssh/key_for_logs"
if [ ! -f "$key_path" ]; then
    ssh-keygen -t rsa -b 2048 -f "$key_path" -N ""
    echo "SSH key generated at $key_path"
else
    echo "SSH key already exists at $key_path"
fi

# Push the public key to the server
ssh-copy-id -i "${key_path}.pub" "$user@$server_ip"
if [ $? -eq 0 ]; then
    echo "SSH key successfully copied to $server_ip"
else
    echo "Failed to copy SSH key to $server_ip"
    exit 1
fi

#
# Add the following lines to the ~/.bashrc file to log the user history
CONFIG1='export LOGFILE="/home/user/user_history.log"'
CONFIG2='export PROMPT_COMMAND='\''RETRN_VAL=$?; echo "$(date "+%Y-%m-%d %H:%M:%S") $(whoami) $(history 1 | sed "s/^[ ]*[0-9]*[ ]*//")" >> $LOGFILE'\'''

if ! grep -qF "$CONFIG1" ~/.bashrc; then
    echo "$CONFIG1" >> ~/.bashrc
fi

if ! grep -qF "$CONFIG2" ~/.bashrc; then
    echo "$CONFIG2" >> ~/.bashrc
fi

# Reload the bashrc file
source ~/.bashrc

# Create the logs_sender_service script
cat << 'EOF' | sudo tee /usr/local/bin/logs_sender_service.sh > /dev/null
#!/bin/bash
while true; do
    rsync -avz /home/user/user_history.log $user@$server_ip:/home/logs/$IPv4.log
    sleep 5  # Wait for 5 seconds 
done
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/logs_sender_service.sh

# Create the systemd service file
cat << EOF | sudo tee /etc/systemd/system/logs_sender_service.service > /dev/null
[Unit]
Description=Logs Sender Service

[Service]
ExecStart=/usr/local/bin/logs_sender_service.sh
Restart=always
User=$user

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable logs_sender_service
sudo systemctl start logs_sender_service

# Check if the logs_sender_service is running
if systemctl is-active --quiet logs_sender_service; then
    echo "logs_sender_service is running."
else
    echo "logs_sender_service is not running."
fi

```


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
