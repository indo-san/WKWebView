#!/bin/sh

# Update bundled block lists in ABPKit.
#
# Run from the project root with:
#
# $ Scripts/update-bundled-blocklists.sh

source "Scripts/blocklists-default.txt"
curl -o "$LOCAL_EASYLIST" "$REMOTE_EASYLIST"
curl -o "$LOCAL_EASYLIST_PLUS_EXCEPTIONS" "$REMOTE_EASYLIST_PLUS_EXCEPTIONS"
cp "$LOCAL_EASYLIST" "$CB_OUTPUT_PATH"
cp "$LOCAL_EASYLIST_PLUS_EXCEPTIONS" "$CB_OUTPUT_PATH"
