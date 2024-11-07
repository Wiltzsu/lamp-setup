#!/bin/bash

# Define a few color codes
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Install expect
echo -e "${BLUE}Installing Expect...${$}"
sudo apt install expect

# Install Apache
echo -e "${BLUE}Installing Apache...${NC}"
sudo apt install apache2

# Append "ServerName 127.0.0.1" to Apache's configuration file
echo -e "${BLUE}Adding localhost server name to configuration file...${NC}"
if ! grep -q "ServerName 127.0.0.1" /etc/apache2/apache2.conf; then
    echo "ServerName 127.0.0.1" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
fi

# Install MySQL server
echo -e "${BLUE}Installing MySQL server...${NC}"
sudo apt install mysql-server

# Run the secure installation script for MySQL
echo -e "${BLUE}Running MySQL secure installation...${NC}"

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

echo -e "${BLUE}MySQL secure installation ready...${NC}"

echo -e "${BLUE}Installing PHP...${NC}"
sudo apt install -y php libapache2-mod-php php-mysql

# Uninstall redundant files
echo -e "${BLUE}Cleaning up unnecessary packages...${NC}"
sudo apt autoremove

# Print Apache, MySQL and PHP versions
apache2 -v
mysql --version
php -v

# Reload system configuration and restart Apache
echo -e "${BLUE}Reloading daemon...${NC}"
sudo systemctl daemon-reload
echo -e "${BLUE}Restaring Apache...${NC}"
sudo systemctl restart apache2.service

echo -e "${BLUE}LAMP stack installation complete!${NC}"

