#!/bin/bash

USE_GUM=false

# Fonction pour afficher des messages d'information en bleu
info_msg() {
    if $USE_GUM; then
        gum style --foreground 33 "$1"
    else
        echo -e "\e[38;5;33m$1\e[0m"
    fi
}

# Fonction pour afficher des messages de succès en vert
success_msg() {
    if $USE_GUM; then
        gum style --foreground 82 "$1"
    else
        echo -e "\e[38;5;82m$1\e[0m"
    fi
}

# Fonction pour afficher des messages d'erreur en rouge
error_msg() {
    if $USE_GUM; then
        gum style --foreground 196 "$1"
    else
        echo -e "\e[38;5;196m$1\e[0m"
    fi
}

# Fonction pour exécuter une commande et afficher le résultat
execute_command() {
    local command="$1"
    local success_msg="$2"
    local error_msg="$3"

    if $USE_GUM; then
        if gum spin --spinner dot --title "$2" -- eval "$command" > /dev/null 2>&1; then
            gum style --foreground 82 "✓ $success_msg"
        else
            gum style --foreground 196 "✗ $error_msg"
            return 1
        fi
    else
        if eval "$command" > /dev/null 2>&1; then
            success_msg "✓ $success_msg"
        else
            error_msg "✗ $error_msg"
            return 1
        fi
    fi
}

# Traitement des arguments en ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true ;;
        *) error_msg "Option non reconnue : $1" ;;
    esac
    shift
done

# Modification des interactions utilisateur pour utiliser gum si nécessaire
if $USE_GUM; then
    if gum confirm "Voulez-vous télécharger et installer le fond d'écran ?"; then
        # ... (code pour télécharger et installer le fond d'écran)
    fi
    
    if gum confirm "Voulez-vous installer WhiteSur-Dark ?"; then
        # ... (code pour installer WhiteSur-Dark)
    fi
    
    if gum confirm "Voulez-vous installer Fluent Cursor ?"; then
        # ... (code pour installer Fluent Cursor)
    fi
else
    # ... (code existant pour les interactions sans gum)
fi

info_msg "----------------------------------------"
## Téléchargement et installation du fond d'écran
info_msg "Téléchargement du fond d'écran..."
execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png > /dev/null 2>&1" \
    "Fond d'écran téléchargé." \
    "Échec du téléchargement du fond d'écran."

execute_command "mkdir -p /usr/share/backgrounds/xfce/" \
    "Dossier de fond d'écran créé." \
    "Échec de la création du dossier de fond d'écran."

execute_command "sudo mv waves.png /usr/share/backgrounds/xfce/ > /dev/null 2>&1" \
    "Fond d'écran installé." \
    "Échec de l'installation du fond d'écran."

## Installation de WhiteSur-Dark
info_msg "Installation WhiteSur-Dark..."
execute_command "wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip > /dev/null 2>&1" \
    "Archive WhiteSur-Dark téléchargée." \
    "Échec du téléchargement de WhiteSur-Dark."

execute_command "unzip 2024.09.02.zip && tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz && sudo mv WhiteSur-Dark/ /usr/share/themes/ && sudo rm -rf WhiteSur* && sudo rm 2024.09.02.zip" \
    "WhiteSur-Dark installé." \
    "Échec de l'installation de WhiteSur-Dark."

## Installation de Fluent Cursor
info_msg "Installation Fluent Cursor..."
execute_command "wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip > /dev/null 2>&1" \
    "Archive Fluent Cursor téléchargée." \
    "Échec du téléchargement de Fluent Cursor."

execute_command "unzip 2024-02-25.zip && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/ && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/ && sudo rm -rf $HOME/Fluent* && sudo rm 2024-02-25.zip" \
    "Fluent Cursor installé." \
    "Échec de l'installation de Fluent Cursor."