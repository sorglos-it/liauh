# Custom Repository Configuration

Configure multiple custom script repositories with different authentication methods. All enabled repositories are cloned/pulled to `custom/` folder on startup.

## Quick Start

### Option 1: SSH with custom/keys/ (Recommended)

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

### Option 2: HTTPS with Personal Access Token

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

## Repository Configuration

### Basic Structure

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

### Authentication Methods

#### 1. SSH (Recommended for personal use)

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

#### 2. HTTPS Token (Recommended for CI/CD)

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

#### 3. HTTPS Basic Auth (Legacy)

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

#### 4. Public (No Auth)

```yaml
repositories:
  public-repo:
    name: "Public Community Scripts"
    url: "https://github.com/org/public-repo.git"
    path: "public-repo"
    auth_method: "none"
    enabled: true
    auto_update: false          # Optional: disable auto-update for read-only
```

## Global Settings

```yaml
update_settings:
  auto_update_on_start: true      # Update enabled repos on startup
  retry_on_failure: 3             # Retry count on clone/pull failure
  retry_delay_seconds: 5          # Delay between retries
```

## Environment Variables

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

## Auto-Update Control

Use `auto_update: false` for read-only repositories:

```yaml
repositories:
  company-standards:
    name: "Company Standards"
    url: "git@github.com:company/standards.git"
    path: "company-standards"
    auth_method: "ssh"
    ssh_key: "id_rsa"
    enabled: true
    auto_update: false          # Don't auto-pull this repo
```

When `auto_update: false`:
- Repository is cloned initially (if not present)
- Subsequent runs skip pulling updates
- Useful for frozen/read-only repos

## Directory Structure

```
liauh/
├── liauh.sh (main entry point)
├── custom/
│   ├── repo.yaml              # Repository configuration
│   ├── repo.md                # This file
│   ├── .gitignore             # Ignore cloned repos
│   ├── keys/                  # SSH keys directory
│   │   ├── .gitignore         # Protect keys from git
│   │   ├── id_rsa
│   │   ├── company_key
│   │   └── ...
│   ├── my-scripts/            # Cloned repo 1
│   │   ├── custom.yaml        # Defines scripts
│   │   ├── scripts/
│   │   │   ├── tool1.sh
│   │   │   └── tool2.sh
│   │   └── ...
│   ├── company-tools/         # Cloned repo 2
│   │   ├── custom.yaml
│   │   └── scripts/
│   └── ...
└── ...
```

## How It Works

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

## Example: Complete Setup

```yaml
repositories:
  # Personal scripts with SSH key in custom/keys/
  personal:
    name: "My Personal Scripts"
    url: "git@github.com:myuser/my-scripts.git"
    path: "personal"
    auth_method: "ssh"
    ssh_key: "id_rsa"
    enabled: true
    auto_update: true

  # Company scripts with GitHub token
  company:
    name: "Company Scripts"
    url: "https://github.com/mycompany/scripts.git"
    path: "company"
    auth_method: "https_token"
    token: "${COMPANY_TOKEN}"
    enabled: true
    auto_update: true

  # Team repo with SSH key and passphrase
  team:
    name: "Team Tools"
    url: "git@github.com:myteam/tools.git"
    path: "team"
    auth_method: "ssh"
    ssh_key: "team_key"
    ssh_passphrase: "${TEAM_KEY_PASSPHRASE}"
    enabled: true
    auto_update: true

  # Public community addons (read-only)
  community:
    name: "Community Addons"
    url: "https://github.com/liauh/addons.git"
    path: "community"
    auth_method: "none"
    enabled: false
    auto_update: false

update_settings:
  auto_update_on_start: true
  retry_on_failure: 3
  retry_delay_seconds: 5
```

**Run:**
```bash
export COMPANY_TOKEN="ghp_xxxxxxxxxxxx"
export TEAM_KEY_PASSPHRASE="passphrase"
bash liauh.sh
```

## Troubleshooting

### Repository not cloning

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

### Repositories not appearing in menu

1. Check `repo.yaml` has `enabled: true`
2. Verify cloned repo path has `custom.yaml`
3. Verify scripts exist in path specified in `custom.yaml`
4. Run LIAUH with debug: `bash liauh.sh --debug`

### SSH key passphrase keeps being asked

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
