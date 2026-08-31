-- Sets DMG window appearance after mounting
-- Usage: osascript dmg_window.applescript "Volume Name"
on run argv
  set volName to item 1 of argv
  tell application "Finder"
    tell disk volName
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to {200, 120, 760, 420}
      set viewOptions to the icon view options of container window
      set arrangement of viewOptions to not arranged
      set icon size of viewOptions to 96
      set position of item (volName & ".app") of container window to {140, 150}
      set position of item "Applications" of container window to {420, 150}
      close
      open
      update without registering applications
      delay 2
    end tell
  end tell
end run
