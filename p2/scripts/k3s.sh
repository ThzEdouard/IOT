#!/bin/bash

echo "[+] Updating and installing prerequisites..."
apt-get update -y
apt-get install -y curl

SERVER_IP="192.168.56.110"

echo "[+] Installing K3s in Server mode..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP}" sh -

echo "[+] Configuring kubectl for vagrant user..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
echo "export KUBECONFIG=/home/vagrant/.kube/config" >>/home/vagrant/.bashrc

echo "[+] Installing Nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

echo "[+] Waiting for Ingress Controller to be ready..."
sleep 10
kubectl wait --namespace ingress-nginx \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/component=controller \
	--timeout=90s

echo "[+] Waiting for Ingress Controller to be ready..."
sleep 10
kubectl wait --namespace ingress-nginx \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/component=controller \
	--timeout=90s

echo "[+] Deploying applications..."
kubectl apply -f /vagrant/confs/app1.yaml
kubectl apply -f /vagrant/confs/app2.yaml
kubectl apply -f /vagrant/confs/app3.yaml
kubectl apply -f /vagrant/confs/ingress.yaml

echo "[✔] K3s, Ingress and applications deployed successfully!"
