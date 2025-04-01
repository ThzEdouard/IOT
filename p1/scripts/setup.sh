#!/bin/bash

echo "[+] Generating SSH key without passphrase..."
ssh-keygen -t rsa -N "" -f /home/vagrant/.ssh/id_rsa

echo "[+] Adding public key to authorized keys..."
cat /home/vagrant/.ssh/id_rsa.pub >>/home/vagrant/.ssh/authorized_keys

echo "[✔] SSH configured successfully!"
