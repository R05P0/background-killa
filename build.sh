#!/bin/bash
# Background Killa - Build & Push via ADB
set -e

MODULE_ID="background_killa"
ZIP_NAME="background-killa.zip"
DEVICE_TMP="/sdcard/Download/$ZIP_NAME"

cd "$(dirname "$0")"

echo "==> Building $ZIP_NAME..."
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" \
    module.prop \
    icon.png \
    service.sh \
    monitor.sh \
    action.sh \
    uninstall.sh \
    webroot/ \
    META-INF/ \
    -x "*.DS_Store" "*.gitkeep"

echo "==> Pushing to device..."
adb push "$ZIP_NAME" "$DEVICE_TMP"

echo ""
echo "Done! To install:"
echo "  1. Open Magisk > Modules > Install from storage"
echo "  2. Select: $DEVICE_TMP"
echo "  3. Reboot"
echo ""
echo "After reboot, run:"
echo "  adb forward tcp:8765 tcp:8765"
echo "  Then open: http://localhost:8765"
echo ""

# Optional: direct install if Magisk CLI is available
if adb shell "[ -f /data/adb/magisk/magisk ]" 2>/dev/null; then
    read -r -p "Try direct Magisk install? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        adb shell "magisk --install-module $DEVICE_TMP" && \
        echo "Installed! Reboot your device."
    fi
fi
