#!/bin/bash

echo ""
## Téléchargement et installation du fond d'écran
echo -e "\e[38;5;33mTéléchargement du fond d'écran...\e[0m"
wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png > /dev/null 2>&1
mkdir -p /usr/share/backgrounds/xfce/
sudo mv waves.png /usr/share/backgrounds/xfce/ > /dev/null 2>&1

echo ""
## Installation de WhiteSur-Dark
echo -e "\e[38;5;33mInstallation WhiteSur-Dark...\e[0m"
wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip > /dev/null 2>&1
{
    unzip 2024.09.02.zip
    tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz
    sudo mv WhiteSur-Dark/ /usr/share/themes/
    sudo rm -rf WhiteSur*
    sudo rm 2024.09.02.zip
} > /dev/null 2>&1

echo ""
## Installation de Fluent Cursor
echo -e "\e[38;5;33mInstallation Fluent Cursor...\e[0m"
wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip > /dev/null 2>&1
{
    unzip 2024-02-25.zip
    sudo mv Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/
    sudo mv Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/
    sudo rm -rf $HOME/Fluent*
    sudo rm 2024-02-25.zip
} > /dev/null 2>&1