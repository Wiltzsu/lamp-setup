#!/bin/bash

# Define colors
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging setup
LOG_FILE="lamp_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${PURPLE}Updating package list...${NC}"
sudo apt update

echo -e "${PURPLE}Installing required packages...${NC}"
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql expect || {
    echo "Error: Package installation failed." >&2
    exit 1
}

# Apache configuration
echo -e "${PURPLE}Configuring Apache...${NC}"
if ! grep -q "ServerName 127.0.0.1" /etc/apache2/apache2.conf; then
    echo "ServerName 127.0.0.1" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
fi
sudo systemctl restart apache2

# MySQL secure setup
echo -e "${PURPLE}Securing MySQL...${NC}"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "FLUSH PRIVILEGES;"

# Define the file path
MYSQL_CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Check if the [mysqld] section exists, and add or modify the bind-address setting
echo -e "${PURPLE}Configuring MySQL to bind to localhost only...${NC}"

if grep -q "^\[mysqld\]" "$MYSQL_CONFIG_FILE"; then
    # If [mysqld] exists, update or add the bind-address line
    sudo sed -i '/^\[mysqld\]/,/^\[/ s/^bind-address.*/bind-address = 127.0.0.1/' "$MYSQL_CONFIG_FILE" || 
    echo "bind-address = 127.0.0.1" | sudo tee -a "$MYSQL_CONFIG_FILE" > /dev/null
else
    # If [mysqld] doesn't exist, add it with the bind-address setting
    echo -e "\n[mysqld]\nbind-address = 127.0.0.1" | sudo tee -a "$MYSQL_CONFIG_FILE" > /dev/null
fi

# Restart MySQL to apply changes
echo -e "${PURPLE}Restarting MySQL service to apply changes...${NC}"
sudo systemctl restart mysql

# Verify installations
echo -e "${PURPLE}Verifying installation...${NC}"
apache2 -v
mysql --version
php -v

echo -e "${PURPLE}LAMP stack installation complete!${NC}"
