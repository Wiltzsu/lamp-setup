#!/bin/bash

# Define a few color codes
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Install expect
echo -e "${PURPLE}Installing Expect...${NC}"
sudo apt install -y expect


# Install Apache
echo -e "${PURPLE}Installing Apache...${NC}"
sudo apt install -y apache2

# Append "ServerName 127.0.0.1" to Apache's configuration file
echo -e "${PURPLE}Adding localhost server name to configuration file...${NC}"
if ! grep -q "ServerName 127.0.0.1" /etc/apache2/apache2.conf; then
    echo "ServerName 127.0.0.1" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
fi

# Install MySQL server
echo -e "${PURPLE}Installing MySQL server...${NC}"
sudo apt install mysql-server

# Run the secure installation script for MySQL
echo -e "${PURPLE}Running MySQL secure installation...${NC}"

expect <<EOF
spawn sudo mysql_secure_installation

# Handle the sudo password prompt 
expect "password for *:"
send "changeme\r"

# Proceed with MySQL secure installation and set default values
expect "VALIDATE PASSWORD COMPONENT"
send "y\r"
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

echo -e "${PURPLE}MySQL secure installation ready...${NC}"

echo -e "${PURPLE}Installing PHP...${NC}"
sudo apt install -y php libapache2-mod-php php-mysql

# Uninstall redundant files
echo -e "${PURPLE}Cleaning up unnecessary packages...${NC}"
sudo apt autoremove

# Print Apache, MySQL and PHP versions
apache2 -v
mysql --version
php -v

# Reload system configuration and restart Apache
echo -e "${PURPLE}Reloading daemon...${NC}"
sudo systemctl daemon-reload
echo -e "${PURPLE}Restaring Apache...${NC}"
sudo systemctl restart apache2.service

echo -e "${PURPLE}LAMP stack installation complete!${NC}"

