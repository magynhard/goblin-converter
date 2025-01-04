#!/usr/bin/env bash

# Check if ruby command is available
if ! command -v ruby &> /dev/null; then
  echo "Error: Ruby is not installed. Please install Ruby to continue."
  exit 1
fi

# Check if bundle command is available
if ! command -v bundle &> /dev/null; then
  echo "Error: Bundler is not installed. Please install Bundler by running 'gem install bundler'."
  exit 1
fi

# Get the current Ruby version
RUBY_VERSION=$(ruby -v | awk '{print $2}')

# Create .ruby-version file with the current Ruby version
echo "$RUBY_VERSION" > .ruby-version

# Get the current path
CURRENT_PATH=$(pwd)

# Run bundle install to install dependencies
bash -c "bundle install"

# Target path for the .desktop file
DESKTOP_FILE="$HOME/.local/share/applications/goblin-document-converter.desktop"

# Copy the .desktop file and replace placeholders
sed "s|{{path_to_goblin_document_converter_root}}|$CURRENT_PATH|g" res/goblin-document-converter.desktop > "$DESKTOP_FILE"

echo "Installation complete. You can now run Goblin Document Converter from the applications menu."