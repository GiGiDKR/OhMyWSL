#!/bin/bash

# Fonction pour afficher des messages d'information en bleu
info_msg() {
    echo -e "\e[38;5;33m$1\e[0m"
}

# Fonction pour afficher des messages de succès en vert
success_msg() {
    echo -e "\e[38;5;82m$1\e[0m"
}

# Fonction pour afficher des messages d'erreur en rouge
error_msg() {
    echo -e "\e[38;5;196m$1\e[0m"
}

# Fonction pour exécuter une commande et afficher le résultat
execute_command() {
    local command="$1"
    local success_msg="$2"
    local error_msg="$3"

    if eval "$command" > /dev/null 2>&1; then
        success_msg "✓ $success_msg"
    else
        error_msg "✗ $error_msg"
        return 1
    fi
}

clear
sudo -v

# Création du fichier .wslconfig
wslconfig_file="/mnt/c/Users/$USER/.wslconfig"
content="[wsl2]
guiApplications=false
[network]
generateResolvConf = false"

clear
info_msg "Création du fichier .wslconfig..."
execute_command "echo -e \"$content\" | tr -d '\r' > \"$wslconfig_file\"" \
    "Le fichier .wslconfig a été créé." \
    "Erreur lors de la création du fichier .wslconfig."

info_msg "----------------------------------------"

## Installation des paquets
packages="xfce4 xfce4-goodies gdm3 xwayland nautilus ark"

info_msg "Mise à jour des listes de paquets..."
execute_command "sudo apt update -y" \
    "Mise à jour des listes de paquets réussie." \
    "Échec de la mise à jour des listes de paquets."

info_msg "Mise à jour des paquets..."
execute_command "sudo apt upgrade -y" \
    "Mise à jour des paquets réussie." \
    "Échec de la mise à jour des paquets."

info_msg "----------------------------------------"

for package in $packages; do
    info_msg "Installation de $package..."
    execute_command "sudo apt install -y $package" \
        "$package installé." \
        "Échec de l'installation de $package."
done

info_msg "----------------------------------------"
# Installation de ZSH
read -p "Installer zsh ? (o/n)" reponse_zsh

reponse_zsh=$(echo "$reponse_zsh" | tr '[:upper:]' '[:lower:]')

if [ "$reponse_zsh" = "oui" ] || [ "$reponse_zsh" = "o" ] || [ "$reponse_zsh" = "y" ] || [ "$reponse_zsh" = "yes" ]; then
    execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh" \
        "Script zsh.sh téléchargé." \
        "Échec du téléchargement du script zsh.sh."
    execute_command "chmod +x zsh.sh" \
        "Permissions du script zsh.sh modifiées." \
        "Échec de la modification des permissions du script zsh.sh."
#    info_msg "Exécution de zsh..."
    "$HOME/zsh.sh"  # Exécution directe du script
    if [ $? -eq 0 ]; then
        success_msg "Installation de zsh terminée."
    else
        error_msg "Échec de l'installation de zsh."
    fi
else
    info_msg "Installation de zsh refusée."
fi

info_msg "----------------------------------------"
## Configuration réseau
info_msg "Configuration du réseau..."
ip_address=$(ip route | grep default | awk '{print $3; exit;}')

if [ -z "$ip_address" ]; then
    error_msg "Erreur : Impossible de récupérer l'adresse IP."
    exit 1
fi

resolv_conf="/etc/resolv.conf"

if [ ! -f "$resolv_conf" ]; then
    error_msg "Erreur : Le fichier $resolv_conf n'existe pas."
    exit 1
fi

info_msg "Mise à jour du fichier $resolv_conf..."
execute_command "sudo sed -i \"s/^nameserver.*/& ${ip_address}:0.0/\" \"$resolv_conf\"" \
    "Le fichier $resolv_conf a été mis à jour." \
    "Erreur lors de la mise à jour de $resolv_conf."

info_msg "----------------------------------------"
## Configuration des fichiers de shell
bashrc_path="$HOME/.bashrc"
zshrc_path="$HOME/.zshrc"

lines_to_add='
export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}"):0.0
export PULSE_SERVER=tcp:$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}")
echo $DISPLAY'

add_lines_to_file() {
    if [ -f "$1" ]; then
        execute_command "echo \"$lines_to_add\" >> \"$1\"" \
            "Les lignes ont été ajoutées à $1" \
            "Erreur lors de l'ajout des lignes à $1"
    else
        error_msg "Le fichier $1 n'existe pas."
    fi
}

add_lines_to_file "$bashrc_path"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path"

success_msg "Fichier(s) de configuration shell mis à jour."

info_msg "----------------------------------------"
## Installation de GWSL
info_msg "Téléchargement de GWSL..."
execute_command "wget https://archive.org/download/gwsl-145-store/GWSL-145-STORE.zip" \
    "GWSL téléchargé." \
    "Erreur lors du téléchargement de GWSL."

execute_command "unzip GWSL-145-STORE.zip" \
    "GWSL extrait." \
    "Erreur lors de l'extraction de GWSL."

execute_command "mv GWSL-145-STORE GWSL" \
    "Dossier GWSL renommé." \
    "Erreur lors du renommage du dossier GWSL."

execute_command "mkdir -p /mnt/c/WSL2-Distros" \
    "Dossier WSL2-Distros créé." \
    "Erreur lors de la création du dossier WSL2-Distros."

execute_command "mv GWSL /mnt/c/WSL2-Distros/" \
    "GWSL déplacé dans WSL2-Distros." \
    "Erreur lors du déplacement de GWSL."

info_msg "----------------------------------------"
## Configuration de XFCE4
#info_msg "Démarrage de XFCE4..."
#execute_command "timeout 5s sudo startxfce4 &> /dev/null" \
#    "XFCE4 fermé après 5 secondes." \
#    "Erreur lors du démarrage de XFCE4."

info_msg "Configuration de XFCE4..."
execute_command "mkdir -p $HOME/.config/xfce4" \
    "Dossier de configuration XFCE4 créé." \
    "Erreur lors de la création du dossier de configuration XFCE4."

execute_command "cp /etc/xdg/xfce4/xinitrc $HOME/.config/xfce4/xinitrc" \
    "Fichier xinitrc copié." \
    "Erreur lors de la copie du fichier xinitrc."

execute_command "touch $HOME/.ICEauthority" \
    "Fichier .ICEauthority créé." \
    "Erreur lors de la création du fichier .ICEauthority."

execute_command "chmod 600 $HOME/.ICEauthority" \
    "Permissions du fichier .ICEauthority modifiées." \
    "Erreur lors de la modification des permissions du fichier .ICEauthority."

execute_command "sudo mkdir -p /run/user/$UID" \
    "Dossier /run/user/$UID créé." \
    "Erreur lors de la création du dossier /run/user/$UID."

execute_command "sudo chown -R $UID:$UID /run/user/$UID/" \
    "Propriétaire du dossier /run/user/$UID modifié." \
    "Erreur lors de la modification du propriétaire du dossier /run/user/$UID."

execute_command "echo 'echo \$DISPLAY' >> $HOME/.bashrc" \
    "Commande d'affichage de DISPLAY ajoutée à .bashrc." \
    "Erreur lors de l'ajout de la commande d'affichage de DISPLAY à .bashrc."

info_msg "----------------------------------------"
# Personnalisation XFCE
read -p "Installer la personnalisation XFCE ? (o/n)" reponse

reponse=$(echo "$reponse" | tr '[:upper:]' '[:lower:]')

if [ "$reponse" = "oui" ] || [ "$reponse" = "o" ] || [ "$reponse" = "y" ] || [ "$reponse" = "yes" ]; then
    if [ -f "$HOME/xfce.sh" ]; then
        echo "Exécution de la personnalisation XFCE..."
        "$HOME/xfce.sh"  # Exécution directe du script
        if [ $? -eq 0 ]; then
            success_msg "Personnalisation XFCE terminée."
        else
            error_msg "Erreur lors de l'exécution de la personnalisation XFCE."
        fi
    else
        error_msg "Erreur : Le fichier xfce.sh n'existe pas."
    fi
else
    info_msg "Installation de la personnalisation XFCE refusée."
fi

info_msg "----------------------------------------"
## Lancement de la session XFCE4
info_msg "Lancement de la session XFCE4..."
execute_command "dbus-launch xfce4-session" \
    "Session XFCE4 lancée." \
    "Échec du lancement de la session XFCE4."

