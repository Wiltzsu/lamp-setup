#!/bin/bash

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please run it with sudo."
    exit 1
fi

echo "Script is running as root. Proceeding..."

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging setup
LOG_FILE="/var/log/lamp_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to log errors
log_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# LAMP Stack Installation
echo -e "${GREEN}Updating package list...${NC}"
sudo apt update || log_error "Failed to update package list"

echo -e "${GREEN}Installing required packages...${NC}"
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql expect ufw || log_error "Failed to install packages"

# Apache Configuration
echo -e "${GREEN}Configuring Apache...${NC}"
if ! grep -q "ServerName 127.0.0.1" /etc/apache2/apache2.conf; then
    echo "ServerName 127.0.0.1" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
fi
sudo systemctl restart apache2 || log_error "Failed to restart Apache"

# MySQL Secure Setup
echo -e "${GREEN}Securing MySQL...${NC}"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "FLUSH PRIVILEGES;"i 

# Configure UFW Firewall
echo -e "${GREEN}Configuring UFW firewall...${NC}"
sudo ufw allow 'Apache Full'
sudo ufw allow ssh
sudo ufw enable || log_error "Failed to enable UFW"
sudo ufw status

# Verify Installations
echo -e "${GREEN}Verifying installations...${NC}"
apache2 -v
mysql --version
php -v

# Ask if user wants to create a new project
read -p "Do you want to create a new project? (y/n): " CREATE_PROJECT

if [[ "$CREATE_PROJECT" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Setting up a new project...${NC}"

    # Ask for project name
    read -p "Enter the project name: " PROJECT_NAME

    # Validate project name
    if [[ -z "$PROJECT_NAME" || "$PROJECT_NAME" =~ [[:space:]] ]]; then
        echo -e "${YELLOW}Project name cannot be empty or contain spaces.${NC}"
        exit 1
    fi

    # Define variables
    PROJECT_DIR="/var/www/html/$PROJECT_NAME"
    DB_NAME="$PROJECT_NAME"
    APACHE_CONF="/etc/apache2/sites-available/$PROJECT_NAME.conf"
    ETC_HOSTS="/etc/hosts"

    # Create project directory
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}Project $PROJECT_NAME already exists.${NC}"
        exit 1
    else
        sudo mkdir -p "$PROJECT_DIR"
        echo "<?php phpinfo(); ?>" | sudo tee "$PROJECT_DIR/index.php" > /dev/null
        sudo chown -R www-data:www-data "$PROJECT_DIR"
        sudo chmod -R 755 "$PROJECT_DIR"
        echo -e "${GREEN}Project directory created at $PROJECT_DIR${NC}"
    fi

    # Create database
    echo -e "${GREEN}Creating database $DB_NAME...${NC}"
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" || log_error "Failed to create database"

    # Create Apache virtual host configuration
    echo -e "${GREEN}Creating Apache configuration for $PROJECT_NAME...${NC}"
    sudo tee "$APACHE_CONF" > /dev/null <<EOF
    <VirtualHost *:80>
    ServerName $PROJECT_NAME.local
    DocumentRoot $PROJECT_DIR

    <Directory $PROJECT_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/${PROJECT_NAME}-error.log
    CustomLog /var/log/apache2/${PROJECT_NAME}-access.log combined
</VirtualHost>
EOF

    # Add project to /etc/hosts
    if ! grep -q "$PROJECT_NAME.local" $ETC_HOSTS; then
        echo "127.0.0.1 $PROJECT_NAME.local" | sudo tee -a $ETC_HOSTS > /dev/null
        echo -e "${GREEN}Added $PROJECT_NAME.local to /etc/hosts${NC}"
    fi

    # Enable virtual host
    sudo a2ensite "$PROJECT_NAME.conf" || log_error "Failed to enable virtual host"
    sudo systemctl reload apache2 || log_error "Failed to reload Apache"

    echo -e "${GREEN}Setup for $PROJECT_NAME complete! Access it at http://$PROJECT_NAME.local${NC}"
else
    echo -e "${GREEN}No new project created. Script finished.${NC}"
fi
