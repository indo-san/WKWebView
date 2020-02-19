#!/bin/sh

# ABPKit bundled block lists copier.
# Copy bundled block lists based on a plist value inside Xcode.

if [ $(/usr/libexec/PlistBuddy -c "Print installBundledBlockLists" ABPKit-BundledBlockLists.plist) == "true" ]
then
echo "Copying bundled block lists..."
source "Scripts/blocklists-default.txt"
# Override iOS destination:
if [ $EFFECTIVE_PLATFORM_NAME == "-iphonesimulator" ] || [ $EFFECTIVE_PLATFORM_NAME == "-iphoneos" ]
then
RESOURCES=""
fi
cp "$LOCAL_EASYLIST" "$CONFIGURATION_BUILD_DIR/$CONTENTS_FOLDER_PATH/$RESOURCES/$BASENAME_EASYLIST"
cp "$LOCAL_EASYLIST_PLUS_EXCEPTIONS" "$CONFIGURATION_BUILD_DIR/$CONTENTS_FOLDER_PATH/$RESOURCES/$BASENAME_EASYLIST_PLUS_EXCEPTIONS"
fi
