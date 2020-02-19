#!/bin/sh

# For ABPKit, if any local default blocklists do not exist, update all of them.

source "Scripts/blocklists-default.txt"
if [ ! -f $LOCAL_EASYLIST ] ||
   [ ! -f $LOCAL_EASYLIST_PLUS_EXCEPTIONS ] ||
   [ ! -f $CB_EASYLIST_PLUS_EXCEPTIONS ] ||
   [ ! -f $CB_LOCAL_EASYLIST_PLUS_EXCEPTIONS ]
then
"Scripts/update-bundled-blocklists.sh"
fi
