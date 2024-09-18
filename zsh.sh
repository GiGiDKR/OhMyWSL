#!/bin/bash

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
        if gum spin  --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command"; then
            gum style "$success_msg" --foreground 82
        else
            gum style "$error_msg" --foreground 196
            return 1
        fi
    else
        info_msg "$info_msg"
        if eval "$command" > /dev/null 2>&1; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
            return 1
        fi
    fi
}

# Traitement des arguments en ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true ;;
        *) error_msg "Option non reconnue : $1" ;;
    esac
    shift
done

execute_command "sudo apt install -y zsh wget curl git unzip" "Installation de zsh"

# Installation de Oh My Zsh
if $USE_GUM; then
    if gum confirm "Voulez-vous installer Oh-My-Zsh ?"; then
        install_oh_my_zsh=true
    fi
else
    read -p "Voulez-vous installer Oh-My-Zsh ? (o/n) : " choice
    [[ $choice =~ ^[Oo]$ ]] && install_oh_my_zsh=true
fi
if [ "$install_oh_my_zsh" = true ]; then
    execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\" --quiet" "Installation de Oh-My-Zsh"
fi

[ -f "$ZSHRC" ] && cp "$ZSHRC" "${ZSHRC}.bak"
execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/zshrc" "Configuraion de zshrc"

# Installation de PowerLevel10k
if $USE_GUM; then
    if gum confirm "Voulez-vous installer PowerLevel10k ?"; then
        install_powerlevel10k=true
    fi
else
    read -p "Voulez-vous installer PowerLevel10k ? (o/n) : " choice
    [[ $choice =~ ^[Oo]$ ]] && install_powerlevel10k=true
fi

if [ "$install_powerlevel10k" = true ]; then
    execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" --quiet" "Installation de PowerLevel10k"
    execute_command "sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' \"$ZSHRC\"" "Configuration de PowerLevel10k"
    if $USE_GUM; then
        if gum confirm "Installer le prompt OhMyTermux ?"; then
            install_p10k=true
        fi
    else
        read -p "Installer le prompt OhMyTermux ? (o/n) : " choice
        [[ $choice =~ ^[Oo]$ ]] && install_p10k=true
    fi
    if [ "$install_p10k" = true ]; then
        execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/p10k.zsh" "Téléchargement du prompt OhMyTermux"
        echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
    else
        info_msg "Vous pouvez configurer le prompt PowerLevel10k en exécutant 'p10k configure'."
    fi
fi

execute_command "curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/aliases.zsh" "Téléchargement de la configuration des alias"

# Installation des plugins
install_zsh_plugins() {
    if $USE_GUM; then
        PLUGINS=$(gum choose --no-limit --header="Sélectionner avec ESPACE les plugins à installer :" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder" "Tout installer")
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
        read -p "Entrez les numéros des plugins : " plugin_choices
        
        PLUGINS=""
        for choice in $plugin_choices; do
            case $choice in
                1) PLUGINS+="zsh-autosuggestions " ;;
                2) PLUGINS+="zsh-syntax-highlighting " ;;
                3) PLUGINS+="zsh-completions " ;;
                4) PLUGINS+="you-should-use " ;;
                5) PLUGINS+="zsh-abbr " ;;
                6) PLUGINS+="zsh-alias-finder " ;;
                7) PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-abbr zsh-alias-finder" ;;
            esac
        done
    fi
    for PLUGIN in $PLUGINS; do
        install_plugin "$PLUGIN"
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

    # Remplacer la ligne des plugins dans .zshrc avec les nouveaux plugins
    sed -i "/^plugins=(/,/)/c\plugins=(\n\t${PLUGINS}\n)" "$zshrc"

    # Ajouter la ligne fpath+= pour zsh-completions si nécessaire
    if [[ "$PLUGINS" == *"zsh-completions"* ]] && ! grep -q "fpath+=" "$zshrc"; then
        sed -i '/^source $ZSH\/oh-my-zsh.sh$/i\fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src' "$zshrc"
    fi
}

install_zsh_plugins
execute_command "chsh -s $(which zsh)" "Changement du shell par défaut à zsh"
execute_command "source $HOME/.zshrc" "Rechargement de la configuration zsh"