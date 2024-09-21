#!/bin/bash

USE_GUM=false
FULL_INSTALL=false
ZSHRC="$HOME/.zshrc"

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

# Vérification des dépendances
check_dependencies() {
    local dependencies=("wget" "curl" "git" "unzip")
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

# Fonction pour installer ZSH
install_zsh() {
    if ! command -v zsh &> /dev/null; then
        execute_command "sudo apt update && sudo apt install -y zsh" "Installation de ZSH"
    else
        info_msg "ZSH est déjà installé"
    fi
}

# Fonction pour sauvegarder la configuration existante
backup_existing_config() {
    if [ -f "$ZSHRC" ]; then
        local backup_file="${ZSHRC}.bak"
        execute_command "cp '$ZSHRC' '$backup_file'" "Sauvegarde de la configuration ZSH existante"
    else
        info_msg "Aucune configuration ZSH à sauvegarder"
    fi
}


# Fonction pour installer Oh My Zsh
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git '$HOME/.oh-my-zsh' --quiet" "Installation de Oh-My-Zsh"
    else
        info_msg "Oh-My-Zsh est déjà installé"
    fi
}

# Fonction pour installer PowerLevel10k
install_powerlevel10k() {
    if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '$HOME/.oh-my-zsh/custom/themes/powerlevel10k' --quiet" "Installation de PowerLevel10k"
        execute_command "sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' '$ZSHRC'" "Configuration de PowerLevel10k"
    else
        info_msg "PowerLevel10k est déjà installé"
    fi
}

# Fonction pour installer le prompt OhMyWSL
install_ohmywsl_prompt() {
    execute_command "curl -fLo '$HOME/.p10k.zsh' https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/files/p10k.zsh" "Téléchargement du prompt OhMyWSL"
    echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
    echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
}

# Fonction pour installer les plugins
install_zsh_plugins() {
    info_msg "❯ Configuration des plugins"
    local plugins_to_install=()
    if $USE_GUM; then
        plugins_to_install=($(gum_choose "Sélectionner avec ESPACE les plugins à installer :" --selected="Tout installer" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder" "Tout installer"))
        if [[ " ${plugins_to_install[*]} " == *" Tout installer "* ]]; then
            plugins_to_install=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder")
        fi
    else
        info_msg "Sélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :"
        echo
        info_msg "1) zsh-autosuggestions"
        info_msg "2) zsh-syntax-highlighting"
        info_msg "3) zsh-completions"
        info_msg "4) you-should-use"
        info_msg "5) zsh-abbr"
        info_msg "6) zsh-alias-finder"
        info_msg "7) Tout installer"
        echo
        read -p $"\e[33mEntrez les numéros des plugins : \e[0m" plugin_choices
        
        for choice in $plugin_choices; do
            case $choice in
                1) plugins_to_install+=("zsh-autosuggestions") ;;
                2) plugins_to_install+=("zsh-syntax-highlighting") ;;
                3) plugins_to_install+=("zsh-completions") ;;
                4) plugins_to_install+=("you-should-use") ;;
                5) plugins_to_install+=("zsh-abbr") ;;
                6) plugins_to_install+=("zsh-alias-finder") ;;
                7) plugins_to_install=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder") ;;
            esac
        done
    fi

    for plugin in "${plugins_to_install[@]}"; do
        install_plugin "$plugin"
    done

    update_zshrc "${plugins_to_install[@]}"
}

# Fonction pour installer un plugin
install_plugin() {
    local plugin_name=$1
    local plugin_url=""

    case $plugin_name in
        "zsh-autosuggestions") plugin_url="https://github.com/zsh-users/zsh-autosuggestions.git" ;;
        "zsh-syntax-highlighting") plugin_url="https://github.com/zsh-users/zsh-syntax-highlighting.git" ;;
        "zsh-completions") plugin_url="https://github.com/zsh-users/zsh-completions.git" ;;
        "you-should-use") plugin_url="https://github.com/MichaelAquilina/zsh-you-should-use.git" ;;
        "zsh-abbr") plugin_url="https://github.com/olets/zsh-abbr" ;;
        "zsh-alias-finder") plugin_url="https://github.com/akash329d/zsh-alias-finder" ;;
    esac

    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/$plugin_name" ]; then
        execute_command "git clone '$plugin_url' '$HOME/.oh-my-zsh/custom/plugins/$plugin_name' --quiet" "Installation de $plugin_name"
    else
        info_msg "$plugin_name est déjà installé"
    fi
}

# Fonction pour mettre à jour la configuration de ZSH
update_zshrc() {
    local plugins=("$@")
    local default_plugins=(git command-not-found copyfile node npm vscode web-search timer)
    plugins+=("${default_plugins[@]}")

    # Supprimer les doublons
    readarray -t unique_plugins < <(printf '%s\n' "${plugins[@]}" | sort -u)

    local new_plugins_section="plugins=(\n"
    for plugin in "${unique_plugins[@]}"; do
        new_plugins_section+="\t$plugin\n"
    done
    new_plugins_section+=")"

    execute_command "sed -i '/^plugins=(/,/)/c\\${new_plugins_section}' '$ZSHRC'" "Ajout des plugins dans .zshrc"

    if ! grep -q "source \$ZSH/oh-my-zsh.sh" "$ZSHRC"; then
        echo -e "\n\nsource \$ZSH/oh-my-zsh.sh\n" >> "$ZSHRC"
    fi

    if [[ " ${unique_plugins[*]} " == *" zsh-completions "* ]]; then
        if ! grep -q "fpath+=.*zsh-completions" "$ZSHRC"; then
            sed -i "1ifpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" "$ZSHRC"
        fi
    fi
}

# Fonction principale
main() {
    info_msg "❯ Configuration de ZSH"
    check_dependencies
    install_zsh

    # Demander à l'utilisateur s'il souhaite sauvegarder la configuration existante
    if $USE_GUM; then
        if gum_confirm "Sauvegarder la configuration ZSH ?"; then
            backup_existing_config
        fi
    else
        read -p $'\e[33mSauvegarder la configuration ZSH existante ? (o/n) : \e[0m' choice
        [[ $choice =~ ^[Oo]$ ]] && backup_existing_config
    fi

    # Installation de Oh My Zsh
    if $USE_GUM; then
        if gum_confirm "Installer Oh-My-Zsh ?"; then
            install_oh_my_zsh
        fi
    else
        read -p $'\e[33mInstaller Oh-My-Zsh ? (o/n) : \e[0m' choice
        [[ $choice =~ ^[Oo]$ ]] && install_oh_my_zsh
    fi

    # Configuration de base de ZSH
    execute_command "curl -fLo '$ZSHRC' https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/files/zshrc" "Téléchargement de .zshrc"

    # Installation de PowerLevel10k
    if $USE_GUM; then
        if gum_confirm "Installer PowerLevel10k ?"; then
            install_powerlevel10k
            if gum_confirm "Installer le prompt OhMyWSL ?"; then
                install_ohmywsl_prompt
            else
                info_msg "Vous pouvez configurer le prompt PowerLevel10k en exécutant 'p10k configure'."
            fi
        fi
    else
        read -p $'\e[33mInstaller PowerLevel10k ? (o/n) : \e[0m' choice
        if [[ $choice =~ ^[Oo]$ ]]; then
            install_powerlevel10k
            read -p $'\e[33mInstaller le prompt OhMyWSL ? (o/n) : \e[0m' choice
            if [[ $choice =~ ^[Oo]$ ]]; then
                install_ohmywsl_prompt
            else
                info_msg "Vous pouvez configurer le prompt PowerLevel10k en exécutant 'p10k configure'."
            fi
        fi
    fi

    # Installation de la configuration des alias
    execute_command "curl -fLo '$HOME/.oh-my-zsh/custom/aliases.zsh' https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/files/aliases.zsh" "Configuration des alias communs"

    # Installation des plugins
    install_zsh_plugins

    # TODO Test à effectuer
    # Rechargement de la configuration zsh
    #execute_command "source $HOME/.zshrc" "Rechargement de la configuration zsh"

    # Définition de zsh comme shell par défaut
    #execute_command "chsh -s $(which zsh) $USER" "Définition de zsh comme shell par défaut" true
}

# Ajoutez cette fonction pour gérer les confirmations
gum_confirm() {
    local prompt="$1"
    if $FULL_INSTALL; then
        return 0
    else
        gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "$prompt"
    fi
}

# Ajoutez cette fonction pour gérer les choix multiples
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
        gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=8 --header="$prompt" --selected="$selected" "${options[@]}"
    fi
}

main