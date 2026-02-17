# LIAUH Documentation

Complete guide to LIAUH architecture, configuration, and usage.

## Table of Contents

1. [Architecture](#architecture)
2. [Configuration](#configuration)
3. [Custom Repositories](#custom-repositories)
4. [Menu System](#menu-system)
5. [Script Development](#script-development)
6. [Troubleshooting](#troubleshooting)

---

## Architecture

### Design Philosophy

LIAUH is built for simplicity and maintainability:

- **Single Entry Point** - `liauh.sh` orchestrates everything
- **Focused Libraries** - Each file does one thing well
- **Explicit Over Implicit** - Clear parameter passing, no globals
- **OS Agnostic** - Detects and adapts to any Linux distribution

### File Structure

```
liauh/
├── liauh.sh              # Main entry point (945 lines)
├── lib/
│   ├── colors.sh         # Color codes for output
│   ├── core.sh           # OS detection, logging, utilities
│   ├── yaml.sh           # YAML parsing via yq binary
│   ├── yaml_parser.sh    # Helpers for config parsing
│   ├── menu.sh           # Menu display and navigation
│   ├── execute.sh        # Script execution engine
│   └── repos.sh          # Repository sync and management
├── scripts/              # Production and reference scripts
│   ├── ubuntu.sh, debian.sh, linux.sh, ...
│   ├── template.sh       # Template for new scripts
│   └── test_script.sh    # Testing reference
├── custom/               # User area (git-ignored)
│   ├── repo.yaml         # Custom repository config
│   ├── keys/             # SSH keys (never committed)
│   └── [custom repos]/   # Cloned repositories
├── config.yaml           # System scripts configuration
├── README.md, DOCS.md, CHANGES.md
└── LICENSE
```

### Initialization Flow

1. **liauh.sh** starts → loads libraries
2. **os_detect()** → determines distro + package manager
3. **repo_init()** → syncs custom repositories
4. **menu_main()** → shows repository selector (or LIAUH scripts if no repos)
5. User selects → navigates through menu hierarchy

### Menu Hierarchy

```
Repository Selector (Top Level)
├── LIAUH Scripts
│   └── Categories (Database, System, Tools, etc.)
│       └── Scripts
│           └── Actions
│
└── Custom Repo (per enabled repo)
    └── Scripts
        └── Actions
```

---

## Configuration

### System Scripts (config.yaml)

Controls built-in LIAUH scripts at repo root level:

```yaml
categories:
  Database:
    description: "Database systems"
  System:
    description: "System management"

scripts:
  ubuntu:
    category: "System Updates"
    description: "Ubuntu system management"
    path: "scripts/ubuntu.sh"
    needs_sudo: true
    os_only: "ubuntu"
    
  mariadb:
    category: "Database"
    description: "MariaDB management"
    path: "scripts/mariadb.sh"
    needs_sudo: true
    os_family: ["debian", "redhat"]
    
  compression:
    category: "Tools"
    description: "Archive utilities"
    path: "scripts/compression.sh"
    needs_sudo: false
```

**Fields:**
- `category` - Group in menu
- `description` - Brief description
- `path` - Script location (relative to liauh.sh)
- `needs_sudo` - If true, run with `sudo bash script.sh`
- `os_only` - Single OS (ubuntu, debian, etc.)
- `os_family` - List of OS families (debian, redhat, arch, suse, alpine)
- `os_exclude` - Blacklist specific OSes

---

## Custom Repositories

### Setup

1. Create a custom repository with `custom.yaml`:

```bash
mkdir -p my-scripts/scripts
cat > my-scripts/custom.yaml << 'EOF'
scripts:
  backup:
    description: "Backup utility"
    path: "scripts/backup.sh"
    needs_sudo: false
    
    actions:
      - name: "run"
        parameter: "run"
        description: "Execute backup"
        prompts:
          - question: "Backup directory?"
            variable: "BACKUP_DIR"
            type: "text"
            default: "/backups"
EOF
```

2. Edit `custom/repo.yaml`:

```yaml
repositories:
  my-scripts:
    name: "My Scripts"
    url: "https://github.com/user/my-scripts.git"
    path: "my-scripts"
    auth_method: "none"
    enabled: true
    auto_update: true
```

3. LIAUH handles cloning and setup automatically

### Authentication Methods

#### SSH (Recommended)

```yaml
repositories:
  private-scripts:
    name: "Private Scripts"
    url: "git@github.com:org/private.git"
    path: "private-scripts"
    auth_method: "ssh"
    ssh_key: "id_rsa"  # Looked up in custom/keys/ first
    enabled: true
    auto_update: true
```

Key resolution order:
1. `custom/keys/id_rsa` (recommended - secure storage)
2. `~/.ssh/id_rsa` (fallback - user's home)

**Setup SSH keys:**

```bash
mkdir -p custom/keys
cp ~/.ssh/id_rsa custom/keys/
chmod 600 custom/keys/id_rsa
# .gitignore automatically protects this directory
```

#### HTTPS Token

```yaml
repositories:
  github-scripts:
    name: "GitHub Scripts"
    url: "https://github.com/org/scripts.git"
    path: "github-scripts"
    auth_method: "https_token"
    token: "${GITHUB_TOKEN}"  # From environment variable
    enabled: true
    auto_update: true
```

Set environment variable:
```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
bash liauh.sh
```

#### HTTPS Basic Auth

```yaml
repositories:
  company-scripts:
    name: "Company Scripts"
    url: "https://git.company.com/scripts.git"
    path: "company-scripts"
    auth_method: "https_basic"
    username: "${GIT_USER}"
    password: "${GIT_PASS}"
    enabled: true
    auto_update: false
```

#### Public (No Auth)

```yaml
repositories:
  community:
    name: "Community Scripts"
    url: "https://github.com/public-org/scripts.git"
    path: "community"
    auth_method: "none"
    enabled: true
    auto_update: false
```

### Flag Combinations

| enabled | auto_update | Behavior |
|---------|-------------|----------|
| true | true | Show in menu + auto-pull on startup |
| true | false | Show in menu, no auto-pull |
| false | true | Hidden from menu, but auto-pull on startup |
| false | false | Completely ignored |

**Use Cases:**
- `enabled:true, auto_update:false` - Stable repo, check manually
- `enabled:false, auto_update:true` - Maintenance scripts (hidden, auto-update)
- `enabled:true, auto_update:true` - Live dev repos

### Update Settings

```yaml
update_settings:
  auto_update_on_start: true    # Default: clone/pull repos on startup
  retry_on_failure: 3           # Retry count for clone/pull
  retry_delay_seconds: 5        # Delay between retries
```

---

## Menu System

### Header & Footer

All menus use consistent formatting:

```
+==============================================================================+
| Title                                                          VERSION: 0.3 |
+==============================================================================+
|
   [menu items here]
|
+==============================================================================+
|   b) Back (if applicable)                                                   |
|   q) Quit                                    ubuntu (debian) · v25.10 |
+==============================================================================+

  Choose:
```

**Fixed Width:** 80 characters for all lines

### Menu Types

#### Repository Selector (No Back)
- Shows: LIAUH Scripts + all enabled Custom Repos
- Navigation: Select repository → enter its scripts/categories

#### LIAUH Scripts (Context-Aware Back)
- Shows: Categories (Database, System, Tools, etc.)
- Back button: Only if accessed from Repository Selector
- Navigation: Category → Script → Actions

#### Custom Repo Scripts (Always Back)
- Shows: Scripts from selected repository
- Back button: Always shown
- Navigation: Script → Actions

### Navigation Logic

```
Start LIAUH
    ↓
Has custom repos?
    ├→ Yes: Show Repository Selector
    │       └→ Choose LIAUH or Custom → Script Menu
    └→ No: Show LIAUH Categories directly

Script Menu
    ↓
Choose Category
    ↓
Choose Script
    ↓
Choose Action
    ↓
Execute Script
    ↓
Back to Script Menu / Quit
```

---

## Script Development

### Creating System Scripts

Use `scripts/template.sh` as starting point:

```bash
cp scripts/template.sh scripts/my-script.sh
```

### Parameter Format

Scripts receive comma-separated parameters:

```bash
"action,VAR1=val1,VAR2=val2,VAR3=val3"
```

**Parsing in script:**

```bash
action="${1%%,*}"
IFS=',' read -ra params <<< "${1#*,}"
for param in "${params[@]}"; do
    IFS='=' read -r key value <<< "$param"
    eval "$key='$value'"
done
```

### Script Template

```bash
#!/bin/bash
# my-script.sh - Description

set -euo pipefail

# Parse parameters
action="${1%%,*}"
IFS=',' read -ra params <<< "${1#*,}"
for param in "${params[@]}"; do
    IFS='=' read -r key value <<< "$param"
    eval "$key='${value//\"/}'"
done

# Detect OS and package manager
. /etc/os-release
OS_FAMILY=$(...)
PKG_MANAGER=$(...)

case "$action" in
    install)
        echo "Installing..."
        ;;
    update)
        echo "Updating..."
        ;;
    *)
        echo "Unknown action: $action"
        exit 1
        ;;
esac
```

### Package Manager Detection

```bash
case "$OS_FAMILY" in
    debian) apt install -y package ;;
    redhat) dnf install -y package ;;
    arch) pacman -S --noconfirm package ;;
    suse) zypper install -y package ;;
    alpine) apk add package ;;
esac
```

### Registering in config.yaml

```yaml
scripts:
  my-script:
    category: "Tools"
    description: "My script description"
    path: "scripts/my-script.sh"
    needs_sudo: true  # or false
    os_family: ["debian", "redhat"]
    
    actions:
      - name: "install"
        parameter: "install"
        description: "Install package"
```

---

## Troubleshooting

### Menu not showing

**Problem:** LIAUH starts but no menu appears

**Solution:**
```bash
bash liauh.sh --debug  # Enable verbose output
```

Check:
- `config.yaml` exists and is valid YAML
- Scripts in `path` field exist
- No syntax errors in bash

### Repository not cloning

**Problem:** Custom repo shows "error" or doesn't appear

**Check:**
```bash
# Test git access
git clone [URL] /tmp/test-repo
rm -rf /tmp/test-repo

# Check SSH key
cat custom/keys/id_rsa
ls -la ~/.ssh/id_rsa
```

**Solutions:**
- SSH key permissions: `chmod 600 custom/keys/id_rsa`
- Add key to GitHub/GitLab settings
- Test token: `curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user`
- Check network: `ping github.com`

### Scripts not executing

**Problem:** Selected action does nothing

**Check:**
```bash
# Test script syntax
bash -n scripts/my-script.sh

# Test execution manually
bash scripts/my-script.sh "action,PARAM=value"
```

**Common issues:**
- Missing `needs_sudo: true` in config for privileged operations
- Wrong script path in config
- Script not executable (auto-fixed by LIAUH)
- Syntax errors in script

### Performance issues

**Problem:** Menu is slow or unresponsive

**Solutions:**
- Disable auto-update: `bash liauh.sh --no-update`
- Check network: Custom repos fetch on startup
- Reduce repo count: Disable unused repositories
- Check disk space: Cloned repos consume space

### Colors not showing

**Problem:** ANSI color codes print as literal `\033[1m`

**Causes:**
- TERM environment variable not set
- Old bash version (< 4.0)
- Non-interactive terminal

**Solution:**
```bash
TERM=xterm-256color bash liauh.sh
```

---

## API Reference

### Library Functions

#### core.sh
- `detect_os()` - Detect Linux distro
- `get_pkg_manager()` - Get package manager for current OS
- `msg_ok()`, `msg_err()`, `msg_warn()`, `msg_info()` - Output functions

#### menu.sh
- `menu_header($title, $version)` - Display header
- `menu_footer($show_back)` - Display footer
- `menu_show_repositories()` - Repository selector
- `menu_show_main()` - Categories menu
- `menu_show_category($name)` - Scripts in category
- `menu_show_actions($script)` - Actions for script

#### repos.sh
- `repo_init($config)` - Initialize repositories
- `repo_sync_all($config)` - Sync all enabled repos
- `repo_list_enabled($dir)` - Get list of enabled repos
- `repo_get_name($config, $id)` - Get display name
- `repo_get_path($config, $id)` - Get clone path

#### execute.sh
- `execute_action($script, $action_index)` - Run script action
- `execute_custom_repo_action($repo_path, $script, $action_idx)` - Run custom repo action

---

## Tips & Tricks

### Disable auto-update for offline work
```bash
bash liauh.sh --no-update
```

### Test custom repository locally
```bash
mkdir -p test-repo/scripts
cat > test-repo/custom.yaml << 'EOF'
scripts:
  test:
    description: "Test script"
    path: "scripts/test.sh"
EOF

# Edit custom/repo.yaml:
# path: "test-repo"
# url: ""
# enabled: true
# auto_update: false
```

### Export custom scripts to another LIAUH instance
```bash
cp -r custom/my-repo /path/to/other/liauh/custom/
# Update custom/repo.yaml on other instance
```

---

## Support

For issues, questions, or contributions:

- **Documentation:** See README.md and SCRIPTS.md
- **Issues:** GitHub issue tracker
- **Discussions:** GitHub discussions

---

**Last Updated:** 2026-02-17
**Version:** 0.3
