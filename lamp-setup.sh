#!/bin/bash

# Check if the script is running as root
# $EUID is a special variable that holds the user ID of the current user
# If it is not 0 (root), the script will exit with a message
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please run it with sudo."
    exit 1
fi

echo "Script is running as root. Proceeding..."

# Define colors for output messages
# These are ANSI escape codes for colored text
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging setup
# All output from the install process will be logged to /var/log/lamp_install.log
# 'exec' redirects the output data and error data to the log file
LOG_FILE="/var/log/lamp_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to log errors and exit
# Stops the script and prints first error argument
log_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# LAMP Stack Installation
# Update the package list to ensure we have the latest packages
echo -e "${GREEN}Updating package list...${NC}"
sudo apt update || log_error "Failed to update package list"

# Install Apache, MySQL, PHP and other necessary packages
echo -e "${GREEN}Installing required packages...${NC}"
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql ufw || log_error "Failed to install packages"

# Apache Configuration
# Add 'ServerName' to Apache configuration to suppress a warning
echo -e "${GREEN}Configuring Apache...${NC}"
if ! grep -q "ServerName 127.0.0.1" /etc/apache2/apache2.conf; then
    echo "ServerName 127.0.0.1" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
fi

# Restart Apache to apply changes
sudo systemctl restart apache2 || log_error "Failed to restart Apache"

# Configure UFW Firewall
# Allow traffic for Apache and SSH, then enable the firewall
echo -e "${GREEN}Configuring UFW firewall...${NC}"
sudo ufw allow 'Apache Full'
sudo ufw allow ssh
sudo ufw enable || log_error "Failed to enable UFW"
# Display the current status of the firewall
sudo ufw status

# Verify Installations
# Print the installed versions of Apache, MySQL and PHP
echo -e "${GREEN}Verifying installations...${NC}"
apache2 -v
mysql --version
php -v

# Ask if user wants to create a new project
# Read the user input and store it in CREATE_PROJECT variable
read -p "Do you want to create a new project? (y/n): " CREATE_PROJECT

# If the user wants to create a project, proceed
if [[ "$CREATE_PROJECT" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Setting up a new project...${NC}"

    # Ask for project name
    read -p "Enter the project name: " PROJECT_NAME

    # Validate project name
    # Ensure it's not empty and doesn't contain spaces
    if [[ -z "$PROJECT_NAME" || "$PROJECT_NAME" =~ [[:space:]] ]]; then
        echo -e "${YELLOW}Project name cannot be empty or contain spaces.${NC}"
        exit 1
    fi

    # Define variables for project setup
    PROJECT_DIR="/var/www/html/$PROJECT_NAME"
    DB_NAME="$PROJECT_NAME"
    APACHE_CONF="/etc/apache2/sites-available/$PROJECT_NAME.conf"
    ETC_HOSTS="/etc/hosts"

    # Create project directory if it doesn't exist
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}Project $PROJECT_NAME already exists.${NC}"
        exit 1
    else
        sudo mkdir -p "$PROJECT_DIR"
        # Create a simple PHP file to test the setup
        echo "<?php phpinfo(); ?>" | sudo tee "$PROJECT_DIR/index.php" > /dev/null
        # Set ownership and permissions for the project directory
        sudo chown -R www-data:www-data "$PROJECT_DIR"
        sudo chmod -R 755 "$PROJECT_DIR"
        echo -e "${GREEN}Project directory created at $PROJECT_DIR${NC}"
    fi

    # Create a MySQL database for the project
    echo -e "${GREEN}Creating database $DB_NAME...${NC}"
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" || log_error "Failed to create database"

    # Create Apache virtual host configuration for the project
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

    # Add project to domain to /etc/hosts for local access
    # This maps the project domain to localhost (127.0.0.1)
    if ! grep -q "$PROJECT_NAME.local" $ETC_HOSTS; then
        echo "127.0.0.1 $PROJECT_NAME.local" | sudo tee -a $ETC_HOSTS > /dev/null
        echo -e "${GREEN}Added $PROJECT_NAME.local to /etc/hosts${NC}"
    fi

    # Enable the new virtual host and reload Apache
    # This makes the new site configuration active
    echo -e "${GREEN}Enabling virtual host...${NC}"
    sudo a2ensite "$PROJECT_NAME.conf" || log_error "Failed to enable virtual host"
    echo -e "${GREEN}Reloading Apache...${NC}"
    sudo systemctl reload apache2 || log_error "Failed to reload Apache"

    # Inform the user that the setup is complete and provide the URL
    echo -e "${GREEN}Setup for $PROJECT_NAME complete! Access it at http://$PROJECT_NAME.local${NC}"
    else
    # If user chose not to create a new project, finish the script
        echo -e "${GREEN}No new project created. Script finished.${NC}"
    fi
