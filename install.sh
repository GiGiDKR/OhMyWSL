#!/bin/bash

USE_GUM=false

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
    echo "Installation de gum..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
}

# Installation de gum si nécessaire
if $USE_GUM; then
    if ! command -v gum &> /dev/null; then
        clear
        install_gum
    fi
fi

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

clear
sudo -v

# Création du fichier .wslconfig
wslconfig_file="/mnt/c/Users/$USER/.wslconfig"
content="[wsl2]
guiApplications=false
[network]
generateResolvConf = false"

clear
info_msg "Création du fichier .wslconfig..."
execute_command "echo -e \"$content\" | tr -d '\r' > \"$wslconfig_file\"" \
    "Le fichier .wslconfig a été créé." \
    "Erreur lors de la création du fichier .wslconfig."

info_msg "----------------------------------------"

## Installation des paquets
packages="xfce4 xfce4-goodies gdm3 xwayland nautilus ark"

info_msg "Mise à jour des listes de paquets..."
execute_command "sudo apt update -y" \
    "Mise à jour des listes de paquets réussie." \
    "Échec de la mise à jour des listes de paquets."

info_msg "Mise à jour des paquets..."
execute_command "sudo apt upgrade -y" \
    "Mise à jour des paquets réussie." \
    "Échec de la mise à jour des paquets."

info_msg "----------------------------------------"

for package in $packages; do
    info_msg "Installation de $package..."
    execute_command "sudo apt install -y $package" \
        "$package installé." \
        "Échec de l'installation de $package."
done

info_msg "----------------------------------------"
# Installation de ZSH
if $USE_GUM; then
    if gum confirm "Installer zsh ?"; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh" \
            "Script zsh.sh téléchargé." \
            "Échec du téléchargement du script zsh.sh."
        execute_command "chmod +x zsh.sh" \
            "Permissions du script zsh.sh modifiées." \
            "Échec de la modification des permissions du script zsh.sh."
        "$HOME/zsh.sh" --gum  # Exécution directe du script avec gum
        if [ $? -eq 0 ]; then
            success_msg "Installation de zsh terminée."
        else
            error_msg "Échec de l'installation de zsh."
        fi
    else
        info_msg "Installation de zsh refusée."
    fi
else
    read -p "Installer zsh ? (o/n) : " reponse_zsh

    reponse_zsh=$(echo "$reponse_zsh" | tr '[:upper:]' '[:lower:]')

    if [ "$reponse_zsh" = "oui" ] || [ "$reponse_zsh" = "o" ] || [ "$reponse_zsh" = "y" ] || [ "$reponse_zsh" = "yes" ]; then
        execute_command "wget https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/zsh.sh" \
            "Script zsh.sh téléchargé." \
            "Échec du téléchargement du script zsh.sh."
        execute_command "chmod +x zsh.sh" \
            "Permissions du script zsh.sh modifiées." \
            "Échec de la modification des permissions du script zsh.sh."
        "$HOME/zsh.sh"  # Exécution directe du script
        if [ $? -eq 0 ]; then
            success_msg "Installation de zsh terminée."
        else
            error_msg "Échec de l'installation de zsh."
        fi
    else
        info_msg "Installation de zsh refusée."
    fi
fi

info_msg "----------------------------------------"
## Configuration réseau
info_msg "Configuration du réseau..."
ip_address=$(ip route | grep default | awk '{print $3; exit;}')

if [ -z "$ip_address" ]; then
    error_msg "Erreur : Impossible de récupérer l'adresse IP."
    exit 1
fi

resolv_conf="/etc/resolv.conf"

if [ ! -f "$resolv_conf" ]; then
    error_msg "Erreur : Le fichier $resolv_conf n'existe pas."
    exit 1
fi

info_msg "Mise à jour du fichier $resolv_conf..."
execute_command "sudo sed -i \"s/^nameserver.*/& ${ip_address}:0.0/\" \"$resolv_conf\"" \
    "Le fichier $resolv_conf a été mis à jour." \
    "Erreur lors de la mise à jour de $resolv_conf."

info_msg "----------------------------------------"
## Configuration des fichiers de shell
bashrc_path="$HOME/.bashrc"
zshrc_path="$HOME/.zshrc"

lines_to_add='
export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}"):0.0
export PULSE_SERVER=tcp:$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}")
echo $DISPLAY'

add_lines_to_file() {
    if [ -f "$1" ]; then
        execute_command "echo \"$lines_to_add\" >> \"$1\"" \
            "Les lignes ont été ajoutées à $1" \
            "Erreur lors de l'ajout des lignes à $1"
    else
        error_msg "Le fichier $1 n'existe pas."
    fi
}

add_lines_to_file "$bashrc_path"
[ -f "$zshrc_path" ] && add_lines_to_file "$zshrc_path"

success_msg "Fichier(s) de configuration shell mis à jour."

info_msg "----------------------------------------"
## Installation de GWSL
# Fonction pour installer GWSL
install_gwsl() {
    info_msg "Installation de GWSL..."
    if [ ! -f "GWSL-145-STORE.zip" ]; then
        execute_command "wget https://github.com/Opticos/GWSL-Source/releases/download/v1.4.5/GWSL-145-STORE.zip" \
            "GWSL téléchargé." \
            "Échec du téléchargement de GWSL."
    else
        info_msg "Le fichier GWSL-145-STORE.zip existe déjà."
    fi

    execute_command "unzip GWSL-145-STORE.zip && mv GWSL-145-STORE/GWSL.exe /mnt/c/Users/Public/Desktop/ && rm -rf GWSL-145-STORE*" \
        "GWSL installé." \
        "Échec de l'installation de GWSL."
}

# Fonction pour installer des packages optionnels
optional_packages() {
    if $USE_GUM; then
        PACKAGES=$(gum choose --no-limit --header="Sélectionner avec ESPACE les packages à installer :" "nala" "eza" "lfm" "bat" "fzf" "Tout installer")
    else
        info_msg "Sélectionnez les packages à installer (séparés par des espaces) :"
        info_msg "1) nala"
        info_msg "2) eza"
        info_msg "3) lfm"
        info_msg "4) bat"
        info_msg "5) fzf"
        read -p "Entrez les numéros des packages : " package_choices
    fi

    for choice in $PACKAGES; do
        case $choice in
            1) install_package "nala" ;;
            2) install_eza ;;
            3) install_package "lfm" ;;
            4) install_package "bat" ;;
            5) install_package "fzf" ;;
            "Tout installer")
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
    info_msg "Installation de $package..."
    execute_command "sudo apt install -y $package" \
        "$package installé." \
        "Échec de l'installation de $package."
    add_aliases_to_rc "$package"
}

# Fonction pour installer eza
install_eza() {
    info_msg "Installation de eza..."
    execute_command "sudo apt install -y gpg ca-certificates" \
        "Prérequis pour eza installés." \
        "Échec de l'installation des prérequis pour eza."

    execute_command "sudo mkdir -p /etc/apt/keyrings && \
                    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
                    echo 'deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main' | sudo tee /etc/apt/sources.list.d/gierens.list && \
                    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
                    sudo apt update && \
                    sudo apt install -y eza" \
        "eza installé." \
        "Échec de l'installation de eza."

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

info_msg "----------------------------------------"
## Configuration de XFCE4
#info_msg "Démarrage de XFCE4..."
#execute_command "timeout 5s sudo startxfce4 &> /dev/null" \
#    "XFCE4 fermé après 5 secondes." \
#    "Erreur lors du démarrage de XFCE4."

info_msg "Configuration de XFCE4..."
execute_command "mkdir -p $HOME/.config/xfce4" \
    "Dossier de configuration XFCE4 créé." \
    "Erreur lors de la création du dossier de configuration XFCE4."

execute_command "cp /etc/xdg/xfce4/xinitrc $HOME/.config/xfce4/xinitrc" \
    "Fichier xinitrc copié." \
    "Erreur lors de la copie du fichier xinitrc."

execute_command "touch $HOME/.ICEauthority" \
    "Fichier .ICEauthority créé." \
    "Erreur lors de la création du fichier .ICEauthority."

execute_command "chmod 600 $HOME/.ICEauthority" \
    "Permissions du fichier .ICEauthority modifiées." \
    "Erreur lors de la modification des permissions du fichier .ICEauthority."

execute_command "sudo mkdir -p /run/user/$UID" \
    "Dossier /run/user/$UID créé." \
    "Erreur lors de la création du dossier /run/user/$UID."

execute_command "sudo chown -R $UID:$UID /run/user/$UID/" \
    "Propriétaire du dossier /run/user/$UID modifié." \
    "Erreur lors de la modification du propriétaire du dossier /run/user/$UID."

execute_command "echo 'echo \$DISPLAY' >> $HOME/.bashrc" \
    "Commande d'affichage de DISPLAY ajoutée à .bashrc." \
    "Erreur lors de l'ajout de la commande d'affichage de DISPLAY à .bashrc."

info_msg "----------------------------------------"
# Personnalisation XFCE
if $USE_GUM; then
    if gum confirm "Installer la personnalisation XFCE ?"; then
        if [ -f "$HOME/xfce.sh" ]; then
            echo "Exécution de la personnalisation XFCE..."
            "$HOME/xfce.sh" --gum  # Exécution directe du script avec gum
            if [ $? -eq 0 ]; then
                success_msg "Personnalisation XFCE terminée."
            else
                error_msg "Erreur lors de l'exécution de la personnalisation XFCE."
            fi
        else
            error_msg "Erreur : Le fichier xfce.sh n'existe pas."
        fi
    else
        info_msg "Installation de la personnalisation XFCE refusée."
    fi
else
    read -p "Installer la personnalisation XFCE ? (o/n) : " reponse

    reponse=$(echo "$reponse" | tr '[:upper:]' '[:lower:]')

    if [ "$reponse" = "oui" ] || [ "$reponse" = "o" ] || [ "$reponse" = "y" ] || [ "$reponse" = "yes" ]; then
        if [ -f "$HOME/xfce.sh" ]; then
            echo "Exécution de la personnalisation XFCE..."
            "$HOME/xfce.sh"  # Exécution directe du script
            if [ $? -eq 0 ]; then
                success_msg "Personnalisation XFCE terminée."
            else
                error_msg "Erreur lors de l'exécution de la personnalisation XFCE."
            fi
        else
            error_msg "Erreur : Le fichier xfce.sh n'existe pas."
        fi
    else
        info_msg "Installation de la personnalisation XFCE refusée."
    fi
fi

info_msg "----------------------------------------"
## Lancement de la session XFCE4
info_msg "Lancement de la session XFCE4..."
execute_command "dbus-launch xfce4-session" \
    "Session XFCE4 lancée." \
    "Échec du lancement de la session XFCE4."
