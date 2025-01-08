#!/usr/bin/env bash

# Check if ruby command is available
if ! command -v ruby &> /dev/null; then
  echo "Error: Ruby is not installed. Please install Ruby to continue."
  exit 1
fi

# Check if bundle command is available
if ! command -v bundle &> /dev/null; then
  echo "Error: Bundler is not installed. Installing bundler ..."
  bash -c "gem install bundler"
fi

# Überprüfen, ob die .ruby-version Datei existiert
if [ ! -f .ruby-version ]; then
  # Aktuelle Ruby-Version abrufen
  RUBY_VERSION=$(ruby -v | awk '{print $2}')

  # .ruby-version Datei mit der aktuellen Ruby-Version erstellen
  echo "$RUBY_VERSION" > .ruby-version
fi

# Get the current path
CURRENT_PATH=$(pwd)

# Run bundle install to install dependencies
bash -c "bundle install"

# Target path for the .desktop file
DESKTOP_FILE="$HOME/.local/share/applications/goblin-doc.desktop"

# Copy the .desktop file and replace placeholders
sed "s|{{path_to_goblin_document_converter_root}}|$CURRENT_PATH|g" res/goblin-doc.desktop > "$DESKTOP_FILE"

echo "Installation complete. You can now run Goblin Document Converter from the applications menu."