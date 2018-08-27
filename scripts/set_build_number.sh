#!/bin/bash

version=$(sh scripts/version.sh)
bundleversion=$(git rev-list HEAD --count 2>/dev/null)

target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"

for plist in "$target_plist" "$dsym_plist"; do
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $bundleversion" "$plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$plist"
  fi
done
