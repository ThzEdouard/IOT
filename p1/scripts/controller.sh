#!/bin/bash

SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/token"

echo "[+] Updating and installing prerequisites..."
DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends curl sshpass net-tools

echo "[+] Installing K3s in Server mode..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP} --disable traefik --disable servicelb" sh -

echo "[+] Parallel configuration..."
(
	mkdir -p /home/vagrant/.kube
	cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
	chown -R vagrant:vagrant /home/vagrant/.kube
	echo "export KUBECONFIG=/home/vagrant/.kube/config" >>/home/vagrant/.bashrc
) &

cat /var/lib/rancher/k3s/server/node-token >$TOKEN_FILE

wait

echo "[✔] Server installation completed!"
