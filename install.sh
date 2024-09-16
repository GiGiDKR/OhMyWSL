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
    echo "Installation de gum"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
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
            "" "OHMYWSL ""
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
        if gum spin  --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command"; then
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


## separator() {
#    if $USE_GUM; then
#        gum style "" --foreground 33
#    else
#        echo -e "\e[38;5;33m\e[0m"
#    fi
#}

clear

sudo -v

show_banner

# Création du fichier .wslconfig
wslconfig_file="/mnt/c/Users/$USER/.wslconfig"
content="[wsl2]
guiApplications=false
[network]
generateResolvConf = false"

execute_command "echo -e \"$content\" | tr -d '\r' > \"$wslconfig_file\"" "Création du fichier .wslconfig"

# separator

## Installation des paquets
packages="xfce4 xfce4-goodies gdm3 xwayland nautilus ark"


execute_command "sudo apt update -y" "Recherche de mises à jour"


execute_command "sudo apt upgrade -y" "Mise à jour des paquets"

# separator

for package in $packages; do
    execute_command "sudo apt install -y $package" "Installation de $package"
done

# separator
# Installation de ZSH
if $USE_GUM; then
    if gum confirm "Installer zsh ?"; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh" "Téléchargement du script"
        execute_command "chmod +x zsh.sh" "Modification des permissions du script"
        "$HOME/zsh.sh" --gum  # Exécution directe du script avec gum
        if [ $? -eq 0 ]; then
            success_msg "✓ Installation de zsh"
        else
            error_msg "✗ Installation de zsh"
        fi
    else
        info_msg "Installation de zsh refusée"
    fi
else
    read -p "Installer zsh ? (o/n) : " reponse_zsh

    reponse_zsh=$(echo "$reponse_zsh" | tr '[:upper:]' '[:lower:]')

    if [ "$reponse_zsh" = "oui" ] || [ "$reponse_zsh" = "o" ] || [ "$reponse_zsh" = "y" ] || [ "$reponse_zsh" = "yes" ]; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh" "Téléchargement du script"
        execute_command "chmod +x zsh.sh" "Modification des permissions du script"
        "$HOME/zsh.sh"  # Exécution directe du script
        if [ $? -eq 0 ]; then
            success_msg " ✓ Installation de zsh"
        else
            error_msg "✗ Installation de zsh"
        fi
    else
        info_msg "Installation de zsh refusée"
    fi
fi

# separator
## Configuration réseau
info_msg "Configuration du réseau"
ip_address=$(ip route | grep default | awk '{print $3; exit;}')

if [ -z "$ip_address" ]; then
    error_msg "Erreur : Impossible de récupérer l'adresse IP"
    exit 1
fi

resolv_conf="/etc/resolv.conf"

if [ ! -f "$resolv_conf" ]; then
    error_msg "Erreur : Le fichier $resolv_conf n'existe pas"
    exit 1
fi

execute_command "sudo sed -i \"s/^nameserver.*/& ${ip_address}:0.0/\" \"$resolv_conf\"" "Mise à jour du fichier $resolv_conf"

# separator
## Configuration des fichiers de shell
bashrc_path="$HOME/.bashrc"
zshrc_path="$HOME/.zshrc"

lines_to_add='
export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}"):0.0
export PULSE_SERVER=tcp:$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}")
echo $DISPLAY'

add_lines_to_file() {
    if [ -f "$1" ]; then
        execute_command "echo \"$lines_to_add\" >> \"$1\"" "Ajout de la configuration à $1"
    else
        error_msg "Le fichier $1 n'existe pas"
    fi
}

add_lines_to_file "$bashrc_path"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path"

# separator
## Installation de GWSL
# Fonction pour installer GWSL
install_gwsl() {
    if [ ! -f "GWSL-145-STORE.zip" ]; then
        execute_command "wget https://github.com/Opticos/GWSL-Source/releases/download/v1.4.5/GWSL-145-STORE.zip" "Téléchargement de GWSL"
    else
        info_msg "Le fichier GWSL-145-STORE.zip existe déjà"
    fi

    execute_command "unzip GWSL-145-STORE.zip && mv GWSL-145-STORE/GWSL.exe /mnt/c/Users/Public/Desktop/ && rm -rf GWSL-145-STORE*" "Installation de GWSL"
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
        read -p "Entrez les numéros des packages (SÉPARÉS PAR DES ESPACES) : " package_choices
    fi

    for choice in $packages; do
        case $choice in
            1) install_package "nala" ;;
            2) install_eza ;;
            3) install_package "lfm" ;;
            4) install_package "bat" ;;
            5) install_package "fzf" ;;
            6)
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
        # Ajoutez d'autres cas pour les packages supplémentaires si nécessaire
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

echo -e "$aliases" >> "$bashrc_path"

if [ -f "$zshrc_path" ]; then
    echo -e "$aliases" >> "$zshrc_path"
fi
}

common_alias

# Demander à l'utilisateur s'il souhaite installer des packages supplémentaires
if $USE_GUM; then
    if gum confirm "Installer des packages supplémentaires ?"; then
        optional_packages
    fi
else
    read -p "Installer des packages supplémentaires ? (o/n) : " install_optional_packages
    if [ "$install_optional_packages" = "o" ]; then
        optional_packages
    fi
fi

# Demander à l'utilisateur s'il souhaite installer GWSL
if $USE_GUM; then
    if gum confirm "Voulez-vous installer GWSL ?"; then
        install_gwsl
    fi
else
    read -p "Voulez-vous installer GWSL ? (o/n) : " install_gwsl_choice
    if [ "$install_gwsl_choice" = "o" ]; then
        install_gwsl
    fi
fi

# separator
## Configuration de XFCE4
#info_msg "Démarrage de XFCE4..."
#execute_command "timeout 5s sudo startxfce4 &> /dev/null" "XFCE4 fermé après 5 secondes"

info_msg "Configuration de XFCE4..."
execute_command "mkdir -p $HOME/.config/xfce4" "Création du dossier de configuration XFCE4"

execute_command "cp /etc/xdg/xfce4/xinitrc $HOME/.config/xfce4/xinitrc" "Copie du fichier xinitrc"

execute_command "touch $HOME/.ICEauthority" "Création du fichier .ICEauthority"

execute_command "chmod 600 $HOME/.ICEauthority" "Modification des permissions du fichier .ICEauthority"

execute_command "sudo mkdir -p /run/user/$UID" "Création du dossier /run/user/$UID"

execute_command "sudo chown -R $UID:$UID /run/user/$UID/" "Modification du propriétaire du dossier /run/user/$UID"

execute_command "echo 'echo \$DISPLAY' >> $HOME/.bashrc" "Ajout de l'affichage de DISPLAY à .bashrc"

# separator
# Personnalisation XFCE
if $USE_GUM; then
    if gum confirm "Installer la personnalisation XFCE ?"; then
        if [ -f "$HOME/xfce.sh" ]; then
            "$HOME/xfce.sh" --gum  # Exécution directe du script avec gum
            if [ $? -eq 0 ]; then
                success_msg "✓ Personnalisation XFCE"
            else
                error_msg "✗ Personnalisation XFCE"
            fi
        else
            error_msg "Le fichier xfce.sh n'existe pas"
        fi
    else
        info_msg "Personnalisation XFCE refusée"
    fi
else
    read -p "Installer la personnalisation XFCE ? (o/n) : " reponse

    reponse=$(echo "$reponse" | tr '[:upper:]' '[:lower:]')

    if [ "$reponse" = "oui" ] || [ "$reponse" = "o" ] || [ "$reponse" = "y" ] || [ "$reponse" = "yes" ]; then
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
        info_msg "Personnalisation XFCE refusée"
    fi
fi

# separator
## Lancement de la session XFCE4
execute_command "dbus-launch xfce4-session" "Démarrage de la session XFCE4"
