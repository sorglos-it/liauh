# LIAUH - Linux Install and Update Helper

**Interactive menu system for managing system installation and update scripts**

## 🚀 Installation

### Option 1: One-liner with wget (Recommended)
```bash
wget -qO - https://raw.githubusercontent.com/sorglos-it/liauh/main/install.sh | bash && ./liauh/liauh.sh
```

### Option 2: One-liner with curl
```bash
curl -sSL https://raw.githubusercontent.com/sorglos-it/liauh/main/install.sh | bash && ./liauh/liauh.sh
```

### Option 3: Git Clone
```bash
git clone https://github.com/sorglos-it/liauh.git
cd liauh && bash liauh.sh
```

### Option 4: Manual Install
```bash
sudo apt-get update && sudo apt-get install -y git
cd ~ && git clone https://github.com/sorglos-it/liauh.git
cd liauh && bash liauh.sh
```

## 📖 Usage

### Start the Interactive Menu
```bash
bash liauh.sh
```

The menu structure depends on your custom repositories:

**With Custom Repositories Enabled:**
```
LIAUH - Linux Install and Update Helper

  1) LIAUH Scripts       ← System Scripts (13 scripts)
  2) Custom: my-scripts  ← Custom Repo 1
  3) Custom: team-tools  ← Custom Repo 2

   q) Quit
```

Select a repository, then choose categories and scripts within it.

**Without Custom Repositories:**
Displays LIAUH system scripts directly (like previous versions).

### Command Line Options

```bash
bash liauh.sh                # Start menu (auto-updates)
bash liauh.sh --no-update    # Start without checking for updates
bash liauh.sh --debug        # Enable debug/verbose output
bash liauh.sh --check-update # Check for updates (don't apply)
bash liauh.sh --update       # Apply updates manually
```

## ✨ Features

- **Interactive Menu** - Easy navigation for non-technical users
- **OS Detection** - Supports Debian, Red Hat, Arch, SUSE, Alpine, Proxmox
- **Auto-Update** - Keeps LIAUH scripts current from GitHub
- **Multi-Repo Support** - Clone multiple custom script repositories with auto-updates
- **Flexible Authentication** - SSH keys, Personal Access Tokens, or public repos
- **SSH Key Management** - Store keys in `custom/keys/` (never committed)
- **Interactive Prompts** - Text input, yes/no questions, number selection
- **Sudo Support** - Individual scripts run with sudo when needed (LIAUH runs as normal user)
- **No Dependencies** - Works with bash, git, and standard tools
- **13 System Scripts** - Pre-built scripts for common Linux management tasks

## 📚 Documentation

For detailed configuration, troubleshooting, and architecture:

- **[DOCS.md](DOCS.md)** - Complete documentation with examples and architecture
- **[SCRIPTS.md](SCRIPTS.md)** - Reference of all available system scripts
- **[custom/repo.yaml](custom/repo.yaml)** - Custom repository configuration template
- **[LICENSE](LICENSE)** - MIT License

## 💻 System Requirements

- Linux (Debian, Red Hat, Arch, SUSE, Alpine, or compatible)
- Bash 4.0+
- Git (for auto-update)
- `sudo` access (if scripts need root)

## 📝 License

MIT License - Free for commercial and personal use

**Author:** Thomas Weirich (Sorglos IT)

See [LICENSE](LICENSE) for full details.

---

## 💝 Support & Donate

If you find LIAUH helpful, please consider supporting its development!

[![PayPal Donate](https://img.shields.io/badge/PayPal-Donate-blue?style=for-the-badge&logo=paypal)](https://www.paypal.com/donate/?hosted_button_id=9U6NJRGR7SE52)

Your support helps maintain and improve LIAUH. Thank you! 🙏

---

**Questions?** See **DOCS.md** for detailed documentation.
