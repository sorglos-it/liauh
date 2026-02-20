# Answer.yaml Feature Guide

## Overview

The `custom/answer.yaml` file provides **default values for interactive prompts**. When you run a script, each prompt shows a default value in brackets that you can use by pressing ENTER.

## Quick Example

```yaml
scripts:
  git:
    actions:
      - name: "config"
        prompts:
          - default: "myusername"
          - default: "my@email.com"
```

**In action:**
```
Git username? [myusername]: 
  → Press ENTER → uses "myusername"
  → Type "alice" → uses "alice"

Git email? [my@email.com]: 
  → Press ENTER → uses "my@email.com"
  → Type another email → uses that instead
```

## Key Features

✅ **User always in control**
- All prompts still display
- User decides each value
- Can override any default

✅ **Easier than typing**
- Press ENTER for defaults
- No more repeating values

✅ **No automation**
- Scripts don't auto-execute
- No skipped prompts
- User confirms before running

✅ **Graceful fallback**
- Missing answer.yaml → uses config.yaml defaults
- Invalid YAML → ignores answer.yaml, uses config.yaml
- Missing defaults → uses config.yaml defaults

## File Location

```
ulh/
├── custom/
│   └── answer.yaml  ← Your defaults go here
├── config.yaml      ← Built-in script definitions
└── ...
```

## YAML Structure

### Basic Format

```yaml
scripts:
  script_name:
    actions:
      - name: "action_name"
        prompts:
          - default: "first_prompt_default"
          - default: "second_prompt_default"
```

### Important Rules

1. **Exact Matching**
   - `script_name` must match `config.yaml` exactly
   - `action_name` must match the action name exactly
   - Case-sensitive!

2. **Array Indexing**
   - Arrays are 0-based
   - First prompt = index 0
   - Second prompt = index 1

3. **Syntax**
   - Use quotes: `default: "value"`
   - Booleans: `default: "yes"` or `default: "no"`
   - Numbers: `default: "42"` (quoted)

4. **Optional Defaults**
   - Omit `default:` key if a prompt shouldn't have one
   - Example: Don't provide default for passwords

## Examples

### Example 1: Git Configuration

```yaml
git:
  actions:
    - name: "config"
      prompts:
        - default: "john-doe"
        - default: "john@example.com"
```

Run it:
```
$ ulh.sh
# Select: git → config
Git username? [john-doe]: 
  ENTER
Git email? [john@example.com]: 
  ENTER
```

### Example 2: Mixed Defaults

```yaml
mariadb:
  actions:
    - name: "install"
      prompts:
        - default: "50"          # Use port 50
        - default: ""            # No default (user must type)
        - default: "yes"         # Enable backups
```

### Example 3: Custom Scripts

```yaml
myapp:
  actions:
    - name: "setup"
      prompts:
        - default: "/opt/myapp"
        - default: "8080"
        - default: "true"
```

### Example 4: Multiple Actions

```yaml
docker:
  actions:
    - name: "install"
      prompts:
        - default: "dockeruser"
    
    - name: "configure"
      prompts:
        - default: "/var/lib/docker"
        - default: "yes"
```

## Troubleshooting

### Defaults not showing?

**Check:**
1. Answer.yaml file exists at `custom/answer.yaml`
2. Script/action names match exactly (case-sensitive)
3. YAML syntax is valid (check indentation)

**Test YAML syntax:**
```bash
cd ulh
./lib/yq/yq-amd64 eval 'keys' custom/answer.yaml
# Should output: - scripts
```

### Invalid YAML error?

ULH silently falls back to config.yaml defaults. To debug:

```bash
cd ulh
./lib/yq/yq-amd64 eval '.' custom/answer.yaml
# Shows any YAML parsing errors
```

### Default not being used?

**Check the path:**
```bash
cd ulh
./lib/yq/yq-amd64 eval '.scripts.git.actions[] | select(.name=="config") | .prompts[0].default' custom/answer.yaml
```

This should output your default value.

## Performance

- Answer.yaml is loaded once per session
- Cached in memory after first load
- No performance impact
- Validation is fast (<10ms)

## Security

⚠️ **Be careful with sensitive data:**
- Don't store passwords in answer.yaml
- Don't commit answer.yaml with secrets
- Use environment variables for sensitive defaults

Example (better practice):
```bash
# Don't do this:
prompts:
  - default: "mysecretpassword"

# Do this instead:
# Let user type sensitive values (no default)
prompts:
  - default: ""  # User types password
```

## Migration from Manual Scripts

### Before (typing each time)
```
$ ulh.sh
git config
Git username? []: john
Git email? []: john@example.com
(repeated many times)
```

### After (with answer.yaml)
```
$ ulh.sh
git config
Git username? [john]: ENTER
Git email? [john@example.com]: ENTER
```

## Best Practices

1. **Group related defaults**
   ```yaml
   git:
     actions:
       - name: "config"
         prompts:
           - default: "my-corp-user"
           - default: "corporate@company.com"
   ```

2. **Document your defaults**
   ```yaml
   # Corporate git setup
   git:
     actions:
       - name: "config"
         prompts:
           - default: "john-smith"       # Your username
           - default: "j.smith@corp.com" # Corporate email
   ```

3. **Keep sensitive data out**
   ```yaml
   postgres:
     actions:
       - name: "install"
         prompts:
           - default: "mydb"             # DB name is safe
           - default: ""                 # Password: user must type!
   ```

4. **Start with essentials**
   - Add defaults for prompts you use frequently
   - Start small, expand as needed

## Related Files

- **custom/answer.yaml** - Your default values
- **config.yaml** - Built-in script definitions
- **DOCS.md** - Full ULH documentation
- **README.md** - Quick start guide

## Questions?

See the main DOCS.md file or check `custom/answer.yaml` for examples.
