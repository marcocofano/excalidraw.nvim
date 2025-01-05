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

The plugin comes with sane defaults and it dows not need configuration. If you want to configure it run the
`.configure()` function In the following we provide the default configuration.

In Lazy:

```lua
{ "marcocofano/excalidraw.nvim",
   config = function()
        require("excalidraw").configure(configuration)
    end
}
```

```lua
configuration = {
    ...
}
```

### open file

Call `:Excalidraw open` when you are over a link or path with the `.excalidraw` extension

#### Where does it look for the file?

- defaults for the basic ex file at creation
  1. custom storage directory (configurable)
  2. default storage folder
  3. cwd/.excalidraw
  4. current folder

### Create a new file

Call `:Excalidraw create`. It will prompt for a file name. If a path is provided, it will create all intermediate
folders. You can also give the filepath as an argument to the command, like: `:Escalidraw create [filepath]`

#### Create behaviour

- If file exists, ask for overwrite
- open the file at creation, configurable
- creation follows the following:

  1. parse input
  2. expand to absolute
  3. ensure directories exists
  4. save file
  5. create a link (you can configure the style. Absolute or relative)
  6. open it (if configured)

- some keymaps decision for the telescope pickers integrations.

### Templates

TBD
