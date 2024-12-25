local commands = require("excalidraw.commands.commands")

local open = require("excalidraw.commands.open")
local create = require("excalidraw.commands.create")

commands.register_subcommand("open", open)
commands.register_subcommand("create", create)

commands.build_commands()
