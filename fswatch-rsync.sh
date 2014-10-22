#!/bin/bash

# @author Clemens Westrup
# @date 07.07.2014

# This is a script to automatically synchronize a local project folder to a
# folder on a remote server.
# It watches the local folder for changes and recreates the local state on the
# target machine as soon as a change is detected.
#
# Automatically ignores syncing files per .gitignore files if run
# in root of git project

# For setup and usage see README.md

################################################################################

PROJECT="fswatch-rsync"
VERSION="0.2.0"

# Sync latency / speed in seconds
LATENCY="1"

# default server setup
TARGET="" # target ssh server

# check color support
colors=$(tput colors)
if (($colors >= 8)); then
    red='\033[0;31m'
    green='\033[0;32m'
    yellow='\033[0;33m'
    nocolor='\033[00m'
else
  red=
  green=
  nocolor=
fi

# Check compulsory arguments
if [[ "$1" = "" || "$2" = "" ]]; then
  echo -e "${red}Error: $PROJECT takes 3 compulsory arguments.${nocolor}"
  echo -n "Usage: fswatch-rsync.sh /local/path user@server:/path"
  exit
else
  LOCAL_PATH="$1"
  TARGET="$2"
fi

# Welcome
echo      ""
echo -e   "${green}$PROJECT v$VERSION.${nocolor}"
echo      "Local source path:  \"$LOCAL_PATH\""
echo      "Remote target: \"$TARGET\""
echo      ""
echo -n   "Performing initial complete synchronization "
echo -n   "(Warning: Target directory will be overwritten "
echo      "with local version if differences occur)."

# Perform initial complete sync
read -n1 -r -p "Press any key to continue (or abort with Ctrl-C)... " key
echo      ""
echo -n   "Synchronizing... "
rsync -avzr -q --delete --force --filter=':- .gitignore' $LOCAL_PATH $TARGET
echo      "done."
echo      ""

# Watch for changes and sync (exclude hidden files)
echo    "Watching for changes. Quit anytime with Ctrl-C."
fswatch -0 -r -l $LATENCY $LOCAL_PATH --exclude="/\.[^/]*$" | while read -d "" event
  do
    git check-ignore $event -q
    ignore=$?
    if [ "${ignore}" == "0" ]; then
      echo -e "${yellow}" `date` "${nocolor}\"${event}\" ignored"
    else
      echo -en "${green}" `date` "${nocolor}\"$event\" changed. Synchronizing... "
      rsync -avz -q --delete --force $LOCAL_PATH $TARGET
      echo "done."
    fi
  done
