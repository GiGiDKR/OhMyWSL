#!/bin/bash

USE_GUM=false
FULL_INSTALL=false

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
    local needs_input="${3:-false}"

    if $USE_GUM; then
        if $needs_input; then
            info_msg "$info_msg"
            if bash -c "$command"; then
                gum style "$success_msg" --foreground 82
            else
                gum style "$error_msg" --foreground 196
                return 1
            fi
        else
            if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command"; then
                gum style "$success_msg" --foreground 82
            else
                gum style "$error_msg" --foreground 196
                return 1
            fi
        fi
    else
        info_msg "$info_msg"
        if $needs_input; then
            if eval "$command"; then
                success_msg "$success_msg"
            else
                error_msg "$error_msg"
                return 1
            fi
        else
            if eval "$command" > /dev/null 2>&1; then
                success_msg "$success_msg"
            else
                error_msg "$error_msg"
                return 1
            fi
        fi
    fi
}

# Traitement des arguments en ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true ;;
        --full|-f) FULL_INSTALL=true ;;
        *) error_msg "Option non reconnue : $1" ;;
    esac
    shift
done

# Ajoutez cette fonction pour gérer les confirmations
gum_confirm() {
    local prompt="$1"
    if $FULL_INSTALL; then
        return 0
    else
        gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "$prompt"
    fi
}

# Remplacez tous les appels à gum confirm par gum_confirm
# Par exemple :
if gum_confirm "Installer le fond d'écran ?"; then
    download_wallpaper="Oui"
fi

if gum_confirm "Installer WhiteSur-Dark ?"; then
    install_whitesur="Oui"
fi

if gum_confirm "Installer Fluent Cursor ?"; then
    install_fluent="Oui"
fi

# TODO Revoir cette fonction
# Fonction pour appliquer le thème XFCE
#apply_xfce_theme() {
#    local gtk_theme="$1"
#    local icon_theme="$2"
#    local cursor_theme="$3"

#    execute_command "xfconf-query -c xsettings -p /Net/ThemeName -s '$gtk_theme'" "Application du thème GTK"
#    execute_command "xfconf-query -c xsettings -p /Net/IconThemeName -s '$icon_theme'" "Application du thème d'icônes"
#    execute_command "xfconf-query -c xsettings -p /Gtk/CursorThemeName -s '$cursor_theme'" "Application du thème de curseur"
#    execute_command "xfconf-query -c xfwm4 -p /general/theme -s '$gtk_theme'" "Application du thème de fenêtre"
#}

info_msg "❯ Configuration de XFCE"

# Vérification des dépendances
check_dependencies() {
    local dependencies=("wget" "unzip" "tar")
    local missing_deps=()

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        error_msg "Dépendances manquantes : ${missing_deps[*]}"
        info_msg "Installation des dépendances manquantes..."
        execute_command "sudo apt update && sudo apt install -y ${missing_deps[*]}" "Installation des dépendances"
    fi
}

# Fonction pour télécharger et installer un thème
install_theme() {
    local name="$1"
    local url="$2"
    local install_dir="$3"
    local zip_file="${name}.zip"

    execute_command "wget '$url' -O '$zip_file'" "Téléchargement de $name"
    execute_command "unzip -o '$zip_file' -d '$install_dir'" "Extraction de $name"
    execute_command "rm '$zip_file'" "Nettoyage des fichiers temporaires"
}

# TODO Revoir cette fonction
# Fonction pour appliquer le thème XFCE
#apply_xfce_theme() {
#    local gtk_theme="$1"
#    local icon_theme="$2"
#    local cursor_theme="$3"

#    execute_command "xfconf-query -c xsettings -p /Net/ThemeName -s '$gtk_theme'" "Application du thème GTK"
#    execute_command "xfconf-query -c xsettings -p /Net/IconThemeName -s '$icon_theme'" "Application du thème d'icônes"
#    execute_command "xfconf-query -c xsettings -p /Gtk/CursorThemeName -s '$cursor_theme'" "Application du thème de curseur"
#    execute_command "xfconf-query -c xfwm4 -p /general/theme -s '$gtk_theme'" "Application du thème de fenêtre"
#}

info_msg "❯ Configuration de XFCE"

# Vérification des dépendances
check_dependencies

if [ "$download_wallpaper" = "Oui" ]; then
    execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png -O /tmp/waves.png" "Téléchargement du fond d'écran"
    execute_command "sudo mv /tmp/waves.png /usr/share/backgrounds/xfce/" "Installation du fond d'écran"
fi

if [ "$install_whitesur" = "Oui" ]; then
    install_theme "WhiteSur-Dark-Theme" "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip" "/tmp"
    sudo mkdir -p /usr/share/themes >/dev/null 2>&1
    cd /tmp/WhiteSur-gtk-theme-2024.09.02/release/ >/dev/null 2>&1
    tar -xf /tmp/WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz >/dev/null 2>&1
    execute_command "sudo mv /tmp/WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark /usr/share/themes/" "Installation de WhiteSur-Dark"
    execute_command "rm -rf /tmp/WhiteSur-gtk-theme-2024.09.02" "Nettoyage des fichiers temporaires"
    cd >/dev/null 2>&1
fi


if [ "$install_fluent" = "Oui" ]; then
    install_theme "Fluent-Cursors" "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "/tmp"
    execute_command "sudo mkdir -p /usr/share/icons" "Création du répertoire des icônes"
    execute_command "sudo mv /tmp/Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/Fluent-cursors" "Installation de Fluent Cursor"
    execute_command "sudo mv /tmp/Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/Fluent-cursors-dark" "Installation de Fluent Cursor Dark"
    execute_command "rm -rf /tmp/Fluent-icon-theme-2024-02-25" "Nettoyage des fichiers temporaires"
fi

# TODO Revoir cette fonction
#if [ "$apply_themes" = "Oui" ]; then
#    info_msg "Application des thèmes..."
#    apply_xfce_theme "WhiteSur-Dark" "Fluent-dark" "Fluent-cursors-dark"
#    success_msg "Thèmes appliqués avec succès"
#fi