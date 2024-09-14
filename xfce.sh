#!/bin/bash

USE_GUM=false

for arg in "$@"; do
    case $arg in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
    esac
done

bash_banner() {
    clear
    echo -e "\e[38;5;33m
╔════════════════════════════════════════╗
║                                        ║
║              OHMYUBUNTU                ║
║                                        ║
╚════════════════════════════════════════╝
\e[0m"
}

show_banner() {
    clear
    if $USE_GUM; then
        gum style \
            --foreground 33 \
            --border-foreground 33 \
            --border double \
            --align center \
            --width 40 \
            --margin "1 1 1 0" \
            "" "OHMYUBUNTU" ""
    else
        bash_banner
    fi
}

finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERREUR: Installation de OhMyTermux impossible."
        else
            echo -e "\e[38;5;196mERREUR: Installation de OhMyTermux impossible.\e[0m"
        fi
        echo -e "\e[38;5;33mVeuillez vous référer au(x) message(s) d'erreur ci-dessus.\e[0m"
    fi
}

trap finish EXIT

show_banner
if $USE_GUM && ! command -v gum &> /dev/null; then
    echo -e "\e[38;5;33mInstallation de gum...\e[0m"
    sudo apt update -y > /dev/null 2>&1
    sudo apt install -y gum > /dev/null 2>&1
fi

username="$1"

apts=('virglrenderer-android' 'xfce4' 'xfce4-goodies' 'papirus-icon-theme' 'pavucontrol-qt' 'jq' 'wmctrl' 'firefox' 'netcat-openbsd' 'termux-x11-nightly')

for apt in "${apts[@]}"; do
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $apt" -- sudo apt install "$apt" -y
    else
        show_banner
        echo -e "\e[38;5;33mInstallation de $apt...\e[0m"
        sudo apt install "$apt" -y > /dev/null 2>&1
    fi
done

{
    mkdir -p $HOME/Desktop
    cp /usr/share/applications/firefox.desktop $HOME/Desktop
    chmod +x $HOME/Desktop/firefox.desktop
}

# TODO : Ajouter l'alias
#echo 'alias hud="GALLIUM_HUD=fps"' >> /usr/etc/bash.bashrc

#if [ -f "$HOME/.zshrc" ]; then
#    echo 'alias hud="GALLIUM_HUD=fps"' >> $HOME/.zshrc
#fi

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement du fond d'écran" -- wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png
else
    echo -e "\e[38;5;33mTéléchargement du fond d'écran...\e[0m"
    wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png > /dev/null 2>&1
fi

mkdir -p /usr/share/backgrounds/xfce/
sudo mv waves.png /usr/share/backgrounds/xfce/ > /dev/null 2>&1

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation WhiteSur-Dark" -- wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip
else
    echo -e "\e[38;5;33mInstallation WhiteSur-Dark...\e[0m"
    wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip > /dev/null 2>&1
fi
{
    unzip 2024.09.02.zip
    tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz
    sudo mv WhiteSur-Dark/ /usr/share/themes/
    sudo rm -rf WhiteSur*
    sudo rm 2024.09.02.zip
} > /dev/null 2>&1

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation Fluent Cursor" -- wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip
else
    echo -e "\e[38;5;33mInstallation Fluent Cursor...\e[0m"
    wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip > /dev/null 2>&1
fi
{
    unzip 2024-02-25.zip
    sudo mv Fluent-icon-theme-2024-02-25/cursors/dist /usr/share/icons/
    sudo mv Fluent-icon-theme-2024-02-25/cursors/dist-dark /usr/share/icons/
    sudo rm -rf $HOME/Fluent*
    sudo rm 2024-02-25.zip
} > /dev/null 2>&1

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de la configuration" -- wget https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip
else
    echo -e "\e[38;5;33mInstallation de la configuration...\e[0m"
    wget https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip > /dev/null 2>&1
fi
{
    unzip config.zip
    rm config.zip
} > /dev/null 2>&1