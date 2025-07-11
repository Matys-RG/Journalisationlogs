#!/bin/bash

set -e

Required_Version="2.6.5"

#Aller chercher le gestionnaire de paquet dans /var/bin/ au lieu de la distribution

# check_distro() {
# echo "[1/5] Détection de la distribution"
# if [ -f /etc/os-release ]; then
#     DISTRO=$( ( . /etc/os-release && echo "$ID" ) )
#     echo "Distibution trouvée."
# else
#     echo "Distribution non trouvée."
#     exit 1
# fi

# if [[ "$DISTRO" != "debian" && "$DISTRO" != "ubuntu" && "$DISTRO" != "centos" && "$DISTRO" != "rhel" ]]; then
#     echo "Mauvaise distribution"
#     exit 1
# else
#     echo "Distribution conforme"
# fi
# }

# install_auditctl() {
# echo "[2/5] Installation d'auditctl"
# if command -v auditctl &>/dev/null; then
#     echo "Auditctl est déjà installé"
# else
#     echo "Auditctl n'est pas installé. Installation en cours..."
#     if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
#         apt update && apt install auditctl -y
#     elif [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]]; then
#         if command -v dnf &>/dev/null; then
#             dnf makecache
#             dnf update && dnf install -y audit
#         else
#             yum makecache fast && yum install -y audit
#         fi
#     fi
# fi
# }

# check_auditctl_version() {
# echo "[3/5] Vérification de la version d'auditctl"
# local Current_Version=$( ( auditctl -v | awk '{print $NF}' ) )
# if [[ "$(printf '%s\n' "$Required_Version" "$Current_Version" | sort -V | head -n1)" != "$Required_Version" ]]; then
#     if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
#         apt update
#     elif [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]]; then
#         if command -v dnf &>/dev/null; then
#             dnf makecache
#             dnf update -y
#         else
#             yum makecache
#             yum update -y
#         fi
#     fi
# fi
# }

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
echo "[3/4] Activation d'auditd"
systemctl enable auditd
systemctl start auditd
}

apply_rules() {
echo "[4/4] Application des règles de base..."
# Voir quels fichiers systèmes critiques il faut surveiller
cat <<EOF > /etc/audit/rules.d/basic.rules
-w /etc/sudoers -p wa -k sudoers_change
-w /etc/shadow -p wa -k shadow_file
-w /etc/pam.d/ -p wa -k pam_config
-w /etc/passwd -p wa -k passwd_changes
-a always,exit -F path=/bin -F perm=x -F auid>=1000 -F auid!=4294967295 -k bin_exec

EOF
}
