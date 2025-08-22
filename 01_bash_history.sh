#!/bin/bash

set -e

# Configuration sécurisée de l'historique Bash

configure_bash_repertoire(){
while true; do
read -p "Donnez le chemin absolu pour le répertoire de logs bash sécurisés (exemple : /var/log/bash)" HISTORY_DIR
[ -n "$HISTORY_DIR" ] && break || echo "veuillez entrer un chemin valide"
done
}

configure_bash_file(){
while true; do
read -p "Donnez le chemin absolu pour le fichier de sortie des logs (exemple : /var/log/bash/$(whoami).history)" HISTORY_FILE
[ -n "$HISTORY_FILE" ] && break || echo "Veuillez entrer un chemin valide"
done
}

configure_secure_bash_history() {
    echo "[1/2] Création du répertoire de logs Bash sécurisé : $HISTORY_DIR"
    mkdir -p "$HISTORY_DIR"
    chown root:adm "$HISTORY_DIR"
    chmod 750 "$HISTORY_DIR"

    echo "[2/2] Configuration de l'historique Bash de l'utilisateur $(whoami)"

if ! grep -q "$HISTORY_FILE" /etc/profile.d/history.sh 2>/dev/null; then
cat <<EOF >> /etc/profile.d/history.sh
    echo "Chargement profile.d/history.sh OK"
    export HISTFILE="$HISTORY_FILE"
    export HISTTIMEFORMAT='%F %T '
    export HISTSIZE=10000
    export HISTFILESIZE=20000
    export HISTCONTROL=ignoredups
    shopt -s histappend
    export PROMPT_COMMAND='history -a; history -n; logger -p local1.notice -t bash -i -- "$(date "+%F %T") $(whoami)@$(hostname):$(tty): $(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//")"'
EOF
fi
    
    chmod 644 /etc/profile.d/history.sh
    chown root:root /etc/profile.d/history.sh

    # Protection du fichier d'historique
    touch "$HISTORY_FILE"
    chown root:root "$HISTORY_FILE"
    chmod 600 "$HISTORY_FILE"
    
    if ! command -v chattr &>/dev/null; then
        if [[ "$paquet" == "apt" ]]; then
            apt install -y e2fsprogs
        elif [[ "$paquet" == "yum" ]]; then
            yum install -y e2fsprogs
        elif [[ "$paquet" == "dnf" ]]; then
            dnf install -y e2fsprogs
        fi
    fi

    if command -v chattr &>/dev/null; then
        chattr +a "$HISTORY_FILE" || echo "chattr +a non supporté"
        echo "Historique Bash sécurisé, configuré pour $(whoami) et verrouillé dans : $HISTORY_FILE"   
    else
        echo "Impossible d'appliquer chattr. Protection partielle uniquement par chmod/chown."
    fi
}

configure_root_history() {
HISTORY_SCRIPT="/etc/profile.d/history.sh"

if [ ! -f "$HISTORY_SCRIPT" ]; then
    echo "$HISTORY_SCRIPT n'existe pas."
    exit 1
fi


ROOT_BASHRC="/root/.bashrc"
LINE_TO_ADD='[ -f /etc/profile.d/history.sh ] && source /etc/profile.d/history.sh'

if ! grep -Fxq "$LINE_TO_ADD" "$ROOT_BASHRC"; then
    echo "$LINE_TO_ADD" >> "$ROOT_BASHRC"
fi

ROOT_BASHPROFILE="/root/.bash_profile"
if ! grep -Fxq "[ -f /etc/profile.d/history.sh ]" "$ROOT_BASHPROFILE"; then
    echo "[ -f /etc/profile.d/history.sh ]" >> "$ROOT_BASHPROFILE"
fi
}

configure_rsyslog() {
    echo "local1.* /var/log/logger.log" >> /etc/rsyslog.d/logger.conf
    touch /var/log/logger.log
    chown syslog:adm /var/log/logger.log
    chmod 640 /var/log/logger.log
    systemctl restart rsyslog
}
