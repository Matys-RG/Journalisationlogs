#!/bin/bash

set -e

SSHD_CONFIG="/etc/ssh/sshd_config"
LOG_FILE="/var/log/secure"
RSYSLOG_CONF="/etc/rsyslog.conf"

install_sshd(){
echo "[1/4] Installation de sshd"
if ! command -v sshd >/dev/null; then
    echo "Serveur SSH absent, tentative d'installation..."
    
    if [[ "$paquet" == "apt" ]]; then
        apt install -y openssh-server
    elif [[ "$paquet" == "dnf" ]]; then
        dnf install -y openssh-server
    elif [[ "$paquet" == "yum" ]]; then
        yum install -y openssh-server
    else
        echo "Aucun gestionnaire de paquets compatible trouvé."
        exit 1
    fi
else
    echo "sshd est déjà présent"
fi
}

configure_sshd(){
echo "[1/4] Configuration de sshd pour LogLevel VERBOSE"
if grep -q "^#*LogLevel" "$SSHD_CONFIG"; then
    sed -i 's/^#*LogLevel.*/LogLevel VERBOSE/' "$SSHD_CONFIG"
else
    echo "LogLevel VERBOSE" >> "$SSHD_CONFIG"
fi

echo "Redémarrage de sshd..."
systemctl restart ssh
}

create_rsyslog_conf(){
echo "[2/4] Création d’un fichier de configuration rsyslog dédié à SSH"
echo "Création de la configuration rsyslog pour SSH dans $RSYSLOG_CONF"

if ! grep -q "^authpriv.*[[:space:]]\+$LOG_FILE" "$RSYSLOG_CONF"; then
    echo "Ajout de la configuration rsyslog pour SSH..."
    cat <<EOF >> "$RSYSLOG_CONF"
authpriv.*    $LOG_FILE

EOF
else
    echo "La configuration rsyslog SSH existe déjà dans $RSYSLOG_CONF"
fi
}

comment_rsyslog_template(){
echo "[3/4] Commenter la ligne ActionFileDefaultTemplate si elle est active"
if grep -q "^\$ActionFileDefaultTemplate" "$RSYSLOG_CONF"; then
    sed -i 's/^\$ActionFileDefaultTemplate/#$ActionFileDefaultTemplate/' "$RSYSLOG_CONF"
    echo "Rsyslog commenté dans $RSYSLOG_CONF"
fi
}

create_log_file(){
echo "[4/4] S'assurer que le fichier log existe"
touch "$LOG_FILE"
chown syslog:adm "$LOG_FILE"
}
