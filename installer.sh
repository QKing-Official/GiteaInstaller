#!/bin/bash

# Gitea Local Installation Script
# Version: 1.23.1

# Variables
GITEA_VERSION="1.23.1"  # Gitea version to install
GITEA_USER="gitea"
GITEA_HOME="/home/$GITEA_USER"
GITEA_DIR="/var/lib/gitea"
GITEA_BINARY="/usr/local/bin/gitea"
GITEA_PORT="3000"  # Port for Gitea to run on
GITEA_DB_NAME="gitea_db"  # SQLite database name
GITEA_DB_USER="gitea_user"  # Database username (not used for SQLite)
GITEA_DB_PASSWORD="gitea_password"  # Database password (not used for SQLite)
GITEA_ADMIN_USER="admin"  # Admin username for Gitea
GITEA_ADMIN_PASSWORD="admin_password"  # Admin password for Gitea

# Step 1: Update the system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install dependencies
echo "Installing dependencies..."
sudo apt install -y git curl sqlite3

# Step 3: Create a user for Gitea
echo "Creating Gitea user..."
sudo adduser --system --group --disabled-password --home $GITEA_HOME --shell /bin/bash $GITEA_USER

# Step 4: Download and install Gitea
echo "Downloading Gitea binary..."
sudo wget -O /tmp/gitea https://dl.gitea.io/gitea/$GITEA_VERSION/gitea-$GITEA_VERSION-linux-amd64
sudo mv /tmp/gitea $GITEA_BINARY
sudo chmod +x $GITEA_BINARY

# Step 5: Create Gitea directory structure
echo "Setting up Gitea directories..."
sudo mkdir -p $GITEA_DIR/{custom,data,log}
sudo chown -R $GITEA_USER:$GITEA_USER $GITEA_DIR
sudo chmod -R 750 $GITEA_DIR

# Step 6: Configure Gitea as a systemd service
echo "Configuring Gitea systemd service..."
sudo tee /etc/systemd/system/gitea.service > /dev/null <<EOL
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
RestartSec=2s
Type=simple
User=$GITEA_USER
Group=$GITEA_USER
WorkingDirectory=$GITEA_DIR
ExecStart=$GITEA_BINARY web --config $GITEA_DIR/custom/conf/app.ini
Restart=always
Environment=USER=$GITEA_USER HOME=$GITEA_HOME

[Install]
WantedBy=multi-user.target
EOL

# Step 7: Create Gitea configuration file
echo "Creating Gitea configuration file..."
sudo tee $GITEA_DIR/custom/conf/app.ini > /dev/null <<EOL
APP_NAME = Gitea
RUN_USER = $GITEA_USER
RUN_MODE = prod

[server]
HTTP_PORT = $GITEA_PORT
DOMAIN = localhost
ROOT_URL = http://localhost:$GITEA_PORT/

[database]
DB_TYPE = sqlite3
HOST = localhost:3306
NAME = $GITEA_DB_NAME
USER = $GITEA_DB_USER
PASSWD = $GITEA_DB_PASSWORD
PATH = $GITEA_DIR/data/$GITEA_DB_NAME.sqlite3

[repository]
ROOT = $GITEA_DIR/data/gitea-repositories

[session]
PROVIDER = file
PROVIDER_CONFIG = $GITEA_DIR/data/sessions

[log]
MODE = file
LEVEL = Info
ROOT_PATH = $GITEA_DIR/log
EOL

# Step 8: Set permissions for the configuration file
sudo chown -R $GITEA_USER:$GITEA_USER $GITEA_DIR/custom/conf/app.ini

# Step 9: Reload systemd and start Gitea
echo "Starting Gitea service..."
sudo systemctl daemon-reload
sudo systemctl enable --now gitea

# Step 10: Display installation details
echo "Gitea installation complete!"
echo "Access Gitea at: http://localhost:$GITEA_PORT"
echo "Use the following details during the setup wizard:"
echo "-----------------------------------------------"
echo "Database Type: SQLite3"
echo "Database Path: $GITEA_DIR/data/$GITEA_DB_NAME.sqlite3"
echo "Application Name: Gitea"
echo "Repository Root: $GITEA_DIR/data/gitea-repositories"
echo "Admin Username: $GITEA_ADMIN_USER"
echo "Admin Password: $GITEA_ADMIN_PASSWORD"
echo "-----------------------------------------------"
echo "Follow the setup wizard to complete the installation."
