#!/bin/bash

set -e  # Exit on any error

# Install dependencies
echo "Installing dependencies..."
sudo apt update && sudo apt install -y curl wget git sqlite3 acl

echo "Dependencies installed."

# Install Tailscale
echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "Tailscale installation complete."

# Download and set up Gitea
GITEA_VERSION="1.23.1"
GITEA_BINARY="gitea-$GITEA_VERSION-linux-amd64"
GITEA_USER="gitea"
GITEA_GROUP="gitea"
GITEA_DIR="/srv/gitea"
GITEA_BIN="/usr/local/bin/gitea"

echo "Creating Gitea user and group..."
sudo adduser --system --group --disabled-login $GITEA_USER || true

echo "Creating necessary directories..."
sudo mkdir -p $GITEA_DIR/{custom,data,log}
sudo chown -R $GITEA_USER:$GITEA_GROUP $GITEA_DIR
sudo chmod -R 750 $GITEA_DIR

echo "Downloading Gitea version $GITEA_VERSION..."
wget -O gitea "https://dl.gitea.com/gitea/$GITEA_VERSION/$GITEA_BINARY"
sudo mv gitea $GITEA_BIN
sudo chmod +x $GITEA_BIN

# Create systemd service for Gitea
echo "Setting up Gitea service..."
cat <<EOF | sudo tee /etc/systemd/system/gitea.service
[Unit]
Description=Gitea
After=network.target

[Service]
RestartSec=2s
Type=simple
User=$GITEA_USER
Group=$GITEA_GROUP
WorkingDirectory=$GITEA_DIR
ExecStart=$GITEA_BIN web
Restart=always
Environment=USER=$GITEA_USER HOME=$GITEA_DIR

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now gitea

echo "Gitea installation complete. Access it via http://localhost:3000"
