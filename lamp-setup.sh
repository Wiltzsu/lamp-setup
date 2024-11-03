#!/bin/bash

# Install Apache
sudo apt install apache2

# Append "ServerName 127.0.0.1" to Apache's configuration file
if ! grep -q "ServerName 127.0.0.1" /etc/apache2/apache2.conf; then
    echo "ServerName 127.0.0.1" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
fi

# Install MySQL server
sudo apt install mysql-server

# Run the secure installation script for MySQL
sudo mysql_secure_installation

set timeout -1
set MYSQL_ROOT_PASSWORD "your_password"

spawn sudo mysql_secure_installation

expect "Enter password for user root:"
send "$MYSQL_ROOT_PASSWORD\r"
expect "Press y|Y for Yes, any other key for No:"
send "y\r"
expect "New password:"
send "$MYSQL_ROOT_PASSWORD\r"
expect "Re-enter new password:"
send "$MYSQL_ROOT_PASSWORD\r"
expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect eof

# Uninstall redundant files
sudo apt autoremove

# Reload system configuration and restart Apache
sudo systemctl daemon-reload
sudo systemctl restart apache2

