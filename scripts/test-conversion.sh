#!/usr/bin/env bash
# Exercise the actual PDF delegate and the formats exposed by the application.
set -euo pipefail
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT
magick -version
gs --version
magick -size 64x64 gradient:white-black "$temporary/source.png"
magick "$temporary/source.png" "$temporary/source.pdf"
magick -density 72 "$temporary/source.pdf" -colorspace Gray -threshold 50% \
    -type bilevel -compress Group4 "$temporary/monochrome.pdf"
for format in png jpg tiff webp; do
    magick -density 72 "$temporary/monochrome.pdf" "$temporary/result.$format"
    test "$(magick identify -format '%wx%h' "$temporary/result.$format")" = 64x64
done
