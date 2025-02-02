# Goblin Converter
![GitHub Release](https://img.shields.io/github/v/release/magynhard/goblin?style=plastic&color=default&label=GitHub&logo=github)
[![Flatpak](https://img.shields.io/badge/_-Flatpak-Sub?style=plastic&color=gray&logo=flatpak&logoColor=blu)](#)
[![Ruby](https://img.shields.io/badge/_-Ruby-Sub?style=plastic&color=gray&logo=ruby&logoColor=red)](#)
[![GTK](https://img.shields.io/badge/_-GTK-Sub?style=plastic&color=gray&logo=gtk&logoColor=green)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-gold.svg?style=plastic&logo=mit)](LICENSE)

<img src="data/icons/app-icon.svg" style="height: 96px;">

>
> A simple document converter GUI for GTK using magick

Initial use case was to convert 300ppi (PDF) documents (grayscale or colored) to monochrome (PDF) documents to reduce the size significantly for digital document storage.

E.g. a PDF document with 300ppi and about 3-4MB in grayscale can be reduced to about 40-75KB(!) in monochrome.

```diff
- Warning: This app is in early development and may not work as expected or at all due some refactorings.
```

# Setup
This app is distributed as a Flatpak package or can be installed locally.

## Flatpak
```ruby
# not available yet
flatpak install flathub de.magynhard.GoblinConverter
```

## Local
Ensure, Ruby is installed.

Beside, you need to have build tools and other dependencies to be installed.
```
# Ubuntu
sudo apt install build-essential libcairo2-dev libgirepository1.0-dev libgdk-pixbuf2.0-dev libgtk-4-common libgtk-4-dev libadwaita-1-0 libadwaita-1-dev imagemagick
# Manjaro/Arch
sudo pacman -S base-devel libcairo gobject-introspection libgdk-pixbuf libgtk gtk+ adwaita imagemagick
```

### Install
```
git clone https://github.com/magynhard/goblin-converter.git
cd goblin-converter
rake install
cd ..
rm -rf goblin-converter
```
### Uninstall
```
git clone https://github.com/magynhard/goblin-converter.git
cd goblin-converter
rake uninstall
cd ..
rm -rf goblin-converter
```

# Development
## Requirements (development)
* Ruby 3.2
* GTK4
* ImageMagick 7
* Ghostscript 10
* Flatpak & Flatpak Builder

## Install local for development
```
./install.sh
```

## Build package
```
flatpak-builder --force-clean build de.magynhard.GoblinConverter.yaml
```

## Run local package
```
flatpak-builder --run build de.magynhard.GoblinConverter.yaml goblin-converter
```

## Create resources
```
glib-compile-resources data/goblin-converter.gresource.xml
```
