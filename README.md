# OhMyWSL 🐧

**Install an Ubuntu WSL2 distribution with a XFCE desktop**

## 🐧 Ubuntu Installation

Open a Windows Terminal and run the following command to install WSL2 :

```bash
wsl --install
```

After the installation, run the following command to connect to the Ubuntu distribution :
```bash
wsl
```

## 📦 Install OhMyWSL
Run the following command to install OhMyWSL :

```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.1/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

> [!NOTE]
> You can also use the [gum](https://github.com/charmbracelet/gum) interface for execution with the `-g` or `--gum` option :
> ```bash
> curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/install.sh -o install.sh && chmod +x install.sh && ./install.sh --gum
> ```

> [!TIP]
> You can install OhMyWSL with all options (for those who like to copy/paste and go have a coffee :coffee:) with the `-f` or `--full` option :
> ```bash
> curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.0/install.sh -o install.sh && chmod +x install.sh && ./install.sh -g --full 
> ```

## 💻 Version history

- 1.0.0 : Initial release
- 1.0.1 : Add a script to install OhMyWSL on a new Ubuntu installation on WSL2
- 1.0.2 : 

> [!WARNING]
> Preview version (only for internal development) :
> ```bash
> curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/dev/install.sh -o install.sh && chmod +x install.sh && ./install.sh --gum --full
> ```

## 📖 To Do

- [X] Add a script to install OhMyWSL on a new Ubuntu installation on WSL2
- [ ] Add scripts to install OhMyWSL on other Linux distributions on WSL2
