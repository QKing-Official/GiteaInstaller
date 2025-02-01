#!/bin/bash

# Gitea Docker Installation Script
# Version: 1.23.1

# Variables
GITEA_VERSION="1.23.1"  # Gitea version to install
GITEA_PORT="3000"  # Port for Gitea to run on
GITEA_DB_NAME="gitea_db"  # SQLite database name
GITEA_ADMIN_USER="admin"  # Admin username for Gitea
GITEA_ADMIN_PASSWORD="admin_password"  # Admin password for Gitea
GITEA_DATA_DIR="/var/lib/gitea"  # Directory for Gitea data
TAILSCALE_IP=$(tailscale ip -4)  # Get Tailscale IP

# Step 1: Create Gitea data directory
echo "Creating Gitea data directory..."
sudo mkdir -p $GITEA_DATA_DIR/{custom,data,log}
sudo chown -R $USER:$USER $GITEA_DATA_DIR
sudo chmod -R 750 $GITEA_DATA_DIR

# Step 2: Create Gitea configuration file
echo "Creating Gitea configuration file..."
sudo tee $GITEA_DATA_DIR/custom/conf/app.ini > /dev/null <<EOL
APP_NAME = Gitea
RUN_USER = git
RUN_MODE = prod

[server]
HTTP_PORT = $GITEA_PORT
DOMAIN = $TAILSCALE_IP
ROOT_URL = http://$TAILSCALE_IP:$GITEA_PORT/

[database]
DB_TYPE = sqlite3
HOST = localhost:3306
NAME = $GITEA_DB_NAME
PATH = $GITEA_DATA_DIR/data/$GITEA_DB_NAME.sqlite3

[repository]
ROOT = $GITEA_DATA_DIR/data/gitea-repositories

[session]
PROVIDER = file
PROVIDER_CONFIG = $GITEA_DATA_DIR/data/sessions

[log]
MODE = file
LEVEL = Info
ROOT_PATH = $GITEA_DATA_DIR/log
EOL

# Step 3: Run Gitea using Docker
echo "Running Gitea using Docker..."
docker run -d \
  --name=gitea \
  --restart=always \
  -p $GITEA_PORT:3000 \
  -v $GITEA_DATA_DIR:/data \
  -e USER_UID=$(id -u) \
  -e USER_GID=$(id -g) \
  gitea/gitea:$GITEA_VERSION

# Step 4: Display installation details
echo "Gitea installation complete!"
echo "Access Gitea at: http://$TAILSCALE_IP:$GITEA_PORT"
echo "Use the following details during the setup wizard:"
echo "-----------------------------------------------"
echo "Database Type: SQLite3"
echo "Database Path: $GITEA_DATA_DIR/data/$GITEA_DB_NAME.sqlite3"
echo "Application Name: Gitea"
echo "Repository Root: $GITEA_DATA_DIR/data/gitea-repositories"
echo "Admin Username: $GITEA_ADMIN_USER"
echo "Admin Password: $GITEA_ADMIN_PASSWORD"
echo "-----------------------------------------------"
echo "Follow the setup wizard to complete the installation."
