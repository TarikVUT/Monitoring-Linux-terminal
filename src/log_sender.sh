#!/bin/sh


# Save the user in var user, and detect the real user in case the script runs using sudo
if [ "$SUDO_USER" ]; then
    user=$SUDO_USER
else
    user=$(whoami)
fi

echo "The real user is: $user"
key_path="/home/$user/.ssh/key_for_logs"
echo "path 1 $key_path"

detect_os() {

echo "================================="
echo "Detect OS"
echo "================================="

    if [ -f /etc/os-release ]; then
        # Source the file to get OS information
        . /etc/os-release
        
        # Check for Ubuntu
        if [ "$ID" = "ubuntu" ] ; then
        ID="ubuntu"
	echo
	echo "================="
            echo "The OS is Ubuntu."
	echo "================="
	echo
            return 0
        fi
        
        # Check for Fedora 40
        if [ "$ID" = "fedora" ] && [ "$VERSION_ID" = "40" ]; then
        ID="fedora40"
	echo
	echo "================="
           echo "The OS is Fedora 40."
	echo "================="
	echo
            return 0
        fi
        
        # Check for Kali
        if [ "$ID" = "kali" ]; then
        ID="kali"
           
	echo
	echo "================="
	echo "The OS is Kali Linux."
	echo "================="
	echo
            return 0
        fi
        
        echo "This is neither Fedora 40 nor Kali."
        return 1
    else
        echo "/etc/os-release not found. Cannot determine OS."
        return 1
    fi
}

install_and_enable_ssh() {
echo "================================="
echo "Install OpenSSH"
echo "================================="

    	# Ubuntu
        if [ "$ID" = "ubuntu" ] ; then
	echo
            echo "Installing and enabling SSH on Ubuntu..."
	echo
            sudo apt install -y openssh-server
            sudo systemctl enable ssh
            sudo systemctl start ssh
            mkdir -p /root/.ssh
	    mkdir -p /home/$user/.ssh
            chown $user:$user /home/$user/.ssh
	echo
            echo "SSH has been installed and enabled on Ubuntu."
	echo
        # Fedora 40
        elif [ "$ID" = "fedora40" ] ; then
	echo
            echo "Installing and enabling SSH on Fedora 40..."
	echo
            sudo dnf install -y openssh-server
            sudo systemctl enable sshd
            sudo systemctl start sshd
            mkdir -p /root/.ssh
	    mkdir -p /home/$user/.ssh
            chown $user:$user /home/$user/.ssh 
	echo
            echo "SSH has been installed and enabled on Fedora 40."
	echo
        
        # Kali
        elif [ "$ID" = "kali" ]; then
	echo
            echo "Installing and enabling SSH on Kali Linux..."
	echo
            sudo apt update
            sudo apt install -y openssh-server
            sudo systemctl enable ssh
            sudo systemctl start ssh
	    mkdir -p /home/$user/.ssh
	    mkdir -p /root/.ssh
     	    chown $user:$user /home/$user/.ssh 
	echo
            echo "SSH has been installed and enabled on Kali Linux."
	echo
        
        else
            echo "This script only supports Fedora 40 and Kali."
        fi

}


# List network interfac
detect_interface(){
echo "================================="
echo "Detect interfaces"
echo "================================="
	
interfaces=$(ip -4 -o addr show | awk '{print $2, $4}' | cut -d/ -f1)

echo "Available network interfaces:"
echo "$interfaces"

# Ask the user to choose an interface
echo
read -p "Enter the interface you want to use: " chosen_interface
	
echo
echo "You chose interface: $chosen_interface"

# Extract the IPv4 address of the chosen interface
IPv4=$(echo "$interfaces" | grep "^$chosen_interface " | awk '{print $2}')

echo
echo "IPv4 address: $IPv4"

if [ -z "$IPv4" ]; then
    echo "Invalid interface selected."
    exit 1
fi

echo "Selected interface: $chosen_interface with IP: $IPv4"
}


# Function to check if the server IP is alive
check_server_ip() {
    local server_ip=$1
    ping -c 1 -W 1 "$server_ip" &> /dev/null
    if [ $? -eq 0 ]; then
        echo
        echo "Server $server_ip is reachable."
        echo
        sleep 2
        return 0
    else
        echo
        echo "Server $server_ip is unreachable."
        echo
        sleep 2
        return 1
    fi
}

set_server_ip(){
echo "================================="
echo "Set the remote server"
echo "================================="

# Ask the user to enter the server IP
read -p "Enter the server IP: " server_ip

# Check if the server is reachable
check_server_ip "$server_ip"
if [ $? -ne 0 ]; then
    echo "We can not ping the server, check the server IP"
    exit 1
fi

echo "The user is $user"

# Generate the SSH key if it doesn't exist
key_path="/home/$user/.ssh/key_for_logs"

echo "The key path is $key_path"

echo "path 2 $key_path"
if [ -f "$key_path" ]; then
    echo "SSH key already exists at $key_path. Deleting the existing key."
    rm "$key_path"
    rm "${key_path}.pub"  # Also remove the public key
fi

# Generate a new SSH key without a passphrase
ssh-keygen -t rsa -b 2048 -f "$key_path" -N ""
echo
echo "SSH key generated at $key_path"
echo

# Ask for the username to push the public key
read -p "Enter the username for SSH: " sshuser

echo
echo "Change the key's owner"
echo
chown $user:$user $key_path
chown $user:$user "${key_path}.pub"

# Push the public key to the server
echo "ssh-copy-id -i ${key_path}.pub $sshuser@$server_ip"
ssh-copy-id -i "${key_path}.pub" "$sshuser@$server_ip"
if [ $? -eq 0 ]; then
    echo
    echo "SSH key successfully copied to $server_ip"
    echo
else
    echo
    echo "Failed to copy SSH key to $server_ip"
    echo
    exit 1
fi




}
add_to_zshrc_if_missing() {

user_zshrc_path="/home/$user/.zshrc"
root_zshrc_path="/root/.zshrc"

add_config(){
local path="$1"
    # Define the block of code to add
echo "export LOGFILE=\"/home/$user/user_history.log\"
# Variable to store the last exit status
LAST_EXIT_STATUS=0

# Pre-execution hook to store the command to be executed
preexec() {
    LAST_CMD=\$1  # Store the command to be executed
}

# Precommand hook to log the last command and its status
precmd() {
    LAST_EXIT_STATUS=\$?
    # Check if LAST_CMD is set
    if [[ -n \$LAST_CMD ]]; then
        local cmd=\$LAST_CMD
        # Log the command with its exit status after execution
        if [[ \$LAST_EXIT_STATUS -eq 0 ]]; then
            status_message=\"SUCCESS\"
        else
            status_message=\"FAILURE\"
        fi

        # Log the command with its status
        echo \"\$(date \"+%Y-%m-%d %H:%M:%S\") \$(whoami) \$cmd - \$status_message\" >> \"\$LOGFILE\"
    fi
    # Reset LAST_CMD for the next command
    unset LAST_CMD
}

# Bind the precmd and preexec functions
preexec_functions+=(\"preexec\")" >> $path

}


if grep -Fxq "export LOGFILE=\"/home/$user/user_history.log\"" $user_zshrc_path; then
    echo "The configuration exists in $user_zshrc_path, please check that....."
else
    echo "Add the new configuration to $user_zshrc_path"
    add_config $user_zshrc_path
    echo "source $user_zshrc_path"
    sleep 1
    zsh -c "source $user_zshrc_path"
fi

sleep 1

# Root zshrc
if grep -Fxq "export LOGFILE=\"/home/$user/user_history.log\"" $root_zshrc_path; then
    echo "The configuration exists in $root_zshrc_path, please check that....."
else
    echo "Add the new configuration to $root_zshrc_path"
    add_config $root_zshrc_path
    echo "source $root_zshrc_path"
    sleep 1
    zsh -c "source $root_zshrc_path"
fi
sleep 1
}

collect_log(){
echo "================================="
echo "Config logger in the Client"
echo "================================="
user_bash_path="/home/$user/.bashrc"
root_bash_path="/root/.bashrc"

        # Fedora 40
        if [ "$ID" = "fedora40" ] || [ "$ID" = "ubuntu" ]; then
        # Add the following lines to the ~/.bashrc file to log the user history
	##
	# /home/$user/user_terminal.log is a file where the logs will be saved localy.
	# feelfree to change it, but may you will face a issue with selinux.
	##
	CONFIG1="export LOGFILE=\"/home/$user/user_history.log\""
	CONFIG2='export PROMPT_COMMAND='\''RETRN_VAL=$?; echo "$(date "+%Y-%m-%d %H:%M:%S") $(whoami) $(history 1 | sed "s/^[ ]*[0-9]*[ ]*//")" >> $LOGFILE'\'''

	if ! grep -qF "$CONFIG1" $user_bash_path; then
   	 echo "$CONFIG1" >> $user_bash_path
	fi	

	if ! grep -qF "$CONFIG2" $user_bash_path; then
	    echo "$CONFIG2" >> $user_bash_path
	    source $user_bash_path
	fi
	
	# For ROOT

	if ! grep -qF "$CONFIG1" $root_bash_path; then
	echo "$CONFIG1" >> $root_bash_path
	fi

	if ! grep -qF "$CONFIG2" $root_bash_path; then
   	 echo "$CONFIG2" >> $root_bash_path
   	 source $root_bash_path
	fi

        # Kali
        elif [ "$ID" = "kali" ]; then
        
	add_to_zshrc_if_missing
        
        else
            echo "This script only supports Fedora 40, Ubuntu and Kali."
        fi


}
create_logger_services()
{
echo "================================="
echo "Create sender service"
echo "================================="

path_sync_sh="/usr/local/bin/sync_user_history.sh"
path_sync_service="/etc/systemd/system/sync_user_history.service"
 echo
 echo "Creating sync log sender"
 echo
 echo "#!/bin/bash
 while true; do
 rsync -avz -e \"ssh -i $key_path\" /home/$user/user_history.log $sshuser@$server_ip:/home/$sshuser/$IPv4.log
 
 sleep 5  # Wait for 5 seconds 
 done
 " > $path_sync_sh
 
 # Make the script exec
 chmod +x $path_sync_sh
 echo
 echo "Creating sync service"
 echo
 echo "[Unit]
Description=Sync User History Log Service
After=network.target

[Service]
ExecStart=$path_sync_sh
Restart=always
User=$user

[Install]
WantedBy=multi-user.target
 " > $path_sync_service
 


# Enable the service to start on boot

    if systemctl enable sync_user_history.service; then
        echo "Service enabled to start on boot."
    else
        echo "Failed to enable the service."
        return 1  # Exit the function with an error code
    fi
    
    if systemctl daemon-reload; then
        echo " Reload the systemd daemon."
    else
        echo "Failed to reload the systemd daemon."
        return 1  # Exit the function with an error code
    fi   

    # Start the service immediately
    if systemctl restart sync_user_history.service; then
        echo "Service started successfully."
    else
        echo "Failed to start the service."
        return 1  # Exit the function with an error code
    fi
    
    # Check the status of the service
    echo "Checking the status of sync_user_history.service..."
    if systemctl status sync_user_history.service; then
        echo "Service is running."
    else
        echo "Service is not running."
        return 1  # Exit the function with an error code
    fi



}

main(){

detect_os
install_and_enable_ssh
detect_interface
set_server_ip
collect_log
create_logger_services


}
main
