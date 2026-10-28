# ButtonRow requires newer libadwaita than Ubuntu 24.04 provides.
FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl git pkg-config patch python3 python3-yaml \
    libgtk-4-dev libadwaita-1-dev libgirepository1.0-dev gobject-introspection \
    libgc-dev libpcre2-dev librsvg2-dev libdconf1 dconf-gsettings-backend \
    libxml2-dev libyaml-dev libjpeg-dev libpng-dev libtiff-dev libwebp-dev \
    libfontconfig1-dev libfreetype-dev liblcms2-dev zlib1g-dev \
    gettext appstream desktop-file-utils patchelf file squashfs-tools \
    adwaita-icon-theme gsettings-desktop-schemas dbus-bin && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/goblin-converter
COPY scripts/packaging.py scripts/packaging.py
COPY packaging/sources.json packaging/sources.json
COPY shard.yml ./
COPY data/de.magynhard.GoblinConverter.metainfo.xml data/de.magynhard.GoblinConverter.metainfo.xml
RUN python3 scripts/packaging.py fetch-tools /opt/tools && \
    python3 scripts/packaging.py fetch-shards /opt/shards && \
    python3 scripts/packaging.py build-converters /usr && ldconfig
ENV PATH="/opt/tools/crystal/bin:/opt/tools:${PATH}"
WORKDIR /src
COPY . .
RUN cp -a /opt/shards ./lib
ENTRYPOINT ["bash", "scripts/appimage-container.sh"]
