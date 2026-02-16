# LIAUH - Linux Install and Update Helper

**Interactive menu system for managing system scripts**

Quick start: `bash liauh.sh`

For complete documentation, see **DOCS.md**

## Usage

```bash
# Start interactive menu (auto-updates on startup)
bash liauh.sh

# Start without auto-update check
bash liauh.sh --no-update

# Enable debug output
bash liauh.sh --debug

# Check for updates
bash liauh.sh --check-update

# Apply updates manually
bash liauh.sh --update
```

## Auto-Update

LIAUH automatically checks for and applies updates from GitHub on every startup:
- **Non-blocking** - if update fails, LIAUH continues anyway
- **Silent** - no interruption if you're offline
- **Disable with** `--no-update` flag if needed
- **Preserves** your `custom/` directory and `custom.yaml`

## License

MIT License - see [LICENSE](LICENSE) file for details

Users can:
- Use freely (commercial, personal, etc.)
- Modify and redistribute
- Create derivatives

Only requirement: Credit the original author (Thomas Weirich)
