# OhMyWSL 🐧

**Install an Ubuntu WSL2 distribution with a XFCE desktop**

## 🐧 Ubuntu Installation

Open a Windows Terminal and run the following command :

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
> curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.1/install.sh -o install.sh && chmod +x install.sh && ./install.sh --gum
> ```

> [!TIP]
> You can install OhMyWSL with all options (for those who like to copy/paste and go have a coffee :coffee:) with the `-f` or `--full` option :
> ```bash
> curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyWSL/1.0.1/install.sh -o install.sh && chmod +x install.sh && ./install.sh --full
> ```

## 💻 Version history

- 1.0.0 : Initial release

## 📖 To Do

- [X] Add a script to install OhMyWSL on a new Ubuntu installation on WSL2
- [ ] Add a script to install OhMyWSL on a new Debian installation on WSL2