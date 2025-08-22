#!/bin/bash

set -e

Required_Version="2.6.5"

check_gestionnaire_paquet() {
while true; do
    read -p "Quel gestionnaire de paquets utilisez-vous ? ( apt, yum, dnf ) :" paquet
    if [[ "$paquet" == "apt" ]] || [[ "$paquet" == "yum" ]] || [[ "$paquet" == "dnf" ]]; then
        break
    else
        echo "Veuillez entrer un gestionnaire de paquet valide"
    fi
done
}

maj() {
if [[ "$paquet" == "apt" ]]; then
    apt update && apt upgrade
elif [[ "$paquet" == "yum" ]]; then
    yum makecache
    yum update -y
elif [[ "$paquet" == "dnf" ]]; then
    dnf makecache
    dnf update -y
fi
}

install_auditd() {
echo "[1/4] Installation d'auditd"
if command -v auditctl &>/dev/null; then
    echo "Auditd est déjà installé"
else
    echo "Auditd n'est pas installé. Installation en cours..."
    if [[ "$paquet" == "apt" ]]; then
        apt update && apt install auditd -y
    elif [[ "$paquet" == "yum" ]]; then
        yum makecache fast && yum install -y auditd
    elif [[ "$paquet" == "dnf" ]]; then
        dnf makecache
        dnf update && dnf install -y auditd
    fi
fi
}


check_auditctl_version() {
echo "[2/4] Vérification de la version d'auditctl"
local Current_Version=$( ( auditctl -v | awk '{print $NF}' ) )
if [[ "$(printf '%s\n' "$Required_Version" "$Current_Version" | sort -V | head -n1)" != "$Required_Version" ]]; then
    if [[ "$paquet" == "apt" ]]; then
        apt update
    elif [[ "$paquet" == "yum" ]]; then
            yum makecache
            yum update -y
    elif [[ "$paquet" == "dnf" ]]; then
        dnf makecache
        dnf update -y
    fi
fi

echo "Version requise : $Required_Version | Version actuelle : $Current_Version"
}


enable_auditd() {
-a always,exit -F arch=b64 -S execve -F auid>=1000 -F auid!=4294967295 -k user_commands
-a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands
echo "[3/4] Activation d'auditd"
systemctl enable auditd
systemctl start auditd
}
