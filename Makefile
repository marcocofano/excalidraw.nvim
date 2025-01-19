MINIDOC = ~/.local/share/nvim/lazy/mini.doc/
VERSION_SCRIPT := scripts/version.sh
RELEASE_SCRIPT := scripts/release.sh

.PHONY: test
test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.vim' }"

.PHONY: docs
docs: 
	MINIDOC=$(MINIDOC) nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile scripts/generate_docs.lua" -c "qa!"

.PHONY: version
version:
	@bash $(VERSION_SCRIPT)

.PHONY: release
release:
	@bash $(RELEASE_SCRIPT)
