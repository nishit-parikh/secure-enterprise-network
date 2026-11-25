#!/usr/bin/env bash
# Deliberately vulnerable practice apps on the backend host (10.10.30.22).
# Bound to the host's DMZ address only, and that host's firewall accepts these
# ports from the WAF alone. Never expose these apps to the Internet directly.
set -euo pipefail

sudo apt update && sudo apt install -y docker.io curl
sudo systemctl enable --now docker

docker pull vulnerables/web-dvwa
docker pull bkimminich/juice-shop

docker run -d --restart unless-stopped --name dvwa  -p 10.10.30.22:8080:80   vulnerables/web-dvwa
docker run -d --restart unless-stopped --name juice -p 10.10.30.22:3000:3000 bkimminich/juice-shop

docker ps --format 'table {{.Names}}\t{{.Ports}}'
