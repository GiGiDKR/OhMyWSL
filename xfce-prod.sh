#!/bin/bash
set -e

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
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command"; then
            gum style "$success_msg" --foreground 82
        else
            gum style "$error_msg" --foreground 196
            return 1
        fi
    else
        info_msg "$info_msg"
        if eval "$command"; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
            return 1
        fi
    fi
}

# Traitement des arguments de ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true ;;
        *) error_msg "Option non reconnue : $1" >&2; exit 1 ;;
    esac
    shift
done

# Fonction pour télécharger et installer un composant
download_and_install() {
    local url="$1"
    local filename="$2"
    local install_command="$3"
    local component_name="$4"

    execute_command "wget -q $url -O $filename" "Téléchargement de $component_name"
    execute_command "$install_command" "Installation de $component_name"
}

# Demander à l'utilisateur les options de personnalisation
if $USE_GUM; then
    download_wallpaper=$(gum confirm "Voulez-vous installer le fond d'écran ?" && echo true || echo false)
    install_whitesur=$(gum confirm "Voulez-vous installer WhiteSur-Dark ?" && echo true || echo false)
    install_fluent=$(gum confirm "Voulez-vous installer Fluent Cursor ?" && echo true || echo false)
else
    read -p "Voulez-vous installer le fond d'écran ? (o/n) : " response
    [[ $response =~ ^[Oo]$ ]] && download_wallpaper=true || download_wallpaper=false

    read -p "Voulez-vous installer WhiteSur-Dark ? (o/n) : " response
    [[ $response =~ ^[Oo]$ ]] && install_whitesur=true || install_whitesur=false

    read -p "Voulez-vous installer Fluent Cursor ? (o/n) : " response
    [[ $response =~ ^[Oo]$ ]] && install_fluent=true || install_fluent=false
fi

# Télécharger et installer le fond d'écran
if [ "$download_wallpaper" = true ]; then
    download_and_install "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png" \
                        "waves.png" \
                        "sudo mv waves.png /usr/share/backgrounds/xfce/" \
                        "fond d'écran"
fi

# Télécharger et installer WhiteSur-Dark
if [ "$install_whitesur" = true ]; then
    download_and_install "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip" \
                        "whitesur.zip" \
                        "unzip -q whitesur.zip && tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz && sudo mv WhiteSur-Dark/ /usr/share/themes/ && rm -rf WhiteSur* whitesur.zip" \
                        "WhiteSur-Dark"
fi

# Télécharger et installer Fluent Cursor
if [ "$install_fluent" = true ]; then
    download_and_install "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" \
                        "fluent.zip" \
                        "unzip -q fluent.zip && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/ && sudo mv Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/ && rm -rf Fluent* fluent.zip" \
                        "Fluent Cursor"
fi