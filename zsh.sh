#!/bin/bash

ZSHRC="$HOME/.zshrc"

# Fonction pour afficher des messages d'information en bleu
info_msg() {
    echo -e "\e[38;5;33m$1\e[0m"
}

# Fonction pour afficher des messages de succès en vert
success_msg() {
    echo -e "\e[38;5;82m$1\e[0m"
}

# Fonction pour afficher des messages d'erreur en rouge
error_msg() {
    echo -e "\e[38;5;196m$1\e[0m"
}

# Fonction pour exécuter une commande et afficher le résultat
execute_command() {
    local command="$1"
    local success_msg="$2"
    local error_msg="$3"

    if eval "$command"; then
        success_msg "✓ $success_msg"
    else
        error_msg "✗ $error_msg"
        return 1
    fi
}

echo ""
# Installation de Oh My Zsh
info_msg "Voulez-vous installer Oh My Zsh ? (o/n)"
read choice

if [ "$choice" = "o" ]; then
    info_msg "Installation des pré-requis..."
    execute_command "sudo apt install -y wget curl git unzip" \
        "Pré-requis installés avec succès." \
        "Échec de l'installation des pré-requis."

    info_msg "Installation de Oh My Zsh..."
    execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\" --quiet >/dev/null" \
        "Oh My Zsh installé avec succès." \
        "Échec de l'installation de Oh My Zsh."

    execute_command "cp \"$HOME/.oh-my-zsh/templates/zshrc.zsh-template\" \"$ZSHRC\"" \
        "Fichier zshrc copié avec succès." \
        "Échec de la copie du fichier zshrc."
fi

[ -f "$ZSHRC" ] && cp "$ZSHRC" "${ZSHRC}.bak"
execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/zshrc >/dev/null 2>&1" \
    "Configuration zshrc téléchargée avec succès." \
    "Échec du téléchargement de la configuration zshrc."

echo ""
# Installation de PowerLevel10k
info_msg "Voulez-vous installer PowerLevel10k ? (o/n)"
read choice

if [ "$choice" = "o" ]; then
    info_msg "Installation de PowerLevel10k..."
    execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" --quiet >/dev/null || true" \
        "PowerLevel10k installé avec succès." \
        "Échec de l'installation de PowerLevel10k."
    execute_command "sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' \"$ZSHRC\"" \
        "Thème PowerLevel10k configuré avec succès." \
        "Échec de la configuration du thème PowerLevel10k."

    echo ""
    info_msg "Installer le prompt OhMyTermux ? (o/n)"
    read choice

    if [ "$choice" = "o" ]; then
        info_msg "Téléchargement du prompt PowerLevel10k..."
        execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/p10k.zsh" \
            "Prompt PowerLevel10k téléchargé avec succès." \
            "Échec du téléchargement du prompt PowerLevel10k."
        echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
    else
        info_msg "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
    fi
fi

echo ""
# Téléchargement de la configuration
info_msg "Téléchargement de la configuration..."
execute_command "curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/aliases.zsh" \
    "Configuration téléchargée avec succès." \
    "Échec du téléchargement de la configuration."

echo ""
# Installation des plugins
install_zsh_plugins() {
    info_msg "Sélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :"
    info_msg "1) zsh-autosuggestions"
    info_msg "2) zsh-syntax-highlighting"
    info_msg "3) zsh-completions"
    info_msg "4) you-should-use"
    info_msg "5) zsh-abbr"
    info_msg "6) zsh-alias-finder"
    info_msg "7) Tout installer"
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

    for PLUGIN in $PLUGINS; do
        install_plugin "$PLUGIN"
    done

    update_zshrc
}

echo ""
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

    info_msg "Installation $plugin_name..."
    execute_command "git clone \"$plugin_url\" \"$HOME/.oh-my-zsh/custom/plugins/$plugin_name\" --quiet >/dev/null || true" \
        "$plugin_name installé avec succès." \
        "Échec de l'installation de $plugin_name."
}

update_zshrc() {
    local zshrc="$HOME/.zshrc"
    cp "$zshrc" "${zshrc}.bak"
    existing_plugins=$(sed -n '/^plugins=(/,/)/p' "$zshrc" | grep -v '^plugins=(' | grep -v ')' | sed 's/^[[:space:]]*//' | tr '\n' ' ')
    local plugin_list="$existing_plugins"
    for plugin in $PLUGINS; do
        if [[ ! "$plugin_list" =~ "$plugin" ]]; then
            plugin_list+="$plugin "
        fi
    done
    sed -i "/^plugins=(/,/)/c\plugins=(\n\t${plugin_list}\n)" "$zshrc"
    if [[ "$PLUGINS" == *"zsh-completions"* ]]; then
        if ! grep -q "fpath+=" "$zshrc"; then
            sed -i '/^source $ZSH\/oh-my-zsh.sh$/i\fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src' "$zshrc"
        fi
    fi
}

if command -v zsh &> /dev/null; then
    install_zsh_plugins
else
    error_msg "ZSH n'est pas installé. Impossible d'installer les plugins."
fi

chsh