#!/bin/bash

SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/config/token"

echo "[+] Mise à jour et installation des prérequis..."
apt-get update -y
apt-get install -y curl sshpass

echo "[+] Attente du token depuis le serveur..."
while [ ! -f "$TOKEN_FILE" ]; do
	echo "[-] En attente du token..."
	sleep 2
done

echo "[+] Récupération du token et connexion au serveur..."
TOKEN=$(cat "$TOKEN_FILE")
curl -sfL https://get.k3s.io | K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$TOKEN" sh -

echo "[✔] Installation de l'agent terminée !"
