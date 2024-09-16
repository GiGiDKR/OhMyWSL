#!/bin/bash

USE_GUM=false

# Fonction pour afficher des messages d'information en bleu
info_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33
    else
        echo -e "\e[38;5;33m$1\e[0m"
    fi
}

# Fonction pour afficher des messages de succès en vert
success_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 82
    else
        echo -e "\e[38;5;82m$1\e[0m"
    fi
}

# Fonction pour afficher des messages d'erreur en rouge
error_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 196
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
        local info_msg_content=$(info_msg "$2")
        if gum spin --spinner dot --title "$info_msg_content" -- bash -c "$command"; then
            gum style "✓ $success_msg" --foreground 82
        else
            gum style "✗ $error_msg" --foreground 196
            return 1
        fi
    else
        info_msg "$2"
        if eval "$command"; then
            success_msg "✓ $success_msg"
        else
            error_msg "✗ $error_msg"
            return 1
        fi
    fi
}

# Remplacer les lignes de séparation par une fonction
separator() {
    if $USE_GUM; then
        gum style "" "_________________________________________" "" --foreground 33
    else
        echo -e "\e[38;5;33m\n_________________________________________\n\e[0m"
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
        download_wallpaper=true
    fi
    
    if gum confirm "Voulez-vous installer WhiteSur-Dark ?"; then
        install_whitesur=true
    fi
    
    if gum confirm "Voulez-vous installer Fluent Cursor ?"; then
        install_fluent=true
    fi
else
    read -p "Voulez-vous télécharger et installer le fond d'écran ? (o/n) : " response
    [[ $response =~ ^[Oo]$ ]] && download_wallpaper=true

    read -p "Voulez-vous installer WhiteSur-Dark ? (o/n) : " response
    [[ $response =~ ^[Oo]$ ]] && install_whitesur=true

    read -p "Voulez-vous installer Fluent Cursor ? (o/n) : " response
    [[ $response =~ ^[Oo]$ ]] && install_fluent=true
fi

separator

if [ "$download_wallpaper" = true ]; then
    ## Téléchargement et installation du fond d'écran
    info_msg "Téléchargement du fond d'écran..."
    execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png" \
        "Fond d'écran téléchargé." \
        "Échec du téléchargement du fond d'écran."

    execute_command "sudo mkdir -p /usr/share/backgrounds/xfce/" \
        "Dossier de fond d'écran créé." \
        "Échec de la création du dossier de fond d'écran."

    execute_command "sudo mv waves.png /usr/share/backgrounds/xfce/" \
        "Fond d'écran installé." \
        "Échec de l'installation du fond d'écran."
fi

if [ "$install_whitesur" = true ]; then
    ## Installation de WhiteSur-Dark
    info_msg "Installation WhiteSur-Dark..."
    execute_command "wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip" \
        "Archive WhiteSur-Dark téléchargée." \
        "Échec du téléchargement de WhiteSur-Dark."

    execute_command "unzip 2024.09.02.zip && tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz && sudo mv WhiteSur-Dark/ /usr/share/themes/ && sudo rm -rf WhiteSur* && sudo rm 2024.09.02.zip" \
        "WhiteSur-Dark installé." \
        "Échec de l'installation de WhiteSur-Dark."
fi

if [ "$install_fluent" = true ]; then
    ## Installation de Fluent Cursor
    info_msg "Installation Fluent Cursor..."
    execute_command "wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" \
        "Archive Fluent Cursor téléchargée." \
        "Échec du téléchargement de Fluent Cursor."

    execute_command "unzip 2024-02-25.zip && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/ && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/ && sudo rm -rf $HOME/Fluent* && sudo rm 2024-02-25.zip" \
        "Fluent Cursor installé." \
        "Échec de l'installation de Fluent Cursor."
fi