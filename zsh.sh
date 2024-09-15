#!/bin/bash

USE_GUM=false

ZSHRC="$HOME/.zshrc"

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

# Traitement des arguments en ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true ;;
        *) error_msg "Option non reconnue : $1" ;;
    esac
    shift
done

info_msg "----------------------------------------"
info_msg "Installation de zsh..."
execute_command "sudo apt install -y zsh" \
    "zsh installé." \
    "Échec de l'installation de zsh."

info_msg "----------------------------------------"
# Installation de Oh My Zsh
if $USE_GUM; then
    if gum confirm "Voulez-vous installer Oh My Zsh ?"; then
        info_msg "Installation des pré-requis..."
        execute_command "sudo apt install -y wget curl git unzip" \
            "Pré-requis installés." \
            "Échec de l'installation des pré-requis."

        info_msg "Installation de Oh My Zsh..."
        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\" --quiet >/dev/null" \
            "Oh My Zsh installé." \
            "Échec de l'installation de Oh My Zsh."

        execute_command "cp \"$HOME/.oh-my-zsh/templates/zshrc.zsh-template\" \"$ZSHRC\"" \
            "Fichier zshrc copié." \
            "Échec de la copie du fichier zshrc."
    fi
else
    read -p "Voulez-vous installer Oh My Zsh ? (o/n) : " choice

    if [ "$choice" = "o" ]; then
        info_msg "Installation des pré-requis..."
        execute_command "sudo apt install -y wget curl git unzip" \
            "Pré-requis installés." \
            "Échec de l'installation des pré-requis."

        info_msg "Installation de Oh My Zsh..."
        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\" --quiet >/dev/null" \
            "Oh My Zsh installé." \
            "Échec de l'installation de Oh My Zsh."

        execute_command "cp \"$HOME/.oh-my-zsh/templates/zshrc.zsh-template\" \"$ZSHRC\"" \
            "Fichier zshrc copié." \
            "Échec de la copie du fichier zshrc."
    fi
fi

[ -f "$ZSHRC" ] && cp "$ZSHRC" "${ZSHRC}.bak"
execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/zshrc >/dev/null 2>&1" \
    "Configuration zshrc téléchargée." \
    "Échec du téléchargement de la configuration zshrc."

info_msg "----------------------------------------"
# Installation de PowerLevel10k
if $USE_GUM; then
    if gum confirm "Voulez-vous installer PowerLevel10k ?"; then
        info_msg "Installation de PowerLevel10k..."
        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" --quiet >/dev/null || true" \
            "PowerLevel10k installé." \
            "Échec de l'installation de PowerLevel10k."
        execute_command "sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' \"$ZSHRC\"" \
            "Thème PowerLevel10k configuré." \
            "Échec de la configuration du thème PowerLevel10k."

        info_msg "----------------------------------------"
        if gum confirm "Installer le prompt OhMyTermux ?"; then
            info_msg "Téléchargement du prompt PowerLevel10k..."
            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/p10k.zsh" \
                "Prompt PowerLevel10k téléchargé." \
                "Échec du téléchargement du prompt PowerLevel10k."
            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
        else
            info_msg "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
        fi
    fi
else
    read -p "Voulez-vous installer PowerLevel10k ? (o/n) : " choice

    if [ "$choice" = "o" ]; then
        info_msg "Installation de PowerLevel10k..."
        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" --quiet >/dev/null || true" \
            "PowerLevel10k installé." \
            "Échec de l'installation de PowerLevel10k."
        execute_command "sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' \"$ZSHRC\"" \
            "Thème PowerLevel10k configuré." \
            "Échec de la configuration du thème PowerLevel10k."

        info_msg "----------------------------------------"
        read -p "Installer le prompt OhMyTermux ? (o/n) : " choice

        if [ "$choice" = "o" ]; then
            info_msg "Téléchargement du prompt PowerLevel10k..."
            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/p10k.zsh" \
                "Prompt PowerLevel10k téléchargé." \
                "Échec du téléchargement du prompt PowerLevel10k."
            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
        else
            info_msg "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
        fi
    fi
fi

info_msg "----------------------------------------"
# Téléchargement de la configuration
info_msg "Téléchargement de la configuration..."
execute_command "curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/aliases.zsh" \
    "Configuration téléchargée." \
    "Échec du téléchargement de la configuration."

info_msg "----------------------------------------"
# Installation des plugins
install_zsh_plugins() {
    if $USE_GUM; then
        PLUGINS=$(gum choose --no-limit --header="Sélectionner avec ESPACE les plugins à installer :" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder" "Tout installer")
    else
        info_msg "Sélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :"
        info_msg "1) zsh-autosuggestions"
        info_msg "2) zsh-syntax-highlighting"
        info_msg "3) zsh-completions"
        info_msg "4) you-should-use"
        info_msg "5) zsh-abbr"
        info_msg "6) zsh-alias-finder"
        info_msg "7) Tout installer"
        read -p "Entrez les numéros des plugins : " plugin_choices
    fi

    PLUGINS=""
    for choice in $PLUGINS; do
        case $choice in
            "zsh-autosuggestions"|1) PLUGINS+="zsh-autosuggestions " ;;
            "zsh-syntax-highlighting"|2) PLUGINS+="zsh-syntax-highlighting " ;;
            "zsh-completions"|3) PLUGINS+="zsh-completions " ;;
            "you-should-use"|4) PLUGINS+="you-should-use " ;;
            "zsh-abbr"|5) PLUGINS+="zsh-abbr " ;;
            "zsh-alias-finder"|6) PLUGINS+="zsh-alias-finder " ;;
            "Tout installer") PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-abbr zsh-alias-finder" ;;
        esac
    done

    for PLUGIN in $PLUGINS; do
        install_plugin "$PLUGIN"
    done

    update_zshrc
}

install_plugin() {
    local plugin_name=$1
    local plugin_url=""
    info_msg "----------------------------------------"

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
        "$plugin_name installé." \
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

install_zsh_plugins
chsh -s $(which zsh)
source $HOME/.zshrc