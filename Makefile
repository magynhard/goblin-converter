APP_ID = de.magynhard.GoblinConverter
PREFIX ?= /usr/local
CRYSTAL_FLAGS ?=
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share
APPDIR = $(SHAREDIR)/goblin-converter
LOCALEDIR = $(SHAREDIR)/locale

.PHONY: build run install uninstall locales clean test appimage flatpak validate-metadata test-packaging test-file-opening test-conversion-modes

build:
	mkdir -p bin
	crystal build $(CRYSTAL_FLAGS) src/goblin-converter.cr -o bin/goblin-converter

test:
	crystal spec

run: build
	./bin/goblin-converter

install: build locales
	install -Dm755 bin/goblin-converter $(DESTDIR)$(BINDIR)/goblin-converter
	install -Dm644 data/$(APP_ID).desktop $(DESTDIR)$(SHAREDIR)/applications/$(APP_ID).desktop
	install -Dm644 data/$(APP_ID).metainfo.xml $(DESTDIR)$(SHAREDIR)/metainfo/$(APP_ID).metainfo.xml
	install -Dm644 data/icons/app-icon.svg $(DESTDIR)$(SHAREDIR)/icons/hicolor/scalable/apps/$(APP_ID).svg
	install -Dm644 data/icons/app-icon-512.png $(DESTDIR)$(SHAREDIR)/icons/hicolor/512x512/apps/$(APP_ID).png
	@for lang in $$(cat po/LINGUAS); do \
		install -Dm644 po/$$lang/LC_MESSAGES/$(APP_ID).mo $(DESTDIR)$(LOCALEDIR)/$$lang/LC_MESSAGES/$(APP_ID).mo || exit $$?; \
	done

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/goblin-converter
	rm -f $(DESTDIR)$(SHAREDIR)/applications/$(APP_ID).desktop
	rm -f $(DESTDIR)$(SHAREDIR)/metainfo/$(APP_ID).metainfo.xml
	rm -f $(DESTDIR)$(SHAREDIR)/icons/$(APP_ID).svg
	rm -f $(DESTDIR)$(SHAREDIR)/icons/$(APP_ID)-512.png
	rm -f $(DESTDIR)$(SHAREDIR)/icons/hicolor/scalable/apps/$(APP_ID).svg
	rm -f $(DESTDIR)$(SHAREDIR)/icons/hicolor/512x512/apps/$(APP_ID).png
	@for lang in $$(cat po/LINGUAS); do \
		rm -f $(DESTDIR)$(LOCALEDIR)/$$lang/LC_MESSAGES/$(APP_ID).mo || exit $$?; \
	done
	rm -rf $(DESTDIR)$(APPDIR)

locales:
	@for lang in $$(cat po/LINGUAS 2>/dev/null); do \
		mkdir -p po/$$lang/LC_MESSAGES; \
		if [ -f po/$$lang/LC_MESSAGES/$(APP_ID).po ]; then \
			msgfmt po/$$lang/LC_MESSAGES/$(APP_ID).po -o po/$$lang/LC_MESSAGES/$(APP_ID).mo || exit $$?; \
		fi; \
	done

generate_locales:
	@potfiles=$$(cat po/POTFILES 2>/dev/null); \
	if [ -n "$$potfiles" ]; then \
		xgettext -o po/$(APP_ID).pot --from-code=UTF-8 --language=C --keyword=translate $$potfiles; \
	fi
	@for lang in $$(cat po/LINGUAS 2>/dev/null); do \
		mkdir -p po/$$lang/LC_MESSAGES; \
		po_file="po/$$lang/LC_MESSAGES/$(APP_ID).po"; \
		if [ -f "$$po_file" ]; then \
			msgmerge --update --backup=none "$$po_file" po/$(APP_ID).pot; \
		else \
			msginit --input=po/$(APP_ID).pot --locale=$$lang --output="$$po_file" --no-translator; \
		fi; \
	done

clean:
	rm -f bin/goblin-converter
	rm -f *.dwarf

validate-metadata:
	desktop-file-validate data/$(APP_ID).desktop
	appstreamcli validate --no-net --pedantic data/$(APP_ID).metainfo.xml

appimage:
	bash scripts/build-appimage.sh

flatpak:
	bash scripts/build-flatpak.sh

test-packaging:
	python3 -m unittest discover -s tests -v

test-file-opening: build
	dbus-run-session -- xvfb-run -a python3 tests/file_opening.py bin/goblin-converter

test-conversion-modes:
	dbus-run-session -- xvfb-run -a env GDK_BACKEND=x11 GSK_RENDERER=cairo crystal run tests/conversion_modes.cr
