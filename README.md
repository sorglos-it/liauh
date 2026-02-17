# LIAUH - Linux Install and Update Helper

**v0.3** | Unified system management framework with interactive menu system

## 🚀 Installation

### Quick Start (One-liner)
```bash
git clone https://github.com/sorglos-it/liauh.git && cd liauh && bash liauh.sh
```

### From GitHub
```bash
wget -qO - https://raw.githubusercontent.com/sorglos-it/liauh/main/install.sh | bash
curl -sSL https://raw.githubusercontent.com/sorglos-it/liauh/main/install.sh | bash
```

## 📖 Usage

### Start LIAUH
```bash
bash liauh.sh
```

### Menu Structure

```
+==============================================================================+
| LIAUH - Linux Install and Update Helper                         VERSION: 0.3 |
+==============================================================================+
|
   1) LIAUH - Linux Install and Update Helper
   2) Demo Scripts
|
+==============================================================================+
|   q) Quit                                    ubuntu (debian) · v25.10 |
+==============================================================================+

  Choose:
```

**Select a Repository:**
- **LIAUH Scripts** - 13 built-in system management scripts
- **Custom Repos** - Add your own script repositories (enabled via config)

**Then navigate:**
Categories → Scripts → Actions

### CLI Options

| Option | Effect |
|--------|--------|
| `bash liauh.sh` | Start menu (auto-checks for updates) |
| `bash liauh.sh --no-update` | Skip auto-update check |
| `bash liauh.sh --debug` | Enable verbose output |
| `bash liauh.sh --check-update` | Check for updates only |

## ✨ Key Features

- **Interactive Menu** - Clean, intuitive box-based UI
- **Multi-OS Support** - Debian, Ubuntu, Red Hat, Arch, SUSE, Alpine, Proxmox
- **Auto-Update** - Keeps LIAUH current from GitHub
- **Custom Script Repos** - Clone multiple repositories with independent configs
- **Flexible Auth** - SSH keys, Personal Access Tokens, public repos
- **Smart SSH Keys** - Auto-resolve from `custom/keys/` or `~/.ssh/`
- **Interactive Prompts** - Text input, yes/no, selection menus
- **Selective Sudo** - Individual scripts run elevated, LIAUH stays unprivileged
- **Zero Dependencies** - Just bash, git, and standard tools
- **Production Ready** - 15 tested scripts (13 system + 2 reference)

## 🏗️ Architecture

- **liauh.sh** - Main entry point (945 lines)
- **lib/** - 7 focused libraries (colors, core, yaml, menu, execute, repos)
- **scripts/** - 13 production + 2 reference scripts
- **custom/** - User repositories (ignored by git)
- **config.yaml** - System scripts configuration
- **custom/repo.yaml** - Custom repository definitions

## 📋 System Scripts

| Category | Scripts |
|----------|---------|
| System Updates | `ubuntu.sh`, `debian.sh` |
| System Config | `linux.sh` (network, DNS, users) |
| Web Servers | `apache.sh`, `nginx.sh` |
| Containers | `docker.sh`, `portainer.sh` |
| Databases | `mariadb.sh` |
| Appliances | `proxmox.sh`, `pikvm-v3.sh` |
| Tools | `compression.sh`, `ca-cert-update.sh` |

See **[SCRIPTS.md](SCRIPTS.md)** for full reference.

## 🔧 Custom Repositories

Add your own scripts:

1. Create or clone a repository with `custom.yaml`
2. Edit `custom/repo.yaml`:
```yaml
repositories:
  my-scripts:
    name: "My Scripts"
    url: "https://github.com/user/my-scripts.git"
    path: "my-scripts"
    auth_method: "none"
    enabled: true
    auto_update: false
```

3. LIAUH handles cloning, updates, and execution

See **[DOCS.md](DOCS.md)** for authentication setup.

## 📚 Documentation

- **[DOCS.md](DOCS.md)** - Comprehensive guide, architecture, configuration
- **[SCRIPTS.md](SCRIPTS.md)** - System scripts reference table
- **[CHANGES.md](CHANGES.md)** - Version history

## 💻 Requirements

- Linux (Debian, Red Hat, Arch, SUSE, Alpine, or compatible)
- Bash 4.0+
- Git (for updates)
- `sudo` access (if scripts need root)

## 📄 License

MIT License - Free for personal and commercial use

**Author:** Thomas Weirich (Sorglos IT)

---

**Questions?** Check **[DOCS.md](DOCS.md)** for detailed answers.
