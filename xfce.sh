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
    local info_msg="$2"
    local success_msg="✓ $info_msg"
    local error_msg="✗ $info_msg"

    if $USE_GUM; then
        if gum spin  --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command"; then
            gum style "$success_msg" --foreground 82
        else
            gum style "$error_msg" --foreground 196
            return 1
        fi
    else
        info_msg "$info_msg"
        if eval "$command" > /dev/null 2>&1; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
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

if $USE_GUM; then
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "Voulez-vous installer le fond d'écran ?"; then
        download_wallpaper=true
    fi
    
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "Voulez-vous installer WhiteSur-Dark ?"; then
        install_whitesur=true
    fi
    
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "Voulez-vous installer Fluent Cursor ?"; then
        install_fluent=true
    fi
else
    read -p $"\e[33mVoulez-vous installer le fond d'écran ? (o/n) : \e[0m" choice
    [[ $choice =~ ^[Oo]$ ]] && download_wallpaper=true

    read -p $"\e[33mVoulez-vous installer WhiteSur-Dark ? (o/n) : \e[0m" choice
    [[ $choice =~ ^[Oo]$ ]] && install_whitesur=true

    read -p $"\e[33mVoulez-vous installer Fluent Cursor ? (o/n) : \e[0m" choice
    [[ $choice =~ ^[Oo]$ ]] && install_fluent=true
fi

if [ "$download_wallpaper" = true ]; then
    execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png" "Téléchargement du fond d'écran"
    execute_command "sudo mv waves.png /usr/share/backgrounds/xfce/" "Installation du fond d'écran"
fi

if [ "$install_whitesur" = true ]; then
    execute_command "wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip" "Téléchargement de WhiteSur-Dark"
    execute_command "unzip 2024.09.02.zip && tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz && sudo mv WhiteSur-Dark/ /usr/share/themes/ && sudo rm -rf WhiteSur* && sudo rm 2024.09.02.zip" "Installation de WhiteSur-Dark"
fi

if [ "$install_fluent" = true ]; then
    execute_command "wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Téléchargement de Fluent Cursor"
    execute_command "unzip 2024-02-25.zip && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/ && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/ && sudo rm -rf $HOME/Fluent* && sudo rm 2024-02-25.zip" "Installation de Fluent Cursor"
fi