# Gatekeeper & Signing Notes

Mac Tool is distributed as an **ad-hoc signed** DMG (no Apple Developer ID certificate).
macOS Gatekeeper will block it by default. Follow one of the steps below.

## First Launch

**Option A — Right-click method (recommended):**
1. Drag Mac Tool to Applications
2. Right-click `Mac Tool.app` → **Open**
3. Click **Open** in the Gatekeeper dialog

**Option B — Terminal:**
```bash
xattr -dr com.apple.quarantine "/Applications/Mac Tool.app"
open "/Applications/Mac Tool.app"
```

## Full Disk Access (Required for Trash cleanup)

Some features (Trash category) require Full Disk Access:

1. Open **System Settings → Privacy & Security → Full Disk Access**
2. Click **+** and add **Mac Tool**
3. Toggle it **on**

> **After each app update:** The ad-hoc signature changes with every rebuild.
> You must remove the old entry and re-add the new one in Full Disk Access,
> otherwise Trash access silently fails.

## Build from Source

```bash
# Prerequisites: Flutter 3.44+, Xcode 15+
git clone <repo>
cd Mac-Tool
flutter pub get
bash scripts/build_dmg.sh
# Output: build/Mac-Tool.dmg
```
