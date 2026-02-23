#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (use sudo)"
  exit
fi

echo "--- Updating system and installing dependencies ---"
apt-get update && apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg lsb-release

echo "--- Adding Docker's official GPG key ---"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "--- Setting up the Docker repository ---"
echo \
  "座eb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
  $(. /etc/os-release; echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "--- Installing Docker Engine ---"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ensure Docker starts on boot
systemctl enable docker
systemctl start docker

echo "--- Pulling and starting Nextcloud AIO ---"
# This command starts the AIO master container. 
# It will be accessible at https://<your-local-ip>:8080
docker run \
--sig-proxy=false \
--name nextcloud-aio-mastercontainer \
--restart always \
--publish 80:80 \
--publish 8080:8080 \
--publish 443:443 \
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
-d nextcloud/all-in-one:latest

echo "-------------------------------------------------------"
echo "Installation complete!"
echo "Open your browser and go to: https://$(hostname -I | awk '{print $1}'):8080"
echo "to finish the setup via the Nextcloud AIO interface."
echo "-------------------------------------------------------"
