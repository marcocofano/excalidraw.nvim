-- This is still not working but it is basically doing what it should 
--


local open_command   = require "excalidraw.commands.open"
local create_command = require "excalidraw.commands.create"

local M              = {}

local function parse_input(filepath)
   -- Normalize the filepath using vim.fs API
   if not filepath then
      error("Canva title cannot be nil")
   end
   filepath = filepath:gsub("\\", "/") -- for windows normalization
   local parts = vim.split(filepath, "/")
   local parent = table.concat(parts, "/", 1, #parts - 1)
   local title = parts[#parts]
   return parent, title
end

-- Create an excalidraw canva file and a markdown link to it, optionally it opens it
---@param client excalidraw.Client
---@param data table<string>
M.create_excalidraw_file_from_template = function(client, data)
   -- INFO: this is new
   if not client:templates_dir() then
      log.err "Templates folder is not defined or does not exist"
      return
   end

   local picker = client:picker()
   if not picker then
      log.err "No picker configured"
      return
   end
   ----

   picker:find_templates({
      callback = function()
         local title = ""
         local dir = ""

         local input_string
         if #data > 0 then
            input_string = table.concat(data, " ")
         else
            input_string = vim.fn.input("Enter the name of the new Excalidraw file (without extension): ")
         end

         if title == "" then
            vim.notify("Filename cannot be empty!", vim.log.levels.ERROR)
            return
         end

         dir, title = parse_input(input_string)

         ---@type excalidraw.Canva
         local canva = client:create_canva({ title = title, dir = dir, template = template })

         canva:write_to_file()
         local link = canva:build_markdown_link(client.opts.relative_path)

         vim.api.nvim_put({ link }, 'l', true, false)

         if client.opts.open_on_create == true then
            vim.fn.searchpos("]", "e")
            open_command.open_excalidraw_file(client)
         end
      end
   })
end

function M.run(client, data)
   return M.create_excalidraw_file(client, data)
end

return M
