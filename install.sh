#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/micpause"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.mustafa.micpause.plist"
PLIST_DEST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo "==> Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

echo "==> Installing binary to $INSTALL_PATH"
mkdir -p "$INSTALL_DIR"
cp -f "$PROJECT_DIR/.build/release/micpause" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "==> Linking control script to $INSTALL_DIR/micpausectl"
ln -sf "$PROJECT_DIR/micpausectl" "$INSTALL_DIR/micpausectl"

echo "==> Installing LaunchAgent plist to $PLIST_DEST"
mkdir -p "$LAUNCH_AGENTS_DIR"
sed "s|__INSTALL_PATH__|$INSTALL_PATH|g" "$PROJECT_DIR/$PLIST_NAME" > "$PLIST_DEST"

UID_NUM=$(id -u)
echo "==> Bootstrapping launchd service (gui/$UID_NUM)"
launchctl bootout "gui/$UID_NUM/com.mustafa.micpause" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST_DEST"
launchctl enable "gui/$UID_NUM/com.mustafa.micpause" || true
launchctl kickstart -k "gui/$UID_NUM/com.mustafa.micpause"

echo
echo "Installed. Logs:"
echo "  tail -f /tmp/micpause.log /tmp/micpause.err"
echo
echo "To uninstall:"
echo "  launchctl bootout gui/$UID_NUM/com.mustafa.micpause"
echo "  rm \"$PLIST_DEST\" \"$INSTALL_PATH\""
