#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

USE_GUM=false
HOME_DIR="/home/$USER"
CONFIG_DIR="$HOME_DIR/.config"
XFCE4_CONFIG_DIR="$CONFIG_DIR/xfce4"

# Fonction pour afficher le banner en mode basique
bash_banner() {
    clear
    local BANNER="
╔═════════════════════════════════════╗
║                                     ║
║               OHMYWSL               ║
║                                     ║
╚═════════════════════════════════════╝"

    echo -e "\e[38;5;33m${BANNER}$1\n\e[0m"
}

# Traitement des arguments en ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true ;;
        *) echo "Option non reconnue : $1" ;;
    esac
    shift
done

# Fonction pour installer gum
install_gum() {
    bash_banner
    echo -e "\e[38;5;33mInstallation de gum\e[0m"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    sudo apt update && sudo apt install -y gum
}

# Installation de gum si nécessaire
if $USE_GUM && ! command -v gum &> /dev/null; then
    install_gum
fi

# Fonction pour afficher le banner
show_banner() {
    clear
    if $USE_GUM; then
        gum style \
            --foreground 33 \
            --border-foreground 33 \
            --border double \
            --align center \
            --width 35 \
            --margin "1 1 1 0" \
            "" "OHMYWSL" ""
    else
        bash_banner
    fi
}

# Fonction pour afficher des messages colorés
display_message() {
    local message="$1"
    local color="$2"
    if $USE_GUM; then
        gum style "${message//$'\n'/ }" --foreground "$color"
    else
        echo -e "\e[38;5;${color}m$message\e[0m"
    fi
}

# Alias pour les fonctions de message
info_msg() { display_message "$1" 33; }
success_msg() { display_message "$1" 82; }
error_msg() { display_message "$1" 196; }

# Fonction pour exécuter une commande et afficher le résultat
execute_command() {
    local command="$1"
    local info_msg="$2"
    local success_msg="✓ $info_msg"
    local error_msg="✗ $info_msg"

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command"; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
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

configure_noninteractive() {
    sudo debconf-set-selections <<< "gdm3 shared/default-x-display-manager select gdm3"
    export DEBIAN_FRONTEND=noninteractive
}

sudo -v
show_banner

info_msg "Configuration du système"
# Création du fichier .wslconfig
wslconfig_file="/mnt/c/Users/$USER/.wslconfig"
content="[wsl2]
guiApplications=false
[network]
generateResolvConf = false"

execute_command "echo -e \"$content\" | tr -d '\r' > \"$wslconfig_file\"" "Création du fichier Wslconfig"

# Installation des paquets
packages="xfce4 xfce4-goodies gdm3 xwayland nautilus ark jq"

execute_command "sudo apt update && sudo apt upgrade -y" "Mise à jour du système"

configure_noninteractive

for package in $packages; do
    execute_command "sudo DEBIAN_FRONTEND=noninteractive apt install -y $package" "Installation de $package"
done

# Installation de ZSH
info_msg "Configuration du shell"
install_zsh() {
    execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh && chmod +x zsh.sh" "Téléchargement et préparation du script zsh"
    if $USE_GUM; then
        "$HOME_DIR/zsh.sh" --gum
    else
        "$HOME_DIR/zsh.sh"
    fi
    [ $? -eq 0 ] && success_msg "✓ Installation de zsh" || error_msg "✗ Installation de zsh"
}

if $USE_GUM; then
    gum confirm "Installer zsh ?" && install_zsh || info_msg "𐄂 Installation de zsh refusée"
else
    read -p "Installer zsh ? (o/n) : " reponse_zsh
    [[ "$reponse_zsh" =~ ^[oOyY] ]] && install_zsh || info_msg "𐄂 Installation de zsh refusée"
fi

# Configuration réseau
info_msg "Configuration du réseau"
ip_address=$(ip route | grep default | awk '{print $3; exit;}')
resolv_conf="/etc/resolv.conf"

[ -z "$ip_address" ] && { error_msg "Impossible de récupérer l'adresse IP"; exit 1; }
[ ! -f "$resolv_conf" ] && { error_msg "Le fichier $resolv_conf n'existe pas"; exit 1; }

execute_command "sudo sed -i \"s/^nameserver.*/nameserver ${ip_address}/\" \"$resolv_conf\"" "Mise à jour du fichier Resolv_conf"

# Configuration des fichiers de shell
bashrc_path="$HOME_DIR/.bashrc"
zshrc_path="$HOME_DIR/.zshrc"

lines_to_add="
export DISPLAY=\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2; exit;}'):0.0
export PULSE_SERVER=tcp:\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2; exit;}')
echo \$DISPLAY
"

add_lines_to_file() {
    local file="$1"
    local create_if_missing="$2"

    if [ -f "$file" ] || [ "$create_if_missing" = "true" ]; then
        execute_command "touch \"$file\" && echo \"$lines_to_add\" >> \"$file\"" "Configuration du fichier $(basename "$file")"
    else
        error_msg "Le fichier $(basename "$file") n'existe pas"
    fi
}

add_lines_to_file "$bashrc_path" "true"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path" "false"

# Installation de GWSL
install_gwsl() {
    local gwsl_zip="GWSL-145-STORE.zip"
    local gwsl_dir="/mnt/c/WSL2-Distros/GWSL"

    [ ! -f "$gwsl_zip" ] && execute_command "wget https://github.com/Opticos/GWSL-Source/releases/download/v1.4.5/$gwsl_zip" "Téléchargement de GWSL"
    
    execute_command "unzip $gwsl_zip && mkdir -p /mnt/c/WSL2-Distros && mv GWSL-145-STORE $gwsl_dir && rm -rf $gwsl_zip" "Installation de GWSL"
}

configure_gwsl() {
    local gwsl_config_file="/mnt/c/Users/$USER/AppData/Roaming/GWSL/settings.json"
    local temp_file="/tmp/gwsl_settings.json"

    info_msg "Configuration de GWSL"

    if [ -f "$gwsl_config_file" ]; then
        execute_command "jq '.graphics = {\"window_mode\": \"single\", \"hidpi\": true}' \"$gwsl_config_file\" > \"$temp_file\" && mv \"$temp_file\" \"$gwsl_config_file\"" "Mise à jour du fichier de configuration GWSL"
    else
        error_msg "Le fichier $gwsl_config_file n'existe pas"
    fi
}

execute_gwsl() {
    info_msg "❯ Lancement de GWSL"
    execute_command "/mnt/c/WSL2-Distros/GWSL/GWSL.exe" "Exécution de GWSL"
}

# Fonction pour installer des packages optionnels
optional_packages() {
    local packages_to_install=""
    if $USE_GUM; then
        packages_to_install=$(gum choose --no-limit --header="Sélectionner avec ESPACE les packages à installer :" "nala" "eza" "lfm" "bat" "fzf" "Tout installer")
    else
        info_msg "Sélectionnez les packages à installer :"
        echo  
        info_msg "1) nala"
        info_msg "2) eza"
        info_msg "3) lfm"
        info_msg "4) bat"
        info_msg "5) fzf"
        info_msg "6) Tout installer"
        echo
        read -p "Entrez les numéros des packages (SÉPARÉS PAR DES ESPACES) : " package_choices
        for choice in $package_choices; do
            case $choice in
                1) packages_to_install+="nala " ;;
                2) packages_to_install+="eza " ;;
                3) packages_to_install+="lfm " ;;
                4) packages_to_install+="bat " ;;
                5) packages_to_install+="fzf " ;;
                6) packages_to_install="nala eza lfm bat fzf" ; break ;;
            esac
        done
    fi

    for package in $packages_to_install; do
        case $package in
            nala|eza|lfm|bat|fzf) install_package "$package" ;;
            "Tout installer") install_package "nala eza lfm bat fzf" ; break ;;
        esac
    done
}

# Fonction pour installer un package standard
install_package() {
    local package=$1
    if [ "$package" = "eza" ]; then
        execute_command "sudo apt install -y gpg ca-certificates && \
                        sudo mkdir -p /etc/apt/keyrings && \
                        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
                        echo 'deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main' | sudo tee /etc/apt/sources.list.d/gierens.list && \
                        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
                        sudo apt update && \
                        sudo apt install -y eza" "Installation de eza"
    else
        execute_command "sudo apt install -y $package" "Installation de $package"
    fi
    add_aliases_to_rc "$package"
}

# Fonction pour ajouter des alias selon les packages installés
add_aliases_to_rc() {
    local package=$1
    local rc_file="$HOME_DIR/.bashrc"
    [ -f "$HOME_DIR/.zshrc" ] && rc_file="$HOME_DIR/.zshrc"

    local aliases=""
    case $package in
        eza)
            aliases='
alias l="eza --icons"
alias ls="eza -1 --icons"
alias ll="eza -lF -a --icons --total-size --no-permissions --no-time --no-user"
alias la="eza --icons -lgha --group-directories-first"
alias lt="eza --icons --tree"
alias lta="eza --icons --tree -lgha"
alias dir="eza -lF --icons"'
            ;;
        bat)
            aliases='
alias cat="bat"'
            ;;
        nala)
            aliases='
alias install="nala install -y"
alias uninstall="nala remove -y"
alias update="nala update"
alias upgrade="nala upgrade -y"
alias search="nala search"
alias list="nala list --upgradeable"
alias show="nala show"'
            ;;
    esac

    [ -n "$aliases" ] && echo "$aliases" >> "$rc_file"
}

common_alias() {
    local aliases='
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias h="history"
alias q="exit"
alias c="clear"
alias md="mkdir"
alias rm="rm -rf"
alias s="source"
alias n="nano"
alias cm="chmod +x"
alias g="git"
alias gc="git clone"
alias push="git pull && git add . && git commit -m '\''mobile push'\'' && git push"'

    echo "$aliases" >> "$bashrc_path"
    [ -f "$zshrc_path" ] && echo "$aliases" >> "$zshrc_path"
}

common_alias

# Demander à l'utilisateur s'il souhaite installer des packages supplémentaires
if $USE_GUM; then
    gum confirm "Installer des packages supplémentaires ?" && optional_packages
else
    read -p "Installer des packages supplémentaires ? (o/n) : " install_optional_packages
    [[ "$install_optional_packages" =~ ^[oOyY] ]] && optional_packages
fi

# Demander à l'utilisateur s'il souhaite installer GWSL
if $USE_GUM; then
    gum confirm "Voulez-vous installer GWSL ?" && { install_gwsl; configure_gwsl; }
else
    read -p "Voulez-vous installer GWSL ? (o/n) : " install_gwsl_choice
    [[ "$install_gwsl_choice" =~ ^[oOyY] ]] && { install_gwsl; configure_gwsl; }
fi

# Configuration de XFCE4
info_msg "Configuration de XFCE4"

execute_command "mkdir -p $XFCE4_CONFIG_DIR && \
                cp /etc/xdg/xfce4/xinitrc $XFCE4_CONFIG_DIR/xinitrc && \
                touch $HOME_DIR/.ICEauthority && \
                chmod 600 $HOME_DIR/.ICEauthority && \
                sudo mkdir -p /run/user/$UID && \
                sudo chown -R $UID:$UID /run/user/$UID/" "Configuration de XFCE4"

# Personnalisation XFCE
install_xfce_customization() {
    if [ -f "$HOME_DIR/xfce.sh" ]; then
        $USE_GUM && "$HOME_DIR/xfce.sh" --gum || "$HOME_DIR/xfce.sh"
        [ $? -eq 0 ] && success_msg "✓ Personnalisation XFCE" || error_msg "✗ Personnalisation XFCE"
    else
        error_msg "Le fichier xfce.sh n'existe pas"
    fi
}

if $USE_GUM; then
    gum confirm "Installer la personnalisation XFCE ?" && install_xfce_customization || info_msg "𐄂 Personnalisation XFCE refusée"
else
    read -p "Installer la personnalisation XFCE ? (o/n) : " reponse
    [[ "$reponse" =~ ^[oOyY] ]] && install_xfce_customization || info_msg "𐄂 Personnalisation XFCE refusée"
fi

execute_gwsl
execute_command "sleep 5 && dbus-launch xfce4-session" "❯ Lancement de la session XFCE4"
execute_command "rm -f zsh.sh xfce.sh && rm -- \"$0\"" "Nettoyage des fichiers temporaires"
# TODO Tester la commande suivante
zsh
exit 0