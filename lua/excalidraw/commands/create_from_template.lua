-- This is still not working but it is basically doing what it should
--


local open_command = require "excalidraw.commands.open"
local Canva        = require "excalidraw.canva"

local M            = {}

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
   if not client.opts.templates_dir then
      vim.notify("Templates folder is not defined or does not exist", vim.log.levels.ERROR)
      return
   end

   ---@type excalidraw.TelescopePicker
   local picker = client:picker()
   if not picker then
      vim.notify("No picker configured", vim.log.levels.ERROR)
      return
   end
   picker:find_excalidraw_templates {
      callback = function(template_path)
         local title = ""
         local dir = ""

         local function read_file_to_variable(filepath)
            local file, err = io.open(filepath, "r") -- Open the file in read mode
            if not file then
               return nil, "Error opening file: " .. (err or "unknown error")
            end

            local content = file:read("*a") -- Read the entire file content
            file:close()                    -- Close the file
            return content
         end

         local template_content = read_file_to_variable(template_path)

         local template = Canva.new(
            "template",
            "template",
            template_path,
            template_path,
            template_content
         )

         local input_string = ""
         if #data > 0 then
            input_string = table.concat(data, " ")
         else
            input_string = vim.fn.input("Enter the name of the new Excalidraw file (without extension): ")
         end

         if input_string == "" then
            vim.notify("Filename cannot be empty!", vim.log.levels.ERROR)
            return
         end

         dir, title = parse_input(input_string)

         ---@type excalidraw.Canva
         local canva = client:create_canva({ title = title, dir = dir, template = template })
         print("dammi tutto:", vim.inspect({ canva }))

         canva:write_to_file()
         local link = canva:build_markdown_link(client.opts.relative_path)

         vim.api.nvim_put({ link }, 'l', true, false)

         if client.opts.open_on_create == true then
            vim.fn.searchpos("]", "e")
            open_command.open_excalidraw_file(client)
         end
      end
   }
end

function M.run(client, data)
   return M.create_excalidraw_file_from_template(client, data)
end

return M
