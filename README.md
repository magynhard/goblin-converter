# Goblin Document Converter
![GitHub Release](https://img.shields.io/github/v/release/magynhard/goblin?style=plastic&color=default&label=GitHub&logo=github)
[![Flatpak](https://img.shields.io/badge/_-Flatpak-Sub?style=plastic&color=gray&logo=flatpak&logoColor=blu)](#)
[![Ruby](https://img.shields.io/badge/_-Ruby-Sub?style=plastic&color=gray&logo=ruby&logoColor=red)](#)
[![GTK](https://img.shields.io/badge/_-GTK-Sub?style=plastic&color=gray&logo=gtk&logoColor=green)](#)
[![GTK](https://img.shields.io/badge/_-magick-Sub?style=plastic&color=gray&logo=gnome-terminal&logoColor=)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-gold.svg?style=plastic&logo=mit)](LICENSE)

<img src="res/logo.svg" style="height: 96px;">

>
> A simple document converter GUI for GTK using magick

Initial use case was to convert 300ppi (PDF) documents (grayscale or colored) to monochrome (PDF) documents to reduce the size significantly for digital document storage.

E.g. a PDF document with 300ppi and about 3-4MB in grayscale can be reduced to about 40-75KB(!) in monochrome.

# Setup
This app is distributed as a Flatpak package.

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
flatpak-builder --force-clean build de.magynhard.Goblin.json
```

## Run local package
```
flatpak-builder --run build de.magynhard.Goblin.json run.sh
```
