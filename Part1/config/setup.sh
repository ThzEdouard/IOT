#!/bin/bash

echo "[+] Génération d'une clé SSH sans mot de passe..."
ssh-keygen -t rsa -N "" -f /home/vagrant/.ssh/id_rsa

echo "[+] Ajout de la clé publique aux clés autorisées..."
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

echo "[✔] SSH configuré avec succès !"
