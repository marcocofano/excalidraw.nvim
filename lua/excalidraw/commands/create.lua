local path_handler = require "excalidraw.path_handler"
local utils        = require "excalidraw.utils"
local open_command = require "excalidraw.commands.open"
local Canva        = require "excalidraw.canva"
local config_mod   = require("excalidraw.config")
local M            = {}



--TODO: change it to enum in case we extend out from excalidaw, for now the string excalidraw

---@class excalidraw.CreateCanvaOpts
---@field title string
---@field type string
---@field storage_dir string


--- Create a new canva object
---
--- This is a builder method to create the canvas from just a title
---
---@param opts excalidraw.CreateCanvaOpts Options
---
--- Create canva builder from the user input or input argument
--- set filename with extension
--- expand to absolute according to configs or input path
--- save separately the relative path, it might be used for the md link
--- @return excalidraw.Canva | nil
local function create_canva(opts)
   local relative_path = opts.title .. "." .. opts.type

   local absolute_path = path_handler.construct_path(relative_path, opts.storage_dir)
   if vim.fn.filereadable(absolute_path) == 1 then
      vim.notify("File already exists: " .. absolute_path, vim.log.levels.ERROR)
      return -- TODO: handle overwrite
   end

   local absolute_dir = vim.fn.fnamemodify(absolute_path, ":p:h")

   utils.ensure_directory_exists(absolute_dir)


   ---@type excalidraw.Canva
   local new_canva = Canva.new(
      opts.title,
      opts.title,
      absolute_path,
      relative_path,
      "excalidraw"
   )
   return new_canva
end

local function parse_input(data)
   return vim.fn.join(data, "_")
end

-- Create an excalidraw canva file and a markdown link to it, optionally it opens it
M.create_excalidraw_file = function(data)
   local config = config_mod.get()
   local title  = ""

   --TODO: parse the input so that it handles the case of path, path plus title with and without spaces
   if #data > 0 then
      title = parse_input(data)
   else
      title = vim.fn.input("Enter the name of the new Excalidraw file (without extension): ")
   end

   if title == "" then
      vim.notify("Filename cannot be empty!", vim.log.levels.ERROR)
      return
   end

   local new_content = [[
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": {
    "gridSize": null,
    "viewBackgroundColor": "#ffffff"
  },
  "files": {}
}
]]
   local canva = create_canva({ title = title, type = "excalidraw", storage_dir = config
   .storage_dir })
   -- Create the new .excalidraw file with a default empty JSON structure.
   -- TODO: handle the default used. For example from templates or a different one from config

   -- TODO: better error handling
   if canva == nil then
      return
   end
   canva:set_content(new_content)

   canva:write_to_file()
   local link = canva:build_markdown_link(config.relative_path)

   vim.api.nvim_put({ link }, 'l', true, false)

   if config.open_on_create == true then
      vim.fn.searchpos("]", "e")
      open_command.open_excalidraw_file()
   end
end

function M.run(data)
   return M.create_excalidraw_file(data)
end

return M
