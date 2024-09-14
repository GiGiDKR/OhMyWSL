#!/bin/bash

# Fonction pour afficher des messages d'information
info_msg() {
    echo -e "\e[38;5;33m$1\e[0m"
}

# Fonction pour afficher des messages d'erreur
error_msg() {
    echo -e "\e[38;5;196m$1\e[0m"
}

sudo -v

# Création du fichier .wslconfig
wslconfig_file="/mnt/c/Users/$USER/.wslconfig"
content="[wsl2]
guiApplications=false
[network]
generateResolvConf = false"

echo -e "$content" | tr -d '\r' > "$wslconfig_file"

if [ -f "$wslconfig_file" ]; then
    info_msg "Le fichier .wslconfig a été créé avec succès."
else
    error_msg "Erreur lors de la création du fichier .wslconfig."
    exit 1
fi

## Installation des paquets
packages="xfce4 xfce4-goodies gdm3 xwayland nautilus ark"

packages_install() {
    info_msg "Installation de $1..."
    if sudo DEBIAN_FRONTEND=noninteractive apt install -y "$1" > /dev/null 2>&1; then
        info_msg "✓ $1 installé avec succès."
    else
        error_msg "✗ Échec de l'installation de $1."
    fi
    echo ""
}

info_msg "Mise à jour des listes de paquets..."
sudo apt update -y && sudo apt upgrade -y > /dev/null 2>&1

for package in $packages; do
    packages_install "$package"
done

# Installation de ZSH
info_msg "Installer zsh ? (oui/non)"
read reponse_zsh

reponse_zsh=$(echo "$reponse_zsh" | tr '[:upper:]' '[:lower:]')

if [ "$reponse_zsh" = "oui" ] || [ "$reponse_zsh" = "o" ] || [ "$reponse_zsh" = "y" ] || [ "$reponse_zsh" = "yes" ]; then
    wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/main/zsh.sh
    chmod +x zsh.sh
    info_msg "Exécution de zsh.."
    ./zsh.sh
else
    info_msg "Installation de zsh refusée."
fi

## Configuration réseau
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

sudo sed -i "s/^nameserver.*/& ${ip_address}:0.0/" "$resolv_conf"

info_msg "Le fichier $resolv_conf a été mis à jour avec succès."

## Configuration des fichiers de shell
bashrc_path="$HOME/.bashrc"
zshrc_path="$HOME/.zshrc"

lines_to_add='
export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}"):0.0
export PULSE_SERVER=tcp:$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}")
echo $DISPLAY'


add_lines_to_file() {
    if [ -f "$1" ]; then
        echo "$lines_to_add" >> "$1"
        info_msg "Les lignes ont été ajoutées à $1"
    else
        error_msg "Le fichier $1 n'existe pas."
    fi
}

add_lines_to_file "$bashrc_path"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path"

info_msg "Fichier(s) de configuration shell mis à jour avec succès."

## Installation de GWSL
if wget https://archive.org/download/gwsl-145-store/GWSL-145-STORE.zip; then
    if unzip GWSL-145-STORE.zip; then
        mv GWSL-145-STORE GWSL
        mkdir -p /mnt/c/WSL2-Distros
        mv GWSL /mnt/c/WSL2-Distros/
        info_msg "GWSL installé avec succès."
    else
        error_msg "Erreur lors de l'extraction de GWSL."
        exit 1
    fi
else
    error_msg "Erreur lors du téléchargement de GWSL."
    exit 1
fi

## Configuration de XFCE4
execute_command() {
    info_msg "Exécution de : $1"
    eval "$1"
    echo ""
}

info_msg "Démarrage de XFCE4..."
timeout 5s sudo startxfce4 &> /dev/null
info_msg "XFCE4 fermé après 5 secondes."
echo ""

execute_command "mkdir -p $HOME/.config/xfce4"
execute_command "cp /etc/xdg/xfce4/xinitrc $HOME/.config/xfce4/xinitrc"
execute_command "touch $HOME/.ICEauthority"
execute_command "chmod 600 $HOME/.ICEauthority"
execute_command "sudo mkdir -p /run/user/$UID"
execute_command "sudo chown -R $UID:$UID /run/user/$UID/"
execute_command "echo 'echo \$DISPLAY' >> $HOME/.bashrc"

# Personnalisation XFCE
info_msg "Installer la personnalisation XFCE ? (oui/non)"
read reponse

reponse=$(echo "$reponse" | tr '[:upper:]' '[:lower:]')

if [ "$reponse" = "oui" ] || [ "$reponse" = "o" ] || [ "$reponse" = "y" ] || [ "$reponse" = "yes" ]; then
    # XFCE script
    wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/main/xfce.sh
    chmod +x xfce.sh
    info_msg "Exécution de la personnalisation XFCE..."
    ./xfce.sh
else
    info_msg "Installation de la personnalisation XFCE refusée."
fi

## Lancement de la session XFCE4
info_msg "Lancement de la session XFCE4..."
dbus-launch xfce4-session