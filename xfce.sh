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

echo ""
## Téléchargement et installation du fond d'écran
info_msg "Téléchargement du fond d'écran..."
execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png > /dev/null 2>&1" \
    "Fond d'écran téléchargé avec succès." \
    "Échec du téléchargement du fond d'écran."

execute_command "mkdir -p /usr/share/backgrounds/xfce/" \
    "Dossier de fond d'écran créé." \
    "Échec de la création du dossier de fond d'écran."

execute_command "sudo mv waves.png /usr/share/backgrounds/xfce/ > /dev/null 2>&1" \
    "Fond d'écran installé avec succès." \
    "Échec de l'installation du fond d'écran."

echo ""
## Installation de WhiteSur-Dark
info_msg "Installation WhiteSur-Dark..."
execute_command "wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip > /dev/null 2>&1" \
    "Archive WhiteSur-Dark téléchargée." \
    "Échec du téléchargement de WhiteSur-Dark."

execute_command "unzip 2024.09.02.zip && tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz && sudo mv WhiteSur-Dark/ /usr/share/themes/ && sudo rm -rf WhiteSur* && sudo rm 2024.09.02.zip" \
    "WhiteSur-Dark installé avec succès." \
    "Échec de l'installation de WhiteSur-Dark."

echo ""
## Installation de Fluent Cursor
info_msg "Installation Fluent Cursor..."
execute_command "wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip > /dev/null 2>&1" \
    "Archive Fluent Cursor téléchargée." \
    "Échec du téléchargement de Fluent Cursor."

execute_command "unzip 2024-02-25.zip && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/ && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/ && sudo rm -rf $HOME/Fluent* && sudo rm 2024-02-25.zip" \
    "Fluent Cursor installé avec succès." \
    "Échec de l'installation de Fluent Cursor."