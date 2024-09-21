# OhMyWSL 🌀

**Install an Ubuntu WSL2 distribution with a XFCE desktop**

## Ubuntu Installation

Open a Windows Terminal and run the following command :
```bash
wsl --install
```
After installing you will be logged into the created user session, ready to run the OhMyWSL installation.

## Install OhMyWSL
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/install.sh -o install.sh && chmod +x install.sh && ./install.sh
Run the following command to install OhMyWSL :
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

> [!TIP]
> You can also use the [gum](https://github.com/charmbracelet/gum) interface for execution with the `-g` or `--gum` option :
> ```bash
> curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/install.sh -o install.sh && chmod +x install.sh && ./install.sh --gum
> ```
>
> [!TIP]
> You can also use the `-f` or `--full` option to install OhMyWSL with a full installation of zsh and xfce :
> ```bash
> curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/install.sh -o install.sh && chmod +x install.sh && ./install.sh --gum --full
> ```