#!/bin/bash

SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/token"
AGENT_IP="192.168.56.111"

echo "[+] Updating and installing prerequisites..."
DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends curl sshpass net-tools

echo "[+] Waiting for token from server..."

while [ ! -f "$TOKEN_FILE" ]; do
	echo "[-] Waiting for token..."
	sleep 5
done

echo "[+] Retrieving token and connecting to server..."

TOKEN=$(cat "$TOKEN_FILE")
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --node-ip=${AGENT_IP}" K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$TOKEN" sh -

echo "[✔] Agent installation completed!"
