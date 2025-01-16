local M = {}

local function parse_input(filepath)
   -- Normalize the filepath using vim.fs API
   if not filepath then
      error("Scene title cannot be nil")
   end
   filepath = filepath:gsub("\\", "/") -- for windows normalization
   local parts = vim.split(filepath, "/")
   local parent = table.concat(parts, "/", 1, #parts - 1)
   local title = parts[#parts]
   return parent, title
end

---Create an excalidraw scene file and a markdown link to it, optionally it opens it
---@param client excalidraw.Client
---@param data table<string>
M.create_excalidraw_file = function(client, data)
   local title = ""
   local dir = ""

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


   ---@type excalidraw.Scene
   local scene = client:create_scene({ title = title, dir = dir })


   client:save_scene(scene)
   local link = client:build_markdown_link(scene)

   vim.api.nvim_put({ link }, 'l', true, false)

   if client.opts.open_on_create == true then
      vim.fn.searchpos("]", "e")
      client:open_scene_link(scene.path)
   end
end


function M.run(client, data)
   return M.create_excalidraw_file(client, data)
end

return M

