# Raycast Reproducible Setup

This Ansible playbook includes tasks to restore Raycast configuration on a new Mac.

## Research-Backed Implementation (2024-2025)

This implementation follows the current best practices confirmed by community research:

**Key Research Findings:**
- **`.rayconfig` format**: Gzipped, AES-256-CBC encrypted JSON file containing all settings
- **Password required**: Raycast now mandates password encryption (no unencrypted option as of 2024)
- **Deep links available**: `raycast://extensions/raycast/raycast/import-settings-data` triggers import
- **No headless automation**: GUI interaction required for passphrase entry
- **Community pattern**: Store `.rayconfig` in dotfiles repo, manual import on new machine

**References:**
- [micahkepe/dotfiles](https://github.com/micahkepe/dotfiles) - Stores `Raycast.rayconfig` at repo root
- [jeremy-code's gist](https://gist.github.com/jeremy-code/50117d5b4f29e04fcbbb1f55e301b893) - Documents the encryption/decryption process
- [Raycast Manual](https://manual.raycast.com/preferences) - Official export/import documentation

## How It Works

Raycast's free plan doesn't include cloud sync (Pro feature). This solution uses:

- **`.rayconfig`** - Exported settings file containing extensions, quicklinks, snippets, and hotkeys
- **`com.raycast.macos.plist`** - macOS preferences file for basic app settings
- **Custom scripts** - Your personal Raycast scripts stored in the dotfiles repo

## Initial Setup (One-time)

Export your current Raycast config from your primary Mac:

```bash
cd ~/dv/mac-dev-playbook/files/raycast
./export-raycast.sh
```

Then commit to your dotfiles repo:

```bash
cd ~/dv/dot-files
git add files/raycast/
git commit -m "Add Raycast configuration"
git push
```

## What Gets Backed Up

| Component | Method | Notes |
|-----------|--------|-------|
| Extensions | .rayconfig | Full list + settings |
| Quicklinks | .rayconfig | All quicklinks |
| Snippets | .rayconfig | All snippets |
| Hotkeys/Aliases | .rayconfig | Custom bindings |
| Preferences | plist | Basic app settings |
| Custom Scripts | dotfiles | Scripts in `raycast/scripts/` |

## What Doesn't Get Backed Up

- Clipboard history
- AI chat history
- Floating notes content
- Extension login sessions (you'll need to re-authenticate)

## Restoring on a New Mac

1. Run the playbook:
   ```bash
   ./run.sh
   # or specifically for raycast:
   ansible-playbook main.yml --tags raycast
   ```

2. When prompted during playbook run, manually import the `.rayconfig`:
   - Open Raycast
   - Run: `Import Settings & Data`
   - Select: `~/dv/mac-dev-playbook/files/raycast/raycast.rayconfig`
   - Enter your export passphrase

3. Your extensions, quicklinks, snippets, and hotkeys will be restored.

## Updating Your Backup

After making Raycast changes you want to keep:

```bash
cd ~/dv/mac-dev-playbook/files/raycast
./export-raycast.sh
```

The script will:
- Copy your current plist preferences
- Guide you through exporting a new `.rayconfig`
- Show you the git commands to commit the changes

## Configuration Variables

In `config.yml`:

```yaml
# Enable/disable Raycast configuration
configure_raycast: true

# Copy custom scripts from dotfiles
raycast_custom_scripts: true

# Copy plist preferences file
raycast_plist_file: true
```

## Free Plan Limitations

- No automatic sync (Pro feature at $8-10/month)
- Manual export/import required when changing machines
- Extensions reinstall during import (settings are preserved)
- No automatic backup—you must remember to export periodically

## Troubleshooting

**Import fails with "invalid passphrase"**
- Double-check your passphrase
- If you forgot it, you'll need to reconfigure Raycast manually and create a new export

**Extensions not appearing after import**
- Some extensions require manual installation from the Raycast Store
- Check if the extension requires authentication (e.g., GitHub, Linear)

**Scripts not found**
- Ensure `raycast_custom_scripts: true` is set in config.yml
- Verify scripts exist in your dotfiles at `raycast/scripts/`

## See Also

- [Raycast Pro](https://www.raycast.com/pro) - Cloud sync and other premium features
- `files/raycast/export-raycast.sh` - Export script for backing up your config
