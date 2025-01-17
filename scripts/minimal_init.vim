set rtp+=.
set rtp+=~/.local/share/nvim/lazy/plenary.nvim/
if $MINIDOC != "" && isdirectory($MINIDOC)
    set rtp+=$MINIDOC
endif 
runtime! plugin/plenary.vim
runtime! plugin/load_excalidraw.lua

