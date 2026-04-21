#!/bin/bash
# Script to export Raycast configuration for dotfiles backup
# Run this manually when you want to update your backed-up config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_RAYCAST_DIR="$SCRIPT_DIR"
DOTFILES_DIR="$SCRIPT_DIR/../.."

echo "═══════════════════════════════════════════════════════════════"
echo "Raycast Config Export for Dotfiles"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "This script will:"
echo "1. Copy your Raycast plist preferences"
echo "2. Guide you to export a .rayconfig file"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# Copy plist
echo ""
echo "Copying plist preferences..."
if [ -f "$HOME/Library/Preferences/com.raycast.macos.plist" ]; then
    cp "$HOME/Library/Preferences/com.raycast.macos.plist" "$DOTFILES_RAYCAST_DIR/"
    echo "✓ Plist backed up to: $DOTFILES_RAYCAST_DIR/com.raycast.macos.plist"
else
    echo "⚠ Raycast plist not found at expected location"
fi

# Remove any old rayconfig files
rm -f "$DOTFILES_RAYCAST_DIR"/*.rayconfig

# Guide for .rayconfig export
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "MANUAL STEP REQUIRED: Export Raycast Settings"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "1. Open Raycast"
echo "2. Run: 'Export Settings & Data'"
echo "3. Save the file to: $DOTFILES_RAYCAST_DIR/"
echo "   Note: Raycast will add a timestamp to the filename"
echo "4. Set a passphrase you'll remember (or note it securely)"
echo ""
echo "Press Enter when you've completed the export..."
read

# Find the most recent rayconfig file
RAYCONFIG_FILE=$(ls -t "$DOTFILES_RAYCAST_DIR"/*.rayconfig 2>/dev/null | head -1)

if [ -f "$RAYCONFIG_FILE" ]; then
    # Rename to standard filename
    mv "$RAYCONFIG_FILE" "$DOTFILES_RAYCAST_DIR/raycast.rayconfig"
    echo "✓ .rayconfig found and renamed to: raycast.rayconfig"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "Files ready for git commit:"
    echo "═══════════════════════════════════════════════════════════════"
    ls -la "$DOTFILES_RAYCAST_DIR/"*.plist "$DOTFILES_RAYCAST_DIR/"*.rayconfig 2>/dev/null || true
    echo ""
    echo "Next steps:"
    echo "  cd $DOTFILES_DIR"
    echo "  git add files/raycast/"
    echo "  git commit -m 'Update Raycast configuration'"
    echo "  git push"
else
    echo ""
    echo "⚠ .rayconfig file not found in: $DOTFILES_RAYCAST_DIR/"
fi
