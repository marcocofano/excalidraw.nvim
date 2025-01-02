local open_command = require "excalidraw.commands.open"

local M            = {}

local function parse_input(data)
   return vim.fn.join(data, "_")
end

-- Create an excalidraw canva file and a markdown link to it, optionally it opens it
---@param client excalidraw.Client
---@param data table<string>
M.create_excalidraw_file = function(client, data)
   local title = ""

   print("test: ", vim.inspect(client))

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

   ---@type excalidraw.Canva
   local canva = client:create_canva({ title = title, type = "excalidraw" })
   -- Create the new .excalidraw file with a default empty JSON structure.
   -- TODO: handle the default used. For example from templates or a different one from config

   -- TODO: better error handling
   if canva == nil then
      return
   end
   print("Canva: ", vim.inspect(canva))
   canva:set_content(new_content)

   canva:write_to_file()
   local link = canva:build_markdown_link(client.opts.relative_path)

   vim.api.nvim_put({ link }, 'l', true, false)

   if client.opts.open_on_create == true then
      vim.fn.searchpos("]", "e")
      open_command.open_excalidraw_file(client)
   end
end

function M.run(client, data)
   return M.create_excalidraw_file(client, data)
end

return M
