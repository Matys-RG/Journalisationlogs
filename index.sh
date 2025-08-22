#!/bin/bash

set -e

source ./01_bash_history.sh
source ./02_auditd_install.sh
source ./03_rsyslog_config.sh

if [[ "$EUID" -ne 0 ]]; then
    echo "Ce script doit être lancé en tant que root."
    echo "Utilisez : sudo $0"
    exit 1
fi

#Auditd part
echo "Installation d'auditd"

check_gestionnaire_paquet
maj
install_auditd
check_auditctl_version
enable_auditd

echo "Redémarrage de auditd"
if ! augenrules --load > /dev/null 2>&1; then
    echo "Échec lors du rechargement des règles auditd."
fi
systemctl restart auditd

echo "Configuration d'auditd terminée avec succès."

#Bash part
echo "Configuration de bash_history"
configure_bash_repertoire
configure_bash_file
configure_secure_bash_history
configure_root_history

#Rsyslog part
echo "Configuration de sshd et journalisation SSH avec rsyslog..."

install_sshd
configure_sshd
create_rsyslog_conf
comment_rsyslog_template
create_log_file

echo "Redémarrage de rsyslog..."
systemctl restart rsyslog

echo "Journalisation SSH configurée dans : $LOG_FILE"
echo "Configuration complète de la journalisation terminée avec succès !"
source /etc/profile.d/history.sh
