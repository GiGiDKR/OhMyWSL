#!/bin/bash

set -e

USE_GUM=false
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

execute_command "sudo apt install -y zsh wget curl git unzip" "Installation de zsh et des dépendances"

# Demander à l'utilisateur les options d'installation
if $USE_GUM; then
    install_oh_my_zsh=$(gum confirm "Voulez-vous installer Oh-My-Zsh ?" && echo true || echo false)
    install_powerlevel10k=$(gum confirm "Voulez-vous installer PowerLevel10k ?" && echo true || echo false)
    [ "$install_powerlevel10k" = true ] && install_p10k=$(gum confirm "Installer le prompt OhMyTermux ?" && echo true || echo false)
else
    read -p "Voulez-vous installer Oh-My-Zsh ? (o/n) : " choice
    [[ $choice =~ ^[Oo]$ ]] && install_oh_my_zsh=true || install_oh_my_zsh=false

    read -p "Voulez-vous installer PowerLevel10k ? (o/n) : " choice
    [[ $choice =~ ^[Oo]$ ]] && install_powerlevel10k=true || install_powerlevel10k=false

    if [ "$install_powerlevel10k" = true ]; then
        read -p "Installer le prompt OhMyTermux ? (o/n) : " choice
        [[ $choice =~ ^[Oo]$ ]] && install_p10k=true || install_p10k=false
    fi
fi

[ -f "$ZSHRC" ] && cp "$ZSHRC" "${ZSHRC}.bak"

if [ "$install_oh_my_zsh" = true ]; then
    execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\" --quiet" "Installation de Oh-My-Zsh"
fi

execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/zshrc >/dev/null 2>&1" "Configuration de zshrc"

if [ "$install_powerlevel10k" = true ]; then
    execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" --quiet" "Installation de PowerLevel10k"
    execute_command "sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' \"$ZSHRC\"" "Configuration de PowerLevel10k"

    if [ "$install_p10k" = true ]; then
        execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/p10k.zsh" "Téléchargement du prompt OhMyTermux"
        echo -e "\n# Pour personnaliser le prompt, exécutez \`p10k configure\` ou modifiez ~/.p10k.zsh." >> "$ZSHRC"
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
    else
        info_msg "Vous pouvez configurer le prompt PowerLevel10k en exécutant 'p10k configure'."
    fi
fi

execute_command "curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/aliases.zsh" "Téléchargement de la configuration des alias"

# Fonction pour installer les plugins ZSH
install_zsh_plugins() {
    local plugins_to_install

    if $USE_GUM; then
        plugins_to_install=$(gum choose --no-limit --header="Sélectionnez les plugins à installer (utilisez ESPACE) :" \
            "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" \
            "you-should-use" "zsh-abbr" "zsh-alias-finder" "Installer tout")
    else
        info_msg "Sélectionner les plugins à installer :"
        echo
        info_msg "1) zsh-autosuggestions"
        info_msg "2) zsh-syntax-highlighting"
        info_msg "3) zsh-completions"
        info_msg "4) you-should-use"
        info_msg "5) zsh-abbr"
        info_msg "6) zsh-alias-finder"
        info_msg "7) Tout installer"
        echo
        read -p "Entrez vos choix (séparés par des espaces): " choices

        plugins_to_install=""
        for choice in $choices; do
            case $choice in
                1) plugins_to_install+="zsh-autosuggestions " ;;
                2) plugins_to_install+="zsh-syntax-highlighting " ;;
                3) plugins_to_install+="zsh-completions " ;;
                4) plugins_to_install+="you-should-use " ;;
                5) plugins_to_install+="zsh-abbr " ;;
                6) plugins_to_install+="zsh-alias-finder " ;;
                7) plugins_to_install="zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-abbr zsh-alias-finder" ;;
            esac
        done
    fi

    for plugin in $plugins_to_install; do
        install_plugin "$plugin"
    done

    update_zshrc
}

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

    execute_command "git clone \"$plugin_url\" \"$HOME/.oh-my-zsh/custom/plugins/$plugin_name\" --quiet" "Installation de $plugin_name"
}

update_zshrc() {
    local zshrc="$HOME/.zshrc"
    cp "$zshrc" "${zshrc}.bak"
    
    local existing_plugins=$(sed -n '/^plugins=(/,/)/p' "$zshrc" | grep -v '^plugins=(' | grep -v ')' | tr -d ' ')
    
    for plugin in $plugins_to_install; do
        if [[ ! "$existing_plugins" =~ "$plugin" ]]; then
            existing_plugins+=" $plugin"
        fi
    done
    
    sed -i "/^plugins=(/,/)/c\plugins=($existing_plugins)" "$zshrc"
    
    if [[ "$plugins_to_install" == *"zsh-completions"* ]]; then
        if ! grep -q "fpath+=" "$zshrc"; then
            sed -i '/^source $ZSH\/oh-my-zsh.sh$/i\fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src' "$zshrc"
        fi
    fi
}

install_zsh_plugins

execute_command "chsh -s zsh" "Changement du shell par défaut"
execute_command "source $HOME/.zshrc" "Rechargement de la configuration zsh"