# LIAUH - Complete Documentation

**Linux Install and Update Helper - Interactive menu system for managing system scripts**

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Directory Structure](#directory-structure)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Custom Script Repositories](#custom-script-repositories)
6. [Creating Scripts](#creating-scripts)
7. [Architecture](#architecture)
8. [API Reference](#api-reference)
9. [Troubleshooting](#troubleshooting)

---

## Getting Started

LIAUH is a Bash-based system for organizing and executing scripts through an interactive menu interface. It handles:

- **Script organization** by category
- **Interactive prompts** before execution (text, yes/no, number)
- **OS compatibility filtering** (Debian, Red Hat, Arch, etc.)
- **Automatic sudo handling** with variable passthrough
- **Custom user scripts** in separate directory

### Features

✅ No chmod +x needed - LIAUH handles permissions automatically
✅ Variables from prompts passed securely to scripts
✅ OS detection and compatibility filtering
✅ Separate system and custom script management
✅ Full English documentation
✅ Debug mode for troubleshooting

---

## Directory Structure

```
liauh/
├── liauh.sh                 # Main entry point
├── config.yaml              # System scripts configuration
├── lib/                     # Library functions
│   ├── core.sh
│   ├── yaml.sh
│   ├── menu.sh
│   ├── execute.sh
│   ├── repos.sh             # Repository management (NEW)
│   └── yq/                  # yq binaries (auto-installed)
├── scripts/                 # System scripts (13 production)
├── custom/                  # Custom repositories hub
│   ├── repo.yaml            # Configure custom repos
│   ├── .gitkeep
│   ├── .gitignore           # Ignore cloned repos locally
│   ├── custom-scripts/      # Cloned repo 1
│   ├── company-tools/       # Cloned repo 2
│   └── ...                  # More cloned repos
├── README.md                # Quick reference
├── DOCS.md                  # This file
├── SCRIPTS.md               # Available scripts reference
├── CHANGES.md               # Version history
└── LICENSE                  # MIT License
│
├── lib/                 # Core libraries
│   ├── core.sh          # Colors, OS detection, utilities
│   ├── yaml.sh          # YAML configuration reader
│   ├── menu.sh          # Interactive menu system
│   ├── execute.sh       # Script execution with prompts
│   └── yq/              # yq binary (architecture-specific)
│       ├── yq-amd64     # x86_64 architecture
│       ├── yq-arm64     # ARM 64-bit
│       ├── yq-arm       # ARM 32-bit
│       └── yq-386       # x86 32-bit
│
├── scripts/             # System scripts directory
│   ├── test_script.sh   # Test/example script
│   ├── template.sh      # Template for new scripts
│   └── [your scripts]   # Add your scripts here
│
└── custom/              # Custom scripts directory (optional)
    └── [your scripts]   # User-defined scripts
```

---

## Quick Start

### Install and Run LIAUH

**With wget:**
```bash
wget -qO - https://raw.githubusercontent.com/sorglos-it/liauh/main/install.sh | bash && ./liauh/liauh.sh
```

**With curl:**
```bash
curl -sSL https://raw.githubusercontent.com/sorglos-it/liauh/main/install.sh | bash && ./liauh/liauh.sh
```

**Manual:**
```bash
git clone https://github.com/sorglos-it/liauh.git
cd liauh && bash liauh.sh
```

### CLI Options

```bash
# Interactive menu (default - auto-updates on startup)
bash liauh.sh

# Start without auto-update check
bash liauh.sh --no-update

# Enable debug output
bash liauh.sh --debug

# Check for updates (requires git repository)
bash liauh.sh --check-update

# Apply latest updates manually (requires git repository)
bash liauh.sh --update
```

### Auto-Update Behavior

By default, LIAUH automatically:
1. Checks for updates from GitHub on every startup
2. Applies updates silently if available
3. Continues normally if update fails or offline
4. **Preserves** your `custom/` scripts and `custom.yaml`

**Why automatic?**
- Stay secure with latest patches
- Get bug fixes automatically
- System scripts stay current
- No manual intervention needed

**To disable auto-update:**
```bash
bash liauh.sh --no-update
```

**How it works:**
- Fetches from remote: `git fetch origin`
- Pulls changes: `git pull origin main/master`
- Falls back gracefully if git unavailable or offline
- Updates are non-blocking - if they fail, LIAUH starts anyway

### Repository Selector (With Custom Repos)

If custom repositories are enabled in `custom/repo.yaml`:

```
+==============================================================================+
|LIAUH - Linux Install and Update Helper                       VERSION: 0.2|
+==============================================================================+

  Detected: ubuntu (debian) - 25.10

   1) LIAUH Scripts
   2) Custom: My Scripts
   3) Custom: Company Tools

──────────────────────────────────────────────────────────────────────────────
   q) Quit
──────────────────────────────────────────────────────────────────────────────

  Choose: 
```

**Select 1:** LIAUH system scripts (13 built-in scripts)
**Select 2+:** Custom repository scripts (from cloned repos)

### LIAUH System Scripts Menu

```
+==============================================================================+
|LIAUH - Linux Install and Update Helper                       VERSION: 0.2|
+==============================================================================+

  System Scripts

   1) system
   2) database
   3) webserver

──────────────────────────────────────────────────────────────────────────────
  b) Back   q) Quit
──────────────────────────────────────────────────────────────────────────────

  Choose: 
```

### Custom Repository Menu

```
+==============================================================================+
|Custom: My Scripts                                             VERSION: 0.2|
+==============================================================================+

   1) deployment
   2) monitoring
   3) backup

──────────────────────────────────────────────────────────────────────────────
  b) Back   q) Quit
──────────────────────────────────────────────────────────────────────────────

  Choose: 
```

---

## Configuration

### Main Config: config.yaml

Defines all available scripts with categories, actions, and prompts.

```yaml
# scripts:
#   [script_name]:                    # Unique identifier
#     description: "..."              # One-line description
#     category: "..."                 # Group: database, webserver, security, language, etc.
#     file: "..."                     # Script filename in scripts/ directory
#     needs_sudo: true                # (optional) Only if script requires root access
#                                     # If omitted or false, script runs as normal user
#     
#     os_only: ubuntu                 # (optional) Limit to specific distro (ubuntu, debian, etc.)
#     os_family: [debian|redhat|arch|suse|alpine]    # (optional) Limit to OS family
#     os_exclude:                     # (optional) Exclude specific distros
#       - raspbian
#     
#     actions:                        # What the script can do
#       - name: "install"             # Action name (shown in menu)
#         parameter: "install"        # Parameter passed to script ($1)
#         description: "..."          # (optional) Action description
#         prompts:                    # (optional) Questions to ask user
#           - question: "Domain?"
#             variable: "DOMAIN"      # Environment variable name
#             type: "text"            # Input type: text, yes/no, number
#             default: "localhost"    # (optional) Default value
```

### Example 1: Ubuntu-Only Script (using os_only)

```yaml
scripts:
  ubuntu-update:
    description: "Update Ubuntu system (handles 25.04 → 25.10 upgrades)"
    category: "system"
    file: "ubuntu-update.sh"
    needs_sudo: true
    os_only: ubuntu
    
    actions:
      - name: "update"
        parameter: "update"
        prompts: []
```

**Note:** Use `os_only: ubuntu` for Ubuntu-specific scripts (don't show on Debian, Linux Mint, etc.)

### Example 2: Debian Family Script

```yaml
scripts:
  apache2:
    description: "Apache2 web server"
    category: "webserver"
    file: "apache2.sh"
    needs_sudo: true
    os_family: debian
    os_exclude:
      - raspbian
    
    actions:
      - name: "install"
        parameter: "install"
        description: "Install Apache2"
        prompts:
          - question: "Domain name?"
            variable: "DOMAIN"
            type: "text"
            default: "localhost"
          
          - question: "Enable SSL?"
            variable: "SSL_ENABLED"
            type: "yes/no"
            default: "no"
          
          - question: "Admin email?"
            variable: "ADMIN_EMAIL"
            type: "text"
            default: "admin@localhost"
      
      - name: "remove"
        parameter: "remove"
        description: "Uninstall Apache2"
        prompts:
          - question: "Keep config files?"
            variable: "KEEP_CONFIG"
            type: "yes/no"
            default: "yes"
```

### Custom Scripts: custom.yaml

Same format as config.yaml, but:
- Must specify `script_dir: custom`
- Scripts stored in `custom/` directory instead of `scripts/`
- Only shown if scripts exist and are compatible with OS
- **NOT tracked by git** - customize locally without affecting repository

```yaml
script_dir: custom

scripts:
  my_backup:
    description: "My backup script"
    category: "maintenance"
    file: "my_backup.sh"
    needs_sudo: true
    
    actions:
      - name: "backup"
        parameter: "backup"
        prompts:
          - question: "Backup destination?"
            variable: "BACKUP_DIR"
            type: "text"
            default: "/backups"
```

### .gitignore

LIAUH includes a `.gitignore` file that excludes:
- `custom/` directory - your personal scripts
- `custom.yaml` - your personal configuration
- `logs/` - temporary log files

This allows you to safely pull updates from GitHub without conflicts with your local customizations.

**Workflow:**
```bash
# You customize locally
cp scripts/template.sh custom/my_script.sh
cat > custom.yaml << EOF
script_dir: custom
scripts:
  my_script:
    ...
EOF

# Updates from GitHub don't affect your custom files
bash liauh.sh --update
# custom/ and custom.yaml are untouched
```

### Prompt Types

| Type | Values | Example |
|------|--------|---------|
| **text** | Any non-empty string | `example.com`, `my_name` |
| **yes/no** | y, yes, n, no (case-insensitive) | `y` → becomes `yes`, `n` → becomes `no` |
| **number** | Digits only | `8080`, `30` |

---

## Custom Script Repositories

Configure multiple custom script repositories with different authentication methods. All enabled repositories are cloned/pulled to `custom/` folder on startup.

### Quick Start

#### Option 1: SSH with custom/keys/ (Recommended)

1. **Copy your SSH key:**
   ```bash
   cp ~/.ssh/id_rsa liauh/custom/keys/id_rsa
   chmod 600 liauh/custom/keys/id_rsa
   ```

2. **Edit `custom/repo.yaml`:**
   ```yaml
   repositories:
     my-scripts:
       name: "My Scripts"
       url: "git@github.com:your-org/your-repo.git"
       path: "my-scripts"
       auth_method: "ssh"
       ssh_key: "id_rsa"
       enabled: true
       auto_update: true
   ```

3. **Create custom.yaml in your repo:**
   ```yaml
   scripts:
     my-tool:
       description: "My custom tool"
       path: "scripts/my-tool.sh"
       needs_sudo: false
   ```

4. **Run LIAUH:**
   ```bash
   bash liauh.sh
   ```
   Your scripts appear in the menu!

#### Option 2: HTTPS with Personal Access Token

1. **Create GitHub token:**
   - Go to https://github.com/settings/tokens/new
   - Select scopes: `repo`, `read:org`

2. **Set environment variable:**
   ```bash
   export LIAUH_CUSTOM_TOKEN="ghp_xxxxxxxxxxxx"
   ```

3. **Edit `custom/repo.yaml`:**
   ```yaml
   repositories:
     custom-scripts:
       name: "My Custom Scripts"
       url: "https://github.com/your-org/liauh-custom.git"
       path: "custom-scripts"
       auth_method: "https_token"
       token: "${LIAUH_CUSTOM_TOKEN}"
       enabled: true
       auto_update: true
   ```

4. **Run LIAUH:**
   ```bash
   bash liauh.sh
   ```

### Repository Configuration

#### Basic Structure

```yaml
repositories:
  repo-id:                    # Unique identifier
    name: "Display Name"      # Human-readable name
    url: "..."                # Git repository URL
    path: "folder-name"       # Cloned to custom/folder-name
    auth_method: "ssh|https_token|https_basic|none"
    enabled: true|false       # Enable/disable this repo
    auto_update: true|false   # Auto-clone/pull on startup
    # auth-specific fields below...
```

#### Authentication Methods

##### 1. SSH (Recommended for personal use)

```yaml
repositories:
  my-repo:
    name: "My Scripts"
    url: "git@github.com:org/repo.git"
    path: "my-repo"
    auth_method: "ssh"
    ssh_key: "id_rsa"           # File in custom/keys/ OR full path
    ssh_passphrase: "${SSH_PASSPHRASE}"  # Optional, if key is encrypted
    enabled: true
    auto_update: true
```

**SSH Key Setup - Option A (custom/keys/):**
```bash
cp ~/.ssh/id_rsa custom/keys/id_rsa
chmod 600 custom/keys/id_rsa
ssh-add custom/keys/id_rsa  # If encrypted
```

**SSH Key Setup - Option B (~/.ssh/):**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
# Then reference in config: ssh_key: "~/.ssh/id_rsa"
```

##### 2. HTTPS Token (Recommended for CI/CD)

```yaml
repositories:
  github-repo:
    name: "GitHub Scripts"
    url: "https://github.com/org/repo.git"
    path: "github-repo"
    auth_method: "https_token"
    token: "${LIAUH_TOKEN}"     # GitHub Personal Access Token
    enabled: true
    auto_update: true
```

**Token Setup:**
1. Create token: https://github.com/settings/tokens/new
2. Select scopes: `repo`, `read:org`
3. Set environment: `export LIAUH_TOKEN="ghp_xxxxxxxxxxxx"`

##### 3. HTTPS Basic Auth (Legacy)

```yaml
repositories:
  gitlab-repo:
    name: "GitLab Scripts"
    url: "https://gitlab.com/org/repo.git"
    path: "gitlab-repo"
    auth_method: "https_basic"
    username: "${GIT_USERNAME}"
    password: "${GIT_PASSWORD}"
    enabled: true
    auto_update: true
```

**Setup:**
```bash
export GIT_USERNAME="your-username"
export GIT_PASSWORD="your-password"
```

##### 4. Public (No Auth)

```yaml
repositories:
  public-repo:
    name: "Public Community Scripts"
    url: "https://github.com/org/public-repo.git"
    path: "public-repo"
    auth_method: "none"
    enabled: true
    auto_update: true
```

### Global Settings

```yaml
update_settings:
  auto_update_on_start: true      # Update enabled repos on startup
  retry_on_failure: 3             # Retry count on clone/pull failure
  retry_delay_seconds: 5          # Delay between retries
```

### Environment Variables

Always use environment variables for secrets. Never hardcode credentials!

```bash
# GitHub Personal Access Token
export LIAUH_TOKEN="ghp_xxxxxxxxxxxx"

# Multiple tokens (different repos)
export LIAUH_CUSTOM_TOKEN="ghp_yyyyyyyyyyyyy"
export LIAUH_COMPANY_TOKEN="ghp_zzzzzzzzzzzzz"

# SSH passphrase (if key is encrypted)
export SSH_KEY_PASSPHRASE="my-key-passphrase"

# Username/password (for private git servers)
export GIT_USERNAME="myuser"
export GIT_PASSWORD="mypass"
```

Reference them in `repo.yaml` with `${VARIABLE_NAME}` syntax.

### Auto-Update Control

Use `auto_update: false` to prevent automatic updates (pulls) on each startup:

```yaml
repositories:
  frozen-version:
    name: "v1.0 Frozen Version"
    url: "git@github.com:company/scripts-v1.git"
    path: "frozen-v1"
    auth_method: "ssh"
    ssh_key: "id_rsa"
    enabled: true
    auto_update: false          # Don't auto-pull (keep frozen)
```

When `auto_update: false`:
- Repository is cloned initially (if not present)
- Subsequent runs skip pulling updates
- Useful for: frozen versions, large repos (performance), local-only repos

When `auto_update: true` (default):
- Repository is cloned initially (if not present)
- Every startup: git pull to get latest changes
- Works for both public and private repos
- No security concerns (read/pull doesn't require write access)

### How It Works

1. **Startup:**
   - LIAUH reads `custom/repo.yaml`
   - For each enabled repository:
     - If `auto_update: true` and repo doesn't exist → Clone it
     - If `auto_update: true` and repo exists → Pull latest
     - If `auto_update: false` → Skip update

2. **Script Loading:**
   - Each cloned repo has `custom.yaml` with script definitions
   - All scripts are merged into LIAUH menu
   - Scripts run like system scripts but from custom repos

3. **Execution:**
   - User selects script from menu
   - LIAUH executes with parameters: `bash script.sh "action,VAR1=val1"`
   - Script operates normally

### Repository Troubleshooting

#### Repository not cloning

**SSH:**
```bash
# Check key exists and has correct permissions
ls -la custom/keys/id_rsa
chmod 600 custom/keys/id_rsa

# Test SSH access
ssh -i custom/keys/id_rsa -T git@github.com
```

**HTTPS Token:**
```bash
# Verify token is set
echo $LIAUH_TOKEN

# Test git clone manually
git clone https://${LIAUH_TOKEN}@github.com/org/repo.git test
```

#### Repositories not appearing in menu

1. Check `repo.yaml` has `enabled: true`
2. Verify cloned repo path has `custom.yaml`
3. Verify scripts exist in path specified in `custom.yaml`
4. Run LIAUH with debug: `bash liauh.sh --debug`

#### SSH key passphrase keeps being asked

If your SSH key is encrypted and passphrase is requested each time:

```bash
# Start SSH agent
eval $(ssh-agent -s)

# Add key to agent
ssh-add custom/keys/id_rsa

# LIAUH will use the cached key from the agent
```

Or set passphrase via environment variable:
```bash
export SSH_KEY_PASSPHRASE="your-passphrase"
bash liauh.sh
```

---

## Creating Scripts

### Step 1: Create script file

No chmod +x needed - LIAUH handles permissions automatically!

```bash
cp scripts/template.sh scripts/my_script.sh
```

### Step 2: Edit your script

```bash
#!/bin/bash
# My Script
ACTION="${1:-install}"

case "$ACTION" in
    install)
        echo "Domain: $DOMAIN"
        echo "Port: $PORT"
        # Your installation logic
        exit 0
        ;;
    remove)
        # Your removal logic
        exit 0
        ;;
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
```

### Step 3: Register in config.yaml or custom.yaml

```yaml
my_script:
  description: "My Script"
  category: "custom"
  file: "my_script.sh"
  needs_sudo: false
  
  actions:
    - name: "install"
      parameter: "install"
      prompts:
        - question: "Domain?"
          variable: "DOMAIN"
          type: "text"
          default: "example.com"
        
        - question: "Port?"
          variable: "PORT"
          type: "number"
          default: "8080"
```

### Step 4: Run LIAUH

Your script appears in the menu under "custom" category.

### Template.sh Reference

Use `scripts/template.sh` as a starting point:

```bash
#!/bin/bash
# Script description

ACTION="${1:-install}"

# Log functions
log_info()    { echo "[INFO] $*"; }
log_error()   { echo "[ERROR] $*" >&2; }
log_success() { echo "[SUCCESS] $*"; }

# Main logic
main() {
    case "$ACTION" in
        install)  handle_install ;;
        remove)   handle_remove ;;
        update)   handle_update ;;
        config)   handle_config ;;
        *)        log_error "Unknown action: $ACTION"; exit 1 ;;
    esac
}

handle_install() {
    log_info "Starting installation..."
    # Your logic here
    log_success "Done"
}

handle_remove() {
    log_info "Starting removal..."
    # Your logic here
    log_success "Done"
}

handle_update() {
    log_info "Starting update..."
    # Your logic here
    log_success "Done"
}

handle_config() {
    log_info "Starting configuration..."
    # Your logic here
    log_success "Done"
}

main
exit $?
```

---

## Architecture

### Startup Flow

```
liauh.sh
  ├─ Set LIAUH_DIR
  ├─ Source libraries: core, yaml, menu, execute, repos
  ├─ detect_os()           → from core.sh
  ├─ yaml_load("config")   → from yaml.sh
  ├─ repo_init()           → from repos.sh (clone/pull custom repos)
  └─ menu_main()           → from menu.sh
      ├─ Check for custom repos
      ├─ If repos exist → menu_repositories()
      │   ├─ Show "LIAUH Scripts" + custom repos
      │   └─ Route to menu_liauh_scripts() or menu_custom_repo_scripts()
      └─ If no repos → menu_liauh_scripts() directly
```

### Execution Flow

**LIAUH System Scripts:**
```
User selects category → selects script → selects action
  ├─ Load action details from config.yaml
  ├─ Count prompts
  ├─ For each prompt:
  │   ├─ Show question + default
  │   ├─ Read input
  │   └─ Validate based on type
  ├─ Ask confirmation: Execute '[action]' now? (y/N)
  ├─ Build parameter string: action,VAR1=val1,VAR2=val2,...
  └─ Execute script:
      ├─ If needs_sudo: true  → sudo bash script.sh "param_string"
      └─ If needs_sudo: false → bash script.sh "param_string"
```

**Custom Repository Scripts:**
```
User selects custom repo → selects script → selects action
  ├─ Load action details from repo/custom.yaml (not config.yaml)
  ├─ Count prompts
  ├─ For each prompt:
  │   ├─ Show question + default
  │   ├─ Read input
  │   └─ Validate based on type
  ├─ Ask confirmation: Execute '[action]' now? (y/N)
  ├─ Build parameter string: action,VAR1=val1,VAR2=val2,...
  └─ Execute script from repo:
      ├─ If needs_sudo: true  → sudo bash repo/scripts/script.sh "param_string"
      └─ If needs_sudo: false → bash repo/scripts/script.sh "param_string"
```

### Permission Handling

No chmod +x needed anywhere!

```bash
# In execute.sh: Auto-fix script permissions
[[ ! -x "$script_path" ]] && chmod +x "$script_path" 2>/dev/null

# In yaml.sh: Auto-fix yq binary permissions
[[ -f "$YQ" && ! -x "$YQ" ]] && chmod +x "$YQ" 2>/dev/null
```

Scripts can be distributed with 644 (rw-r--r--) permissions - LIAUH will make them executable when needed.

### Sudo Execution Model

When `needs_sudo: true` is set:

1. **LIAUH runs as normal user** (no sudo required to start LIAUH)
2. **User confirms execution** → "Execute '[action]' now? (y/N)"
3. **LIAUH builds parameter string** → Comma-separated format  
4. **Script executes with sudo** → `sudo bash script.sh "param_string"`
5. **System prompts for password** → (if needed, standard sudo behavior)
6. **Script runs as root** → Only this specific script, not LIAUH

**Security Model:**
- LIAUH stays unprivileged
- Each script with `needs_sudo: true` gets sudo elevation
- Variables passed as arguments (not environment globals)
- No special password handling in LIAUH code
- Sudo credentials managed entirely by OS

**Example:**
```bash
# User runs LIAUH as normal user
$ bash liauh.sh

# User selects action with needs_sudo: true
# LIAUH executes:
$ sudo bash scripts/apache.sh "install,DOMAIN=example.com,SSL=yes"

# Sudo prompts for password (system-level)
# Script runs as root with the provided parameters
```

### Variable Passing

LIAUH passes variables as a **comma-separated parameter string**:

```
install,DOMAIN=example.com,SSL=yes,EMAIL=admin@test.com
```

Your script must parse this string:

```bash
#!/bin/bash

# Parse the comma-separated parameter string
FULL_PARAMS="$1"

# Extract action (everything before first comma)
ACTION="${FULL_PARAMS%%,*}"

# Extract remaining parameters (everything after first comma)
PARAMS_REST="${FULL_PARAMS#*,}"

# Parse variable assignments and export them
if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        if [[ -n "$key" ]]; then
            export "$key=$val"
        fi
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

# Now variables are available
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

if [[ "$SSL_ENABLED" == "yes" ]]; then
    sudo apt-get install -y ssl-cert  # Script runs as root (via sudo)
fi
```

**The template.sh file includes this parsing code - just copy it!**

### OS Compatibility

LIAUH detects OS and filters scripts automatically:

```bash
# Detect OS
detect_os()
  → Sets OS_FAMILY (debian, redhat, arch, suse, alpine)
  → Sets OS_DISTRO (ubuntu, fedora, arch, etc.)
  → Sets OS_VERSION

# Filter scripts
yaml_os_compatible()
  → Check os_only (whitelist)
  → Check os_family (must match)
  → Check os_exclude (blacklist)
```

Only compatible scripts appear in menu.

---

## API Reference

### Core Library (lib/core.sh)

```bash
# Initialization
detect_os()              # Auto-detect Linux distribution

# Output Functions (all write to stderr)
msg()                    # Generic message
msg_ok()                 # Success message with ✓
msg_err()                # Error message with ✗
msg_warn()               # Warning message with ⚠
msg_info()               # Info message with ℹ
die()                    # Error message and exit 1

# Formatting
header()                 # Display formatted header
separator()              # Display line separator

# OS Info
show_os_info()           # Display detected OS
is_debian_based()        # Check if Debian family
is_redhat_based()        # Check if Red Hat family
is_arch_based()          # Check if Arch family
get_pkg_manager()        # Get package manager (apt, dnf, pacman, etc.)
has_sudo_access()        # Check sudo availability

# Debug
debug()                  # Print debug message (only if --debug)
```

### YAML Library (lib/yaml.sh)

```bash
# Configuration
yaml_load()              # Load YAML file (config or custom)

# Categories & Scripts
yaml_categories()        # Get all script categories
yaml_scripts()           # Get all script names
yaml_scripts_by_cat()    # Get scripts in category

# Script Info
yaml_info()              # Get script metadata
yaml_script_path()       # Get full path to script file
yaml_action_count()      # Get number of actions
yaml_action_name()       # Get action name
yaml_action_param()      # Get action parameter
yaml_action_description()# Get action description

# Prompts
yaml_prompt_count()      # Get number of prompts for action
yaml_prompt_field()      # Get prompt field (question, variable, type, default)
yaml_prompt_var()        # Get prompt variable name

# OS Compatibility
yaml_os_compatible()     # Check if script compatible with OS
```

### Menu Library (lib/menu.sh)

```bash
# Display
menu_show_main()         # Show main category menu
menu_show_category()     # Show scripts in category
menu_show_actions()      # Show actions for script
menu_show_custom()       # Show custom scripts

# Navigation
menu_main()              # Main menu loop
menu_category()          # Category selection loop
menu_actions()           # Action selection loop
menu_custom()            # Custom scripts loop

# Utilities
menu_valid_num()         # Validate number input
menu_error()             # Show error and wait
menu_confirm()           # Ask yes/no confirmation
```

### Execute Library (lib/execute.sh)

```bash
execute_action()         # Collect prompts, confirm, execute script
_prompt_by_type()        # Prompt with validation
```

---

## Troubleshooting

### Issue: Script not appearing in menu

**Checks:**
1. File exists in correct directory
   ```bash
   ls -la scripts/my_script.sh
   ls -la custom/my_script.sh
   ```

2. Script registered in YAML
   ```bash
   grep "my_script:" config.yaml
   grep "my_script:" custom.yaml
   ```

3. OS is compatible
   ```bash
   bash liauh.sh --debug
   # Check detected OS in output
   ```

4. custom.yaml has script_dir if in custom/
   ```yaml
   script_dir: custom  # Must be present
   ```

### Issue: Variables not passed to script

**Check:**
- Variable name in YAML matches what you use in script
  ```yaml
  variable: "DOMAIN"  # In config.yaml
  ```
  ```bash
  echo "$DOMAIN"      # In script
  ```

- Script is in correct directory per script_dir
  ```yaml
  # For scripts/ directory (system scripts)
  file: "my_script.sh"  # Default location
  
  # For custom/ directory (custom scripts)
  script_dir: custom
  file: "my_script.sh"  # In custom/ directory
  ```

### Issue: Colors not showing correctly

**Solution:** Ensure printf %b is used for ANSI codes

```bash
# Wrong (ANSI codes won't render):
echo "${C_GREEN}Success${C_RESET}"

# Correct (ANSI codes render properly):
printf "%b%s%b\n" "$C_GREEN" "Success" "$C_RESET"
```

### Issue: "No custom scripts available"

Happens when:
1. custom.yaml doesn't exist
2. custom/ directory doesn't exist
3. Scripts in custom.yaml have incompatible OS settings
4. Script files don't exist in custom/

**Fix:** Create custom.yaml and custom/ directory:
```bash
mkdir -p custom/
cp scripts/template.sh custom/my_script.sh
cat > custom.yaml << 'EOF'
script_dir: custom
scripts:
  my_script:
    description: "My custom script"
    category: "custom"
    file: "my_script.sh"
    needs_sudo: false
    actions:
      - name: "run"
        parameter: "run"
        prompts: []
EOF
```

### Issue: "yq not found/executable"

yq binaries are automatically made executable. If this fails:

**Check architecture:**
```bash
uname -m
# x86_64 → uses yq-amd64
# aarch64 → uses yq-arm64
# armv7l → uses yq-arm
# i686 → uses yq-386
```

**Verify file exists:**
```bash
ls -la lib/yq/
```

**Manual fix:**
```bash
chmod +x lib/yq/yq-amd64  # for x86_64
chmod +x lib/yq/yq-*      # for all
```

### Issue: Script fails with "Permission denied"

Scripts are made executable automatically, but if manual execution fails:

```bash
# Test outside LIAUH
bash scripts/my_script.sh install

# Check exit code
echo $?
```

### Issue: Running scripts with sudo

LIAUH runs as a normal user. When a script has `needs_sudo: true` in config.yaml:

**How it works:**
1. You run: `bash liauh.sh` (normal user, no sudo needed)
2. LIAUH reads config.yaml and sees script needs sudo
3. LIAUH executes: `sudo bash script.sh "action,DOMAIN=value,PORT=8080"`
4. System prompts for your sudo password (if needed)
5. Script runs with root access, receives parameters as arguments

**Example:**
```bash
#!/bin/bash
# Your script receives sudo'd execution
# Parameters come as arguments: "install,DOMAIN=example.com,PORT=8080"

ACTION="${1%%,*}"
# Parse parameters...

# These run as root (sudo executed us):
apt-get update          # Works - script is already root
apt-get install pkg     # Works - script is already root
```

**Security model:**
- LIAUH stays unprivileged
- Only specific scripts get sudo elevation
- Variables passed as arguments (not globals)
- Clean parameter passing prevents injection

**If password is requested:**
- This is normal - sudo is prompting the user
- Verify your sudoers configuration: `sudo -l`
- System administrator can configure passwordless sudo if desired

3. If sudo still prompts, ask your system admin to check:
   - sudoers `timestamp_timeout` setting (default 15 minutes)
   - `NOPASSWD` entries in sudoers

### Issue: "sudo: no password was provided" or auth failure

**Possible causes:**
1. User is not in sudoers
2. Sudo requires password but user is in NOPASSWD group
3. TTY issues in non-interactive environment

**Check sudo access:**
```bash
sudo -l  # List sudo permissions
sudo -n true  # Test passwordless sudo
```

**Test script with sudo:**
```bash
bash scripts/my_script.sh install  # Direct execution
sudo bash scripts/my_script.sh install  # With sudo
```

### Debug Mode

Run with debug output to see what's happening:

```bash
bash liauh.sh --debug 2>&1 | head -50
```

Output shows:
- Detected OS
- Config file loaded
- Category detection
- Script compatibility checks

---

## Best Practices

### Script Design

1. **Always support multiple actions**
   ```bash
   case "$ACTION" in
       install)  ;;
       remove)   ;;
       update)   ;;
       config)   ;;
   esac
   ```

2. **Use clear logging**
   ```bash
   log_info "Starting..."
   log_error "Failed: reason"
   log_success "Completed"
   ```

3. **Return proper exit codes**
   ```bash
   exit 0          # Success
   exit 1          # General error
   exit 2          # Misuse of shell command
   ```

4. **Parse LIAUH parameters correctly**
   
   LIAUH passes parameters as: `action,VAR1=val1,VAR2=val2,...`
   
   Always include the parsing code from template.sh:
   ```bash
   #!/bin/bash
   FULL_PARAMS="$1"
   ACTION="${FULL_PARAMS%%,*}"
   PARAMS_REST="${FULL_PARAMS#*,}"
   
   if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
       while IFS='=' read -r key val; do
           [[ -n "$key" ]] && export "$key=$val"
       done <<< "${PARAMS_REST//,/$'\n'}"
   fi
   
   # Now use $DOMAIN, $PORT, etc. normally
   ```

### Configuration Design

1. **Use meaningful defaults**
   ```yaml
   - question: "Listen port?"
     variable: "PORT"
     type: "number"
     default: "80"           # Common default
   ```

2. **Group related scripts by category**
   ```yaml
   category: "database"
   category: "webserver"
   category: "security"
   ```

3. **Document with descriptions**
   ```yaml
   description: "Apache2 with SSL support"
   ```

4. **Set needs_sudo only when required**
   ```yaml
   # Only set if script REQUIRES root access
   # If omitted, defaults to false (optional field)
   needs_sudo: true   # Only for scripts that need root
   ```

### File Organization

1. **Keep scripts modular**
   - One script = one service/tool
   - Multiple actions = multiple ways to manage it

2. **No chmod needed**
   - Copy templates without chmod +x
   - LIAUH handles permissions

3. **Test outside LIAUH first**
   ```bash
   bash scripts/my_script.sh install
   ```

---

## Examples

### Example 1: Simple Install Script

**scripts/nginx.sh:**
```bash
#!/bin/bash
# Parse comma-separated parameters from LIAUH
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

case "$ACTION" in
    install)
        echo "Installing Nginx for domain: $DOMAIN"
        sudo apt-get update
        sudo apt-get install -y nginx
        # Configure for $DOMAIN
        exit 0
        ;;
    remove)
        echo "Removing Nginx"
        sudo apt-get remove -y nginx
        exit 0
        ;;
esac
```

**In config.yaml:**
```yaml
nginx:
  description: "Nginx web server"
  category: "webserver"
  file: "nginx.sh"
  needs_sudo: true
  os_family: debian
  
  actions:
    - name: "install"
      parameter: "install"
      prompts:
        - question: "Server domain?"
          variable: "DOMAIN"
          type: "text"
          default: "example.com"
```

### Example 2: Multi-Action Script

**scripts/mysql.sh:**
```bash
#!/bin/bash
# Parse comma-separated parameters from LIAUH
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

case "$ACTION" in
    install)
        echo "Installing MySQL..."
        echo "Root password: $MYSQL_ROOT_PASSWORD"
        sudo apt-get install -y mysql-server
        exit 0
        ;;
    remove)
        echo "Removing MySQL..."
        [[ "$KEEP_DATA" == "yes" ]] && echo "Keeping data"
        sudo apt-get remove -y mysql-server
        exit 0
        ;;
    backup)
        echo "Backing up to: $BACKUP_DIR"
        sudo mysqldump -u root -p$(cat /root/.my.cnf) --all-databases > "$BACKUP_DIR/backup.sql"
        exit 0
        ;;
esac
```

**In config.yaml:**
```yaml
mysql:
  description: "MySQL Database"
  category: "database"
  file: "mysql.sh"
  needs_sudo: true
  
  actions:
    - name: "install"
      parameter: "install"
      prompts:
        - question: "Root password?"
          variable: "MYSQL_ROOT_PASSWORD"
          type: "text"
          default: ""
    
    - name: "remove"
      parameter: "remove"
      prompts:
        - question: "Keep data?"
          variable: "KEEP_DATA"
          type: "yes/no"
          default: "yes"
    
    - name: "backup"
      parameter: "backup"
      prompts:
        - question: "Backup location?"
          variable: "BACKUP_DIR"
          type: "text"
          default: "/backups"
```

---

## Version

LIAUH v0.2 - 2025

---

## Summary

✅ **No chmod +x needed** - LIAUH handles permissions
✅ **Variables auto-exported** - Access via $VARIABLE_NAME
✅ **OS auto-detected** - Scripts filtered by compatibility
✅ **Prompts validated** - Input type checking (text/yes-no/number)
✅ **Sudo handled** - Automatic privilege escalation
✅ **Fully documented** - Comments in English
✅ **Easy to extend** - Template provided, just register in YAML

For updates and contributions, check the repository.
