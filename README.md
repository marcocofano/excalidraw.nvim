# `excalidraw.nvim`

A nvim plugin to help managing excalidraw diagrams in markdown files.

The plugin is still experimental!

- Handle excalidraw links to local files within markdown documents
- Store all files in default folders
- Use pickers to manage creation and opening of the links with the right app.
- Store and use Templates and default Excalidraw scenes for your next drawings

The idea came from the integrtion of Excalidraw and Obsidian in the desktop Obsidian app. The Excalidraw plugin helped
keeping my notes and drawings close. I moved to Obsidian.nvim a few months ago and I was missing this feature. For this
reason **excalidraw.nvim** is close in spirit to obsidian.nvim and uses a similar albeit greatly simplified structure.
Although a perfect integration is probably impossible in nvim, the basic workflow can be reproduced using Excalidraw as
an installed PWA, which is possible using Chrome as browser.

> [!NOTE] I have tried to make it work with non-installed Excalidraw PWA, i.e. diretly in the browser, but the
> development is still on-going

## Prerequisites

- You need to have the excalidraw app installed as a PWA and configured as default application for .excalidraw files.
  The plugin provides a custom opener that tries to find the file in the link, even if you configure it to use relative
  paths. For the moment only installing it as PWA works. There are plans to make it work in the browser.

## Features

- Opens links to .excalidraw files in the APP.
- Create new scene json file, give it a name and it creates the scene, a link
  to the file and puts the cursor on the name (at the start). Optionally, it opens the scene with the default app. You
  can configure where to save your scenes.
- Templates: It can open, save and reuse templates scenes. It uses Telescope pickers. vim-fzf available in the future.
- Lists all Excalidraw scenes from the default directory in a picker.
- Lists all links to excalidraw files in the current buffer.

## Usage

In order to configure the plugin, run the `.setup()` function.

In Lazy:

```lua
{ "marcocofano/excalidraw.nvim",
   config = function()
        require("excalidraw").setup(opts)
    end
}
```

defaults are the following

```lua
opts = {
    storage_dir = "~/.excalidraw",
    templates_dir = "~/.excalidraw/templates",
    open_on_create = true,
    relative_path = true,
    picker = {
       link_scene_mapping = "<C-l>"
    }
}
```

Configure the main directories for storage or templates. These directories will be the default ones where the plugin
will store newly created excalidraw files. It will also look for relative path in md links.

### Open file

Call `:Excalidraw open` when you are over a link or path with the `.excalidraw` extension

### Create a new file

Call `:Excalidraw create`. It will prompt for a file name. If a path is provided, it will create all intermediate
directories. You can also give the filepath as an argument to the command, like: `:Escalidraw create [filepath]`

#### Create behaviour

- If file exists, it returns an error
- open the file at creation, configurable
- creation follows the steps:

  1. parse input
  2. expand to absolute
  3. ensure directories exists
  4. create a link (you can configure the style. Absolute or relative)
  5. open it (if configured)

### Templates

Call `:Excalidraw create_from_template` will open a picker with the templates stored in the configured directory.

`<CR>` is mapped to prompt the user to select the name for the new file. It will create a new excalidraw file (and link)
with the template applied to it.

### List saved scenes

The command `:Excalidraw find_scenes` will list all excalidraw files saved to the default directory.

## Command list

The commands that open Pickers default the <CR> keymap to Open. The find_scenes command can optionally just link to the
selected scene in the picker. The default keymap is <C-l>, which can be changed in the setup.

| Command                          | Action                                          | Sub Keymap |
| -------------------------------- | ----------------------------------------------- | ---------- |
| Excalidraw open_link             | Opens a scene from link under cursor            |            |
| Excalidraw create                | Creates new scene and adds a link               |            |
| Excalidraw create_from_template  | Creates new scene from template and adds a link |            |
| Excalidraw find_scenes           | Opens a picker with a list of saved scenes      | add_link   |
| Excalidraw find_scenes_in_buffer | Opens a picker with a list of linked scenes     |            |

The sub_keymaps are used whenever the corresponding command opens a picker. They can be set calling the setup function
with the configuration

## Dependencies

The only dependency is Telescope.

## Not tested

1. Works on Linux, I have not tested it on Mac or Windows. I will move to plenary.path to have more control over
   filesystem operations

## Wishlist

There are some further features that are either currently under developement or I wish to get to at some point.

### Render excalidraw links inline (with image.nvim support on kitty)

This might be fairly simple to implement, I just need to find a way to export the svg/png programmatically.

### Interactivity with browser

This will require the creation of a server. It might be useful to have a state of the currently open excalidraw files
and get updates live.

### Mermaid to excalidraw and viceversa

I feel that this is easier if I can tap into the ExcalidrawAPI directly.

### Direct integration with obsidian.nvim

Maybe using less configuration or sharing configuration in terms of workspaces, etc...

### Contributions

I will open issues for some of these items in case anyone has ideas or wants to contribute. Any suggestion or help is
welcome
