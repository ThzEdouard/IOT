#!/bin/bash

SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/config/token"

echo "[+] Mise à jour et installation des prérequis..."
apt-get update -y
apt-get install -y curl sshpass net-tools

echo "[+] Installation de K3s en mode Server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP}" sh -

echo "[+] Configuration de kubectl pour l'utilisateur vagrant..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

echo "[+] Sauvegarde du token pour les agents..."
cat /var/lib/rancher/k3s/server/node-token > $TOKEN_FILE

echo "[✔] Installation du serveur terminée !"