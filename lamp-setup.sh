#!/bin/bash

# Define a few color codes
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Install expect
echo -e "${GREEN}Installing Expect...${$}"
sudo apt install expect

# Install Apache
echo -e "${GREEN}Installing Apache...${NC}"
sudo apt install apache2

# Append "ServerName 127.0.0.1" to Apache's configuration file
echo -e "${GREEN}Adding localhost server name to configuration file...${NC}"
if ! grep -q "ServerName 127.0.0.1" /etc/apache2/apache2.conf; then
    echo "ServerName 127.0.0.1" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
fi

# Install MySQL server
echo -e "${GREEN}Installing MySQL server...${NC}"
sudo apt install mysql-server

# Run the secure installation script for MySQL
echo -e "${GREEN}Running MySQL secure installation...${NC}"

expect <<EOF
spawn sudo mysql_secure_installation

# Handle the sudo password prompt
expect "password for *:"
send "changeme\r"

# Proceed with MySQL secure installation and set default values
expect "VALIDATE PASSWORD COMPONENT"
send "y\r"
expect "Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:"
send "1\r"
expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect eof
EOF

echo -e "${GREEN}MySQL secure installation ready...${NC}"

echo -e "${GREEN}Installing PHP...${NC}"
sudo apt install -y php libapache2-mod-php php-mysql

# Uninstall redundant files
echo -e "${GREEN}Cleaning up unnecessary packages...${NC}"
sudo apt autoremove

# Reload system configuration and restart Apache
echo -e "${GREEN}Reloading daemon...${NC}"
sudo systemctl daemon-reload
echo -e "${GREEN}Restaring Apache...${NC}"
sudo systemctl restart apache2.service

echo -e "${GREEN}LAMP stack installation complete!${NC}"

