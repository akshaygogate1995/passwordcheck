#!/bin/bash

# Define MySQL database connection details
mysql_user="akshay"
mysql_password="Balaji@123"
mysql_database="mydatabase"

# Define the admin_user and password age threshold (in days)
admin_user="admin_user"
threshold=30

# Define the hosts
hosts=("private-1" "private-2")

# Initialize counters
vm_checked=0
password_change_needed=0
no_need_password_change=0

# Loop through the hosts
for host in "${hosts[@]}"; do
    # Use SSH to execute the command remotely and capture the last password change date
    last_change_date=$(ssh "$host" "sudo chage -l $admin_user | grep 'Last password change' | awk -F: '{print \$2}'")

    # Calculate the age of the password in days
    last_change_epoch=$(date -d "$last_change_date" +%s)
    current_epoch=$(date +%s)
    password_age=$(( (current_epoch - last_change_epoch) / 86400 ))

    # Check if the password age exceeds the threshold
    if [ "$password_age" -ge "$threshold" ]; then
        echo "Warning: Password for $admin_user on $host was last changed $password_age days ago."
        password_change_needed=$((password_change_needed + 1))
# You can send a notification here, for example, via email or other means.
    else
        echo "Password for $admin_user on $host is within the threshold."
        no_need_password_change=$((no_need_password_change + 1))
    fi
    vm_checked=$((vm_checked + 1))
done


# Insert data into MySQL database
mysql --defaults-file=~/.my.cnf -e "USE $mysql_database; INSERT INTO password_checks (vms_checked, password_change_needed, no_need_password_change) VALUES ($vm_checked, $password_change_needed, $no_need_password_change);"


echo "Data inserted into MySQL database:"
echo "VMs Checked: $vm_checked"
echo "Password Change Needed: $password_change_needed"
echo "No Need of Password Change: $no_need_password_change"
