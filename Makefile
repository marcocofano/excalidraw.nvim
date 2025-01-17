MINIDOC = ~/.local/share/nvim/lazy/mini.doc/

.PHONY: test
test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.vim' }"

.PHONY: docs
docs: 
	MINIDOC=$(MINIDOC) nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile scripts/generate_docs.lua" -c "qa!"
