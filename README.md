# `excalidraw.nvim`

A nvim plugin to help managing excalidraw diagrams in markdown files.

The plugin handles excalidraw (or other drawing tool, in the future) links to local files within markdown documents. It
helps using these tools within your .md notes and store all files in a sensible way. It includes pickers to manage
creation and opening of the links with the right app.

It creates default scenes according to your setup configuration. It can also handle template scenes!

## features

- Open scenes files. `gx` works oput of the box fine if you have the excalidraw app installed as a PWA and configured as
  default application for .excalidraw files. The plugin provides a cusom opener that tries to find the file in the link
  in a smarter way, if you use relative paths.
- Create new scenes file (and possibly open it in app). From .md files, give it a name and it creates the scene, a link
  to the file and puts the cursor on the name (at the start) and optionally opens it with the default app. You can
  configure where to save your scenes.
- default keymaps ???
- Templates: It can open, save and reuse templates scenes. It uses custom or Telescope pickers. vim-fzf available in the
  future. You can use one of the templates as default (it defaults to use a blank one).

## Usage

The plugin comes with sane defaults and it dows not need configuration. If you want to configure it run the `.setup()`
function In the following we provide the default configuration.

In Lazy:

```lua
{ "marcocofano/excalidraw.nvim",
   config = function()
        require("excalidraw").setup(opts)
    end
}
```

```lua
opts = {
    ...
}
```

configure the main folder for storage or templates. These folders will be the default ones where the plugin will store
newly created excalidraw files. It will also look for relative path in md links.

### open file

Call `:Excalidraw open` when you are over a link or path with the `.excalidraw` extension

### Create a new file

Call `:Excalidraw create`. It will prompt for a file name. If a path is provided, it will create all intermediate
folders. You can also give the filepath as an argument to the command, like: `:Escalidraw create [filepath]`

#### Create behaviour

- If file exists, it returns an error (it will ask for overwrite in next iteration)
- open the file at creation, configurable
- creation follows the following:

  1. parse input
  2. expand to absolute
  3. ensure directories exists
  4. create a link (you can configure the style. Absolute or relative)
  5. open it (if configured)

### Templates

Call `:Excalidraw create_from_template` will open a picker with the templates stored in the configured directory.

<CR> is mapped to prompt the user to select the name for the new file. It will create a new excalidraw file (and link)
with the template applied to it.

### List saved scenes

The command `:Excalidraw list` will list all excalidraw files saved to the default directory.

## Command list

| Command                         | Action                                                              | Default keymap | Sub Keymap     |
| ------------------------------- | ------------------------------------------------------------------- | -------------- | -------------- |
| Excalidraw create               | Creates a new scene and adds a link to it t cursor                  | <leader>en     |                |
| Excalidraw open_link            | Open a scene from link under cursor                                 | <leader>eo     |                |
| Excalidraw create_from_template | Creates a new scene from template and adds a link to it at cursor   | <leader>et     |                |
| Excalidraw list_scenes          | Open a picker with a list of saved scenes (in configured directory) | <leader>el     | add_link, open |

The sub_keymaps are used whenever the corresonding command opens a picker. They can be set calling the setup function
with the configuration


## Wishlist

There are some further features that are either currently under developement or I wish to get to at some point.

### Render excalidraw links inline (with image.nvim support on kitty)

This might be fairly simple to implement, I just need to find a way to export the svg/png programmatically.

### Interactivity with browser

This will require the creation of a server. It might be useful to have a state of the currently open excalidraw files
and get updates live.

### mermaid to excalidraw and vv

I feel that this is easier if I can tap into the ExcalidrawAPI directly.

### Direct integration with obsidian.nvim

Maybe using less configuration or sharing configuration in terms of workspaces, etc...

### Contributions

I will open issues for some of these items in case anyone has ideas or wants to contribute. Any suggestion or help is
welcome
