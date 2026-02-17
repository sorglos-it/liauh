# LIAUH - Changelog

All notable changes to LIAUH are documented in this file.

## [0.3] - 2026-02-17

### Changed
- **Menu System Redesigned** - New header/footer structure for cleaner UI
  - `menu_header($title, $version)` - Unified header formatting
  - `menu_footer($show_back)` - Unified footer with Quit + system info
  - All menus now use consistent box-based layout
  
- **Context-Aware Navigation** - Back button only shows when needed
  - `CONTEXT_FROM` global tracks where user came from
  - LIAUH menu shows "Back" only when accessed from repo selector
  - Direct access to LIAUH (no repo menu) shows no Back button
  
- **Code Quality**
  - Removed dynamic padding calculations from menus
  - Fixed ANSI color codes (proper shell quoting with `$'...'`)
  - Cleaner menu item formatting (aligned numbering)
  
- **Repository Sync Logic**
  - Decoupled `enabled` and `auto_update` flags
    - `enabled=true` → show in menu
    - `auto_update=true` → git pull on startup (independent)
  - Local directories work without git initialization
  - Better error messages for missing URLs

- **Bug Fixes**
  - Fixed `repo_get_name()` path handling (double-slash issue)
  - Fixed logging function names in repos.sh
  - Fixed color code rendering in terminal output
  - Fixed demo-scripts handling (local repo, no clone attempts)

### Internal
- All logging uses consistent `msg_info/msg_warn/msg_err` from core.sh
- Menu functions refactored for consistency
- Reduced code duplication in navigation loops

## [0.2] - 2026-02-15

### Added
- **Multi-Repository Custom Script Hub**
  - `custom/repo.yaml` for repository configuration
  - Independent `custom.yaml` per repository
  - Auto-cloning and auto-updating support
  
- **Git Authentication Options**
  - SSH with key auto-resolution (custom/keys/ → ~/.ssh/)
  - HTTPS with Personal Access Token
  - HTTPS Basic Auth with environment variables
  - Public repositories (no auth)
  
- **Repository Management**
  - `repo_init()` - Initialize repositories on startup
  - `repo_sync_all()` - Clone and update all configured repos
  - `repo_list_enabled()` - Filter enabled repositories
  - SSH key management in custom/keys/ (auto-.gitignore)
  
- **Menu Integration**
  - `menu_repositories()` - Top-level selector (LIAUH + Custom Repos)
  - `menu_show_custom_repo()` - Scripts from custom repos
  - `menu_show_custom_repo_actions()` - Actions in custom repos
  - Separate menu entries for LIAUH vs Custom repos
  
- **Menu Restructuring**
  - Top-level repository selector
  - LIAUH Scripts branch (categories → scripts → actions)
  - Custom Repos branch (independent per repository)
  - Automatic detection and categorization

### Documentation
- README.md: Installation and quick start
- DOCS.md: Comprehensive guide with examples
- SCRIPTS.md: System scripts reference table
- CHANGES.md: This file

### Fixed
- Fixed path resolution for LIAUH_DIR in libraries
- Fixed package manager auto-detection on all distributions
- Fixed sudo execution model (individual scripts, not LIAUH)

## [0.1] - Initial Release

### Features
- 13 production system management scripts
- Support for Debian, Red Hat, Arch, SUSE, Alpine, Proxmox
- Package manager auto-detection (apt, dnf, yum, pacman, zypper, apk)
- YAML-based script configuration
- Parameter passing via comma-separated strings
- Interactive menu system
- Debug mode support
- Comprehensive error handling

### Scripts
- System updates: ubuntu.sh, debian.sh
- System config: linux.sh
- Web servers: apache.sh, nginx.sh
- Containers: docker.sh, portainer.sh, portainer-client.sh
- Database: mariadb.sh
- Special: proxmox.sh, pikvm-v3.sh
- Tools: compression.sh, ca-cert-update.sh

---

**Version History**

| Version | Date | Status | Notes |
|---------|------|--------|-------|
| 0.3 | 2026-02-17 | Current | UI redesign, context-aware navigation |
| 0.2 | 2026-02-15 | Stable | Multi-repo hub, authentication |
| 0.1 | 2025-12-XX | Archived | Initial release |
