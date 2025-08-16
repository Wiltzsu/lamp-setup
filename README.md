# LAMP Stack Automation Script

This script automates the setup of a **LAMP stack (Linux, Apache, MySQL, PHP)** on Ubuntu-based systems. It includes options to create a development environment with a virtual host and database for your project. The script is designed to reduce manual work and ensure a smooth installation process.
This script was developed as part of a thesis project to explore automation in LAMP stack setup.

For any issues or suggestions, feel free to open an issue in the GitHub repository.

---

## What the Script Does

### Installs Required Software:
- **Apache** (Web Server)
- **MySQL** (Database Server)
- **PHP** (Server-side Scripting Language)
- Additional PHP modules (`libapache2-mod-php`, `php-mysql`, etc.)
- **UFW** (Firewall)

### ⚙️ Configures Apache:
- Sets a default `ServerName` to suppress warnings.
- Restarts the Apache service to apply changes.

### 🔐 Firewall Configuration:
- Enables **UFW** and allows traffic for **Apache** and **SSH**.

### 🚀 Project Setup (Optional):
- Creates a new project directory.
- Sets up an Apache virtual host.
- Creates a MySQL database for the project.
- Adds the project to `/etc/hosts` for local access.

### ✅ Verification:
- Displays installed versions of **Apache**, **MySQL**, and **PHP**.

### 📝 Logs:
- All script output is logged to `/var/log/lamp_install.log`.

---

## 💡 Prerequisites
- An Ubuntu-based system.
- Basic familiarity with the Linux terminal.
- The script must be run as root (or with `sudo`).

---

## 🚀 How to Use

### Step 1: Download the Script
Clone the repository or download the script:
```bash
git clone https://github.com/Wiltzsu/lamp-setup.git
cd lamp-setup
```
### Step 2: Run the Script
Make the script executable and run it:
```bash
chmod +x lamp_install.sh
sudo ./lamp_install.sh
```
### To uninstall all components
```bash
sudo apt purge -y apache2 mysql-server php libapache2-mod-php php-mysql
sudo apt autoremove -y
sudo rm -rf /var/www/html/<project_name>
sudo rm -rf /etc/apache2/sites-available/<project_name>.conf
sudo rm -rf /var/log/apache2/<project_name>-error.log
sudo rm -rf /var/log/apache2/<project_name>-access.log
sudo sed -i "/<project_name>.local/d" /etc/hosts
```
## 📜 License

This project is licensed under the [MIT License](LICENSE).