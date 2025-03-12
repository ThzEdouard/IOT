#!/bin/bash

echo "[+] Mise à jour et installation des prérequis..."
apt-get update -y
apt-get install -y curl

echo "[+] Installation de K3s en mode Server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -

echo "[+] Configuration de kubectl pour l'utilisateur vagrant..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

echo "[+] Installation de Nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

echo "[+] Attente que l'Ingress Controller soit prêt..."
sleep 10
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "[+] Attente que l'Ingress Controller soit prêt..."
sleep 10
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "[+] Déploiement des applications..."
kubectl apply -f /vagrant/config/app1.yaml
kubectl apply -f /vagrant/config/app2.yaml
kubectl apply -f /vagrant/config/app3.yaml
kubectl apply -f /vagrant/config/ingress.yaml

echo "[✔] K3s, Ingress et applications déployés avec succès !"
