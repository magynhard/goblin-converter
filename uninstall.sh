#!/usr/bin/env bash

# Target path for the .desktop file
DESKTOP_FILE="$HOME/.local/share/applications/goblin-document-converter.desktop"

# Remove the .desktop file
if [ -f "$DESKTOP_FILE" ]; then
  rm "$DESKTOP_FILE"
  echo "The .desktop file has been successfully removed from $DESKTOP_FILE."
else
  echo "The .desktop file does not exist at $DESKTOP_FILE."
fi