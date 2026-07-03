#!/bin/bash
###############################################################################
# Game server (WorkAdventure) startup script.
# Installs Docker + Compose and deploys WorkAdventure's production stack using
# prebuilt images. The public domain is <external-ip>.sslip.io so that Traefik
# can obtain a real Let's Encrypt certificate (required for HTTPS/WebRTC) with
# no domain purchase.
###############################################################################
set -x
exec > /var/log/startup-script.log 2>&1
export DEBIAN_FRONTEND=noninteractive

MD="http://metadata.google.internal/computeMetadata/v1"
hdr="Metadata-Flavor: Google"

EXTERNAL_IP=$(curl -s -H "$hdr" "$MD/instance/network-interfaces/0/access-configs/0/external-ip")
ACME_EMAIL=$(curl -s -H "$hdr" "$MD/instance/attributes/acme-email")
WA_VERSION=$(curl -s -H "$hdr" "$MD/instance/attributes/wa-version")
DOMAIN="${EXTERNAL_IP}.sslip.io"

# --- Docker Engine ---
apt-get update
apt-get install -y ca-certificates curl gnupg openssl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# --- WorkAdventure production stack ---
install -d /opt/workadventure
cd /opt/workadventure
RAW="https://raw.githubusercontent.com/workadventure/workadventure/master/contrib/docker"
curl -fsSL "$RAW/docker-compose.prod.yaml" -o docker-compose.prod.yaml
curl -fsSL "$RAW/.env.prod.template" -o .env

SECRET_KEY=$(openssl rand -hex 32)
MAP_PW=$(openssl rand -hex 12)

sed -i "s|^DOMAIN=.*|DOMAIN=${DOMAIN}|" .env
sed -i "s|^SECRET_KEY=.*|SECRET_KEY=${SECRET_KEY}|" .env
sed -i "s|^ACME_EMAIL=.*|ACME_EMAIL=${ACME_EMAIL}|" .env
sed -i "s|^VERSION=.*|VERSION=${WA_VERSION}|" .env
sed -i "s|^MAP_STORAGE_AUTHENTICATION_USER=.*|MAP_STORAGE_AUTHENTICATION_USER=admin|" .env
sed -i "s|^MAP_STORAGE_AUTHENTICATION_PASSWORD=.*|MAP_STORAGE_AUTHENTICATION_PASSWORD=${MAP_PW}|" .env
sed -i "s|^DEBUG_MODE=.*|DEBUG_MODE=false|" .env

# Record the resolved values for later reference.
{
  echo "DOMAIN=${DOMAIN}"
  echo "URL=https://${DOMAIN}"
  echo "MAP_STORAGE_USER=admin"
  echo "MAP_STORAGE_PASSWORD=${MAP_PW}"
} > /opt/workadventure/DEPLOY_INFO.txt

docker compose -f docker-compose.prod.yaml up -d

echo "startup-script finished: domain=${DOMAIN}"
