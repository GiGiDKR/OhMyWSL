#!/bin/bash

USE_GUM=false

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
    sudo mkdir -p /etc/apt/keyrings > /dev/null 2>&1
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg > /dev/null 2>&1
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null 2>&1
    sudo chmod 644 /etc/apt/keyrings/charm.gpg /etc/apt/sources.list.d/charm.list > /dev/null 2>&1
    sudo apt update -y > /dev/null 2>&1 && sudo apt install -y gum > /dev/null 2>&1
}

# Installation de gum si nécessaire
if $USE_GUM; then
    if ! command -v gum &> /dev/null; then
        install_gum
    fi
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
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "DEBIAN_FRONTEND=noninteractive $command"; then
            gum style "$success_msg" --foreground 82
        else
            gum style "$error_msg" --foreground 196
            return 1
        fi
    else
        info_msg "$info_msg"
        if DEBIAN_FRONTEND=noninteractive eval "$command" > /dev/null 2>&1; then
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

info_msg "❯ Configuration du système"
wslconfig_file="/mnt/c/Users/$USERNAME/.wslconfig"
content="[wsl2]
guiApplications=false
[network]
generateResolvConf = false"

execute_command "echo -e \"$content\" | tr -d '\r' > \"$wslconfig_file\"" "Création du fichier wslconfig"

## Installation des paquets
packages="xfce4 xfce4-goodies gdm3 xwayland nautilus ark jq"

execute_command "sudo apt update -y" "Recherche de mises à jour"
execute_command "sudo apt upgrade -y" "Mise à jour des paquets"
configure_noninteractive
for package in $packages; do
    execute_command "sudo DEBIAN_FRONTEND=noninteractive apt install -y $package" "Installation de $package"
done

# Installation de ZSH
info_msg "❯ Configuration du shell"
if $USE_GUM; then
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.fo
reground="0""Installer zsh ?"; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh" "Téléchargement du script zsh"
        execute_command "chmod +x zsh.sh" "Modification des permissions"
        "$HOME/zsh.sh" --gum  # Exécution directe du script avec gum
        if [ $? -eq 0 ]; then
            success_msg "✓ Installation de zsh"
        else
            error_msg "✗ Installation de zsh"
        fi
    else
        info_msg "𐄂 Installation de zsh refusée"
    fi
else
    read -p $"\e[33mInstaller zsh ? (o/n) : \e[0m" choice

    reponse_zsh=$(echo "$reponse_zsh" | tr '[:upper:]' '[:lower:]')

    if [ "$reponse_zsh" = "oui" ] || [ "$reponse_zsh" = "o" ] || [ "$reponse_zsh" = "y" ] || [ "$reponse_zsh" = "yes" ]; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh" "Téléchargement du script zsh"
        execute_command "chmod +x zsh.sh" "Modification des permissions"
        "$HOME/zsh.sh"  # Exécution directe du script
        if [ $? -eq 0 ]; then
            success_msg "✓ Installation de zsh"
        else
            error_msg "✗ Installation de zsh"
        fi
    else
        info_msg "𐄂 Installation de zsh refusée"
    fi
fi

## Configuration réseau
info_msg "❯ Configuration du réseau"
ip_address=$(ip route | grep default | awk '{print $3; exit;}')

if [ -z "$ip_address" ]; then
    error_msg "Impossible de récupérer l'adresse IP"
    exit 1
fi

resolv_conf="/etc/resolv.conf"

if [ ! -f "$resolv_conf" ]; then
    error_msg "Le fichier $resolv_conf n'existe pas"
    exit 1
fi

execute_command "sudo sed -i 's/^nameserver.*/nameserver '"${ip_address}"'/' /etc/resolv.conf" "Mise à jour du fichier resolv.conf"

## Configuration des fichiers de shell
bashrc_path="$HOME/.bashrc"
zshrc_path="$HOME/.zshrc"

lines_to_add="
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0
export PULSE_SERVER=tcp:$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}')
"

add_lines_to_file() {
    local file="$1"
    local create_if_missing="$2"

    if [ -f "$file" ]; then
        execute_command "echo \"$lines_to_add\" >> \"$file\"" "Configuration du fichier $file"
    else
        if [ "$create_if_missing" = "true" ]; then
            execute_command "touch \"$file\"" "Création du fichier $file"
            execute_command "echo \"$lines_to_add\" >> \"$file\"" "Configuration du fichier $file"
        else
            error_msg "Le fichier $file n'existe pas"
        fi
    fi
}

add_lines_to_file "$bashrc_path" "true"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path" "false"

## Installation de GWSL
install_gwsl() {
    execute_command "mkdir -p /mnt/c/WSL2-Distros" "Création du répertoire C:\WSL2-Distros"

    if [ ! -f "/mnt/c/WSL2-Distros/GWSL-145-STORE.zip" ]; then
        execute_command "wget https://archive.org/download/gwsl-145-store/GWSL-145-STORE.zip -P /mnt/c/WSL2-Distros" "Téléchargement de GWSL"
    else
        info_msg "Sources déjà téléchargées"
    fi

    cd /mnt/c/WSL2-Distros
    execute_command "unzip GWSL-145-STORE.zip" "Extraction de GWSL"
    execute_command "mv GWSL-145-STORE GWSL" "Configuration de GWSL"
    execute_command "rm -f GWSL-145-STORE.zip" "Nettoyage des fichiers temporaires"

    cd
}

# TODO Vérifier si la fonction peut être supprimée
configure_gwsl() {
    local gwsl_config_file="/mnt/c/Users/$USERNAME/AppData/Roaming/GWSL/settings.json"
    local temp_file="/tmp/gwsl_settings.json"

    info_msg "❯ Configuration de GWSL"

    if [ -f "$gwsl_config_file" ]; then
        cat "$gwsl_config_file" > "$temp_file"
        jq '.graphics = {"window_mode": "single", "hidpi": true}' "$temp_file" > "${temp_file}.tmp" && mv "${temp_file}.tmp" "$temp_file"
        execute_command "cp \"$temp_file\" \"$gwsl_config_file\"" "Mise à jour des paramètres de GWSL"
        rm -f "$temp_file"
    else
        error_msg "Le fichier $gwsl_config_file n'existe pas"
        return 1
    fi
}

execute_gwsl() {
    execute_command "/mnt/c/WSL2-Distros/GWSL/GWSL.exe" "Exécution de GWSL"
}

# Fonction pour installer des packages optionnels
optional_packages() {
    if $USE_GUM; then
        packages=$(gum choose --no-limit --header="Sélectionner avec ESPACE les packages à installer :" "nala" "eza" "lfm" "bat" "fzf" "Tout installer")
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
        read -p $"\e[33mEntrez les numéros des packages (SÉPARÉS PAR DES ESPACES) : \e[0m" package_choices
    fi

    for choice in $packages; do
        case $choice in
            nala|1) install_package "nala" ;;
            eza|2) install_eza ;;
            lfm|3) install_package "lfm" ;;
            bat|4) install_package "bat" ;;
            fzf|5) install_package "fzf" ;;
            "Tout installer"|6)
                install_package "nala"
                install_eza
                install_package "lfm"
                install_package "bat"
                install_package "fzf"
                ;;
        esac
    done
}

# Fonction pour installer un package standard
install_package() {
    local package=$1
    execute_command "sudo apt install -y $package" "Installation de $package"
    add_aliases_to_rc "$package"
}

# Fonction pour installer eza
install_eza() {
    execute_command "sudo apt install -y gpg ca-certificates" "Installation des prérequis pour eza"

    execute_command "sudo mkdir -p /etc/apt/keyrings && \
                    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
                    echo 'deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main' | sudo tee /etc/apt/sources.list.d/gierens.list && \
                    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
                    sudo apt update && \
                    sudo apt install -y eza" "Installation de eza"

    add_aliases_to_rc "eza"
}

# Fonction pour ajouter des alias selon les packages installés
add_aliases_to_rc() {
    local package=$1
    local rc_file="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && rc_file="$HOME/.zshrc"

    case $package in
        eza)
            echo -e '\nalias l="eza --icons"
alias ls="eza -1 --icons"
alias ll="eza -lF -a --icons --total-size --no-permissions --no-time --no-user"
alias la="eza --icons -lgha --group-directories-first"
alias lt="eza --icons --tree"
alias lta="eza --icons --tree -lgha"
alias dir="eza -lF --icons"' >> "$rc_file"
            ;;
        bat)
            echo -e '\nalias cat="bat"' >> "$rc_file"
            ;;
        nala)
            echo -e '\nalias install="nala install -y"
alias uninstall="nala remove -y"
alias update="nala update"
alias upgrade="nala upgrade -y"
alias search="nala search"
alias list="nala list --upgradeable"
alias show="nala show"' >> "$rc_file"
            ;;
        # TODO Ajoutez d'autres cas pour les packages supplémentaires si nécessaire
    esac
}

common_alias() {
# Define general aliases in a variable
aliases='alias ..="cd .."
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

if [ -f "$zshrc_path" ]; then
    echo "$aliases" >> "$zshrc_path"
fi
}

common_alias

# Demander à l'utilisateur s'il souhaite installer des packages supplémentaires
info_msg "❯ Installation de packages supplémentaires"
if $USE_GUM; then
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "Installer des packages supplémentaires ?"; then
        optional_packages
    fi
else
    read -p $"\e[33mInstaller des packages supplémentaires ? (o/n) : \e[0m" choice

    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

    if [ "$choice" = "oui" ] || [ "$choice" = "o" ] || [ "$choice" = "y" ] || [ "$choice" = "yes" ]; then
        optional_packages
    fi
fi

# Demander à l'utilisateur s'il souhaite installer GWSL
info_msg "❯ Installation de GWSL"
if $USE_GUM; then
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "Voulez-vous installer GWSL ?"; then
        install_gwsl
# TODO Vérifier si la fonction peut être supprimée
#        configure_gwsl || error_msg "Échec de la configuration de GWSL"
    fi
else
    read -p $"\e[33mVoulez-vous installer GWSL ? (o/n) : \e[0m" choice
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    
    if [ "$choice" = "oui" ] || [ "$choice" = "o" ] || [ "$choice" = "y" ] || [ "$choice" = "yes" ]; then
        install_gwsl
        # TODO Vérifier si la fonction peut être supprimée
#        configure_gwsl || error_msg "Échec de la configuration de GWSL"
    fi
fi

execute_command "timeout 5s sudo startxfce4" "Session XFCE4 fermée après 5 secondes"

## Configuration de XFCE4
info_msg "❯ Configuration de XFCE4"

execute_command "mkdir -p $HOME/.config/xfce4" "Création du dossier de configuration XFCE4"
execute_command "cp /etc/xdg/xfce4/xinitrc $HOME/.config/xfce4/xinitrc" "Copie de fichiers"
execute_command "touch $HOME/.ICEauthority" "Création de fichiers"
execute_command "chmod 600 $HOME/.ICEauthority" "Modification des permissions des fichiers"
execute_command "sudo mkdir -p /run/user/$UID" "Création d'un dossier temporaire"
execute_command "sudo chown -R $UID:$UID /run/user/$UID/" "Modification des permissions du dossier"

# Personnalisation XFCE
if $USE_GUM; then
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "Installer la personnalisation XFCE ?"; then
        if [ -f "$HOME/xfce.sh" ]; then
            "$HOME/xfce.sh" --gum
            if [ $? -eq 0 ]; then
                success_msg "✓ Personnalisation XFCE"
            else
                error_msg "✗ Personnalisation XFCE"
            fi
        else
            error_msg "Le fichier xfce.sh n'existe pas"
        fi
    else
        info_msg "𐄂 Personnalisation XFCE refusée"
    fi
else
    read -p $"\e[33mInstaller la personnalisation XFCE ? (o/n) : \e[0m" choice

    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

    if [ "$choice" = "oui" ] || [ "$choice" = "o" ] || [ "$choice" = "y" ] || [ "$choice" = "yes" ]; then
        if [ -f "$HOME/xfce.sh" ]; then
            "$HOME/xfce.sh"  # Exécution directe du script
            if [ $? -eq 0 ]; then
                success_msg "✓ Personnalisation XFCE"
            else
                error_msg "✗ Personnalisation XFCE"
            fi
        else
            error_msg "Le fichier xfce.sh n'existe pas"
        fi
    else
        info_msg "𐄂 Personnalisation XFCE refusée"
    fi
fi

execute_gwsl
sleep 5
execute_command "dbus-launch xfce4-session" "Lancement de la session XFCE4"
sleep 5
execute_command "rm -f zsh.sh xfce.sh" "Nettoyage des fichiers temporaires"
execute_command "rm -- "$0"" "Suppression du script d'installation"
exit 0