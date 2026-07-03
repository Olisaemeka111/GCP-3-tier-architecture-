#!/bin/bash
###############################################################################
# Backend tier startup script.
# Installs Docker Engine and runs Jenkins (CI) as a Docker container on every
# backend instance.
#
# Jenkins runs in Docker (jenkins/jenkins:lts-jdk17) rather than the native apt
# package, which avoids the pkg.jenkins.io apt-key/repo-signing issues and is
# more reproducible. It listens on 8080 (the backend tier's exposed / health-
# checked port); the health check targets "/login" (Jenkins returns 403 on "/").
# Egress for image pulls is via Cloud NAT (instances have no public IP).
###############################################################################
set -x
exec > /var/log/startup-script.log 2>&1
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg

# --- Docker Engine (official repository) ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# --- Jenkins as a Docker container ---
# Mount the host Docker socket so Jenkins pipelines can build/run containers.
docker volume create jenkins_home
docker run -d --name jenkins --restart unless-stopped \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17

echo "startup-script finished: docker=$(docker --version 2>/dev/null) jenkins_container=$(docker ps --filter name=jenkins --format '{{.Status}}' 2>/dev/null)"
