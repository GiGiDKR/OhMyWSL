#!/bin/bash

# Création du fichier .wslconfig
wslconfig_file="/mnt/c/Users/$USER/.wslconfig"
content="[wsl2]
guiApplications=false
[network]
generateResolvConf = false"

echo -e "$content" | tr -d '\r' > "$wslconfig_file"

if [ -f "$wslconfig_file" ]; then
    echo "Le fichier .wslconfig a été créé avec succès."
else
    echo "Erreur lors de la création du fichier .wslconfig."
    exit 1
fi

## Installation des paquets
packages="xfce4 xfce4-goodies gdm3 xwayland nautilus ark"

packages_install() {
    echo "Installation de $1..."
    if sudo DEBIAN_FRONTEND=noninteractive apt install -y "$1" > /dev/null 2>&1; then
        echo "✓ $1 installé avec succès."
    else
        echo "✗ Échec de l'installation de $1."
    fi
    echo ""
}

echo "Mise à jour des listes de paquets..."
sudo apt update > /dev/null 2>&1

for package in $packages; do
    packages_install "$package"
done

## Configuration réseau
ip_address=$(ip route | grep default | awk '{print $3; exit;}')

if [ -z "$ip_address" ]; then
    echo "Erreur : Impossible de récupérer l'adresse IP."
    exit 1
fi

resolv_conf="/etc/resolv.conf"

if [ ! -f "$resolv_conf" ]; then
    echo "Erreur : Le fichier $resolv_conf n'existe pas."
    exit 1
fi

sudo sed -i "s/^nameserver.*/& ${ip_address}:0.0/" "$resolv_conf"

echo "Le fichier $resolv_conf a été mis à jour avec succès."

## Configuration des fichiers de shell
bashrc_path="$HOME/.bashrc"
zshrc_path="$HOME/.zshrc"

lines_to_add='
export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}"):0.0
export PULSE_SERVER=tcp:$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}")'

add_lines_to_file() {
    if [ -f "$1" ]; then
        echo "$lines_to_add" >> "$1"
        echo "Les lignes ont été ajoutées à $1"
    else
        echo "Le fichier $1 n'existe pas."
    fi
}

add_lines_to_file "$bashrc_path"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path"

echo "Fichier(s) de configuration shell mis à jour avec succès."

## Installation de GWSL
wget https://archive.org/download/gwsl-145-store/GWSL-145-STORE.zip
unzip GWSL-145-STORE.zip
mv GWSL-145-STORE GWSL
mkdir -p /mnt/c/WSL2-Distros
mv GWSL /mnt/c/WSL2-Distros/
echo "GWSL installé avec succès."

## Configuration de XFCE4
execute_command() {
    echo "Exécution de : $1"
    eval "$1"
    echo ""
}

echo "Démarrage de XFCE4..."
timeout 5s sudo startxfce4 &> /dev/null
echo "XFCE4 fermé après 5 secondes."
echo ""

execute_command "mkdir -p $HOME/.config/xfce4"
execute_command "cp /etc/xdg/xfce4/xinitrc $HOME/.config/xfce4/xinitrc"
execute_command "touch $HOME/.ICEauthority"
execute_command "chmod 600 $HOME/.ICEauthority"
execute_command "sudo mkdir -p /run/user/$UID"
execute_command "sudo chown -R $UID:$UID /run/user/$UID/"
execute_command "echo 'echo \$DISPLAY' >> $HOME/.bashrc"


## Téléchargement du fond d'écran
echo -e "\e[38;5;33mTéléchargement du fond d'écran...\e[0m"
wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png > /dev/null 2>&1

mkdir -p /usr/share/backgrounds/xfce/
sudo mv waves.png /usr/share/backgrounds/xfce/ > /dev/null 2>&1

## Installation de WhiteSur-Dark
echo -e "\e[38;5;33mInstallation de WhiteSur-Dark...\e[0m"
wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip > /dev/null 2>&1
{
    unzip 2024.09.02.zip
    tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz
    sudo mv WhiteSur-Dark/ /usr/share/themes/
    sudo rm -rf WhiteSur*
    sudo rm 2024.09.02.zip
} > /dev/null 2>&1

## Installation de Fluent Cursor
echo -e "\e[38;5;33mInstallation de Fluent Cursor...\e[0m"
wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip > /dev/null 2>&1
{
    unzip 2024-02-25.zip
    sudo mv Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/
    sudo mv Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/
    sudo rm -rf $HOME/Fluent*
    sudo rm 2024-02-25.zip
} > /dev/null 2>&1

## Lancement de la session XFCE4
echo "Lancement de la session XFCE4..."
dbus-launch xfce4-session &

echo "Démarrage de GWSL..."
/mnt/c/WSL2-Distros/GWSL/GWSL.exe