#!/bin/bash

USE_GUM=false
FULL_INSTALL=false

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
        --full|-f) FULL_INSTALL=true ;;
        *) echo "Option non reconnue : $1" ;;
    esac
    shift
done

# Vérification des permissions sudo au début du script
if ! sudo -v; then
    error_msg "Permissions sudo requises. Veuillez exécuter le script avec sudo."
    exit 1
fi

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

# Fonction pour journaliser les erreurs
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >> "$HOME/ohmywsl.log"
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
            log_error "$error_msg"
            return 1
        fi
        gum style "$success_msg" --foreground 82
    else
        info_msg "$info_msg"
        if ! eval "$command"; then
            error_msg "$error_msg"
            log_error "$error_msg"
            return 1
        fi
        success_msg "$success_msg"
    fi
}

gum_confirm() {
    local prompt="$1"
    if $FULL_INSTALL; then
        return 0 
    else
        gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "$prompt"
    fi
}

gum_choose() {
    local prompt="$1"
    shift
    local selected=""
    local options=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --selected=*)
                selected="${1#*=}"
                ;;
            *)
                options+=("$1")
                ;;
        esac
        shift
    done

    if $FULL_INSTALL; then
        if [ -n "$selected" ]; then
            echo "$selected"
        else
            echo "${options[@]}"
        fi
    else
        gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --header="$prompt" --selected="$selected" "${options[@]}"
    fi
}

configure_noninteractive() {
    sudo debconf-set-selections <<< "gdm3 shared/default-x-display-manager select gdm3"
    export DEBIAN_FRONTEND=noninteractive
}

# Fonction de nettoyage
cleanup() {
    execute_command "sudo apt autoremove -y && sudo apt clean" "Nettoyage des paquets inutiles"
    execute_command "rm -f $HOME/zsh.sh $HOME/xfce.sh" "Suppression des scripts temporaires"
}

# Vérification des dépendances
check_dependencies() {
    local deps=(wget curl)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            execute_command "sudo apt install -y $dep" "Installation de $dep"
        fi
    done
}

check_dependencies
sudo -v
show_banner

info_msg "❯ Configuration du système"
wslconfig_file="/mnt/c/Users/$USER/.wslconfig"
content="[wsl2]
guiApplications=false
[network]
generateResolvConf = false"

execute_command "echo -e \"$content\" | tr -d '\r' > \"$wslconfig_file\"" "Création du fichier .wslconfig"

execute_command "sudo apt update -y" "Recherche de mises à jour"
execute_command "sudo apt upgrade -y" "Mise à jour des paquets"
configure_noninteractive

## Installation des paquets

packages=(xfce4 xfce4-goodies xwayland nautilus ark jq)

install_and_configure_gdm3() {
    execute_command "sudo DEBIAN_FRONTEND=noninteractive apt install -y gdm3" "Installation de gdm3"
    execute_command "echo 'gdm3 shared/default-x-display-manager select gdm3' | sudo debconf-set-selections" "Définition de gdm3 comme gestionnaire par défaut"
    execute_command "sudo dpkg-reconfigure gdm3" "Configuration de gdm3"
    execute_command "sudo systemctl enable gdm3" "Activation du service gdm3"
}

install_and_configure_gdm3

for package in $packages; do
    execute_command "sudo DEBIAN_FRONTEND=noninteractive apt install -y $package" "Installation de $package"
done

# Installation de ZSH
info_msg "❯ Configuration du shell"
if $USE_GUM; then
    if gum_confirm "Installer zsh ?"; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh && chmod +x zsh.sh" "Téléchargement du script zsh"
        if $FULL_INSTALL; then
            "$HOME/zsh.sh" --gum --full
        else
            "$HOME/zsh.sh" --gum
        fi
    else
        info_msg "𐄂 Installation de zsh refusée"
    fi
else
    read -p $'\e[33mInstaller zsh ? (o/n) : \e[0m' choice
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    if [[ "$choice" =~ ^(oui|o|y|yes)$ ]]; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh && chmod +x zsh.sh" "Téléchargement du script zsh"
        if $FULL_INSTALL; then
            "$HOME/zsh.sh" --full
        else
            "$HOME/zsh.sh"
        fi
    else
        info_msg "𐄂 Installation de zsh refus��e"
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
    local file_name=$(basename "$file")

    if [ -f "$file" ]; then
        execute_command "echo \"$lines_to_add\" >> \"$file\"" "Configuration du fichier $file_name"
    else
        if [ "$create_if_missing" = "true" ]; then
            execute_command "touch \"$file\"" "Création du fichier $file_name"
            execute_command "echo \"$lines_to_add\" >> \"$file\"" "Configuration du fichier $file_name"
        else
            error_msg "Le fichier $file_name n'existe pas"
        fi
    fi
}

add_lines_to_file "$bashrc_path" "true"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path" "false"

add_lines_to_file "$bashrc_path" "true"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path" "false"

## Fonction pour forcer la fermeture de GWSL et des processus associés
force_close_gwsl() {
    info_msg "Fermeture forcée de GWSL et des processus associés"

    local processes=("GWSL.exe" "GWSL_service.exe" "GWSL_vcxsrv.exe" "vcxsrv.exe")
    
    for process in "${processes[@]}"; do
        taskkill.exe /F /IM "$process" >/dev/null 2>&1
    done
    
    if tasklist.exe | grep -qE "GWSL|vcxsrv"; then
        error_msg "Impossible de fermer tous les processus GWSL. Veuillez les fermer manuellement."
    else
        success_msg "✓ Tous les processus GWSL ont été fermés avec succès."
    fi
}

# Fonction pour configurer GWSL
configure_gwsl() {
    local config_file="/mnt/c/Users/$USER/AppData/Roaming/GWSL/settings.json"
    
    # Attendre que le fichier soit créé
    timeout=5
    while [ ! -f "$config_file" ] && [ $timeout -gt 0 ]; do
        sleep 1
        ((timeout--))
    done

    if [ ! -f "$config_file" ]; then
        error_msg "Le fichier de configuration GWSL n'a pas été créé dans le délai imparti."
        return 0
    fi

    # Modifier le fichier de configuration
    execute_command "sed -i 's/\"window_mode\": \"multi\"/\"window_mode\": \"single\"/' \"$config_file\"" "Modification du fichier de configuration GWSL"
}

## Installation de GWSL
install_gwsl() {
    if [ -f "/mnt/c/WSL2-Distros/GWSL/GWSL.exe" ]; then
        success_msg "✓ GWSL est déjà installé"
        execute_command "powershell.exe -Command 'Start-Process -FilePath \"C:\WSL2-Distros\GWSL\GWSL.exe\" -WindowStyle Hidden'" "Exécution de GWSL"
        configure_gwsl && force_close_gwsl
        return 0
    else
        error_msg "✗ GWSL.exe n'a pas été trouvé après l'installation."
        return 0
    fi

    if [ ! -f "/mnt/c/WSL2-Distros/GWSL-145-STORE.zip" ]; then
        execute_command "wget https://archive.org/download/gwsl-145-store/GWSL-145-STORE.zip -P /mnt/c/WSL2-Distros" "Téléchargement de GWSL"
    else
        success_msg "✓ Sources de GWSL déjà téléchargées"
    fi
    
    execute_command "mkdir -p /mnt/c/WSL2-Distros" "Création du répertoire C:\WSL2-Distros"
    execute_command "cd /mnt/c/WSL2-Distros && unzip GWSL-145-STORE.zip && mv GWSL-145-STORE GWSL" "Extraction et configuration de GWSL"

    if [ -f "/mnt/c/WSL2-Distros/GWSL/GWSL.exe" ]; then
        execute_command "/mnt/c/WSL2-Distros/GWSL/GWSL.exe" "Exécution initiale de GWSL"
        configure_gwsl && force_close_gwsl
    else
        error_msg "✗ GWSL.exe n'a pas été trouvé après l'installation."
        return 0
    fi
}

# Fonction pour installer des packages optionnels
optional_packages() {
    local packages=()
    if $USE_GUM; then
        packages=($(gum_choose "Sélectionner avec ESPACE les packages à installer :" --selected="Tout installer" "nala" "eza" "lfm" "bat" "fzf" "Tout installer"))
        if [[ " ${packages[*]} " == *"Tout installer"* ]]; then
            packages=("nala" "eza" "lfm" "bat" "fzf")
        fi
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

    for choice in "${packages[@]}"; do
        case $choice in
            nala) install_package "nala" ;;
            eza) install_eza ;;
            lfm) install_package "lfm" ;;
            bat) install_package "bat" ;;
            fzf) install_package "fzf" ;;
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
info_msg "❯ Configuration additionnelle"
if $USE_GUM; then
    if gum_confirm "Installer des packages supplémentaires ?"; then
        optional_packages
    fi
else
    read -p $"\e[33mInstaller des packages supplémentaires ? (o/n) : \e[0m" choice

    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

    if [[ "$choice" =~ ^(oui|o|y|yes)$ ]]; then
        optional_packages
    fi
fi

# Demander à l'utilisateur s'il souhaite installer GWSL
info_msg "❯ Installation de GWSL"
if $USE_GUM; then
    if gum_confirm "Installer GWSL ?"; then
        install_gwsl
    fi
else
    read -p $'\e[33mInstaller GWSL ? (o/n) : \e[0m' choice
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$choice" =~ ^(oui|o|y|yes)$ ]]; then
        install_gwsl
    fi
fi

execute_command "timeout 5s sudo startxfce4" "Exécution initiale de XFCE4"

## Configuration de XFCE4
info_msg "❯ Configuration de XFCE4"

execute_command "mkdir -p $HOME/.config/xfce4 && \
                cp /etc/xdg/xfce4/xinitrc $HOME/.config/xfce4/xinitrc && \
                touch $HOME/.ICEauthority && \
                chmod 600 $HOME/.ICEauthority && \
                sudo mkdir -p /run/user/$UID && \
                sudo chown -R $UID:$UID /run/user/$UID/" "Attribution des permissions"

# Personnalisation XFCE
if $USE_GUM; then
    if gum_confirm "Installer la personnalisation XFCE ?"; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/xfce.sh && chmod +x xfce.sh" "Téléchargement du script xfce"
        if [ -f "$HOME/xfce.sh" ]; then
            if $FULL_INSTALL; then
                "$HOME/xfce.sh" --gum --full
            else
                "$HOME/xfce.sh" --gum
            fi
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

    if [[ "$choice" =~ ^(oui|o|y|yes)$ ]]; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/xfce.sh && chmod +x xfce.sh" "Téléchargement du script xfce"
        if [ -f "$HOME/xfce.sh" ]; then
            if $FULL_INSTALL; then
                "$HOME/xfce.sh" --full
            else
                "$HOME/xfce.sh"
            fi
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

execute_command "powershell.exe -Command 'Start-Process -FilePath \"C:\WSL2-Distros\GWSL\GWSL.exe\" -WindowStyle Hidden'" "Exécution de GWSL re-configuré"
execute_command "dbus-launch xfce4-session" "Exécution de la session XFCE4"
# TODO : Vérifier si la commande suivante fonctionne
#execute_command "sleep 5" "Attente de 5 secondes"
#execute_command "startxfce4" "Exécution de XFCE4"

# Nettoyage final
cleanup
if $USE_GUM; then
    if gum_confirm "Supprimer les sources d'installation ?"; then
        execute_command "rm -f /mnt/c/WSL2-Distros/GWSL-145-STORE.zip" "Suppression des sources de GWSL"
        execute_command "rm -- \"$0\"" "Suppression du script d'installation"
    fi
else
    read -p $"\e[33mSupprimer les sources d'installation ? (o/n) : \e[0m" choice
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$choice" =~ ^(oui|o|y|yes)$ ]]; then
        execute_command "rm -f /mnt/c/WSL2-Distros/GWSL-145-STORE.zip" "Suppression des sources de GWSL"
        execute_command "rm -- \"$0\"" "Suppression du script d'installation"
    fi
fi

# Définition de zsh comme shell par défaut s'il est installé
if command -v zsh &> /dev/null
then
    execute_command "chsh -s $(which zsh) $USER" "Définition de zsh comme shell par défaut"
    exec zsh
fi