


Log pour commandes user : sudo cat /var/log/logger.log
Log pour commandes root : sudo cat /var/log/bash/root.history

Log pour connexions :
sudo grep 'sshd' /var/log/auth.log
sudo grep 'sudo' /var/log/auth.log
sudo grep 'session' /var/log/auth.log

Log pour surveiller l'accès et les modifs au fichier contenant les mdp chiffrés / détecter un dump ou une altération des hashes : sudo ausearch -k shadow_file
Log pour voir les modifications dans la table des utilisateurs système : sudo ausearch -k passwd_changes
Log pour surveiller les écritures et attributs sur le fichier sudoers / voir les modifications de privilèges : sudo ausearch -k sudoers_change
Log pour surveiller les fichiers de config PAM (Authentification Linux) / Détecter une tentative de backdoor via PAM : sudo ausearch -k pam_config

