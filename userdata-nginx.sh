#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Update system
sudo apt-get update -y
sudo apt-get install -y nginx

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Simple index page
echo "<h1>Hello from Nginx on EC2</h1>" | sudo tee /var/www/html/index.html
