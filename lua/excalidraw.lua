local path_handler = require("excalidraw.path_handler")

local utils        = require("excalidraw.utils")

local M            = {}


-- Open a excalidraw canva from a markdown link (or just a string with a path to a canva)
M.open_excalidraw_file   = function()
   -- Get the link or file name under the cursor
   local link   = vim.fn.expand('<cfile>')

   local config = require("excalidraw.config").get()
   -- Check if the link ends with .excalidraw
   if string.match(link, '%.excalidraw$') then
      -- contruct path from the input
      local filepath = path_handler.construct_path(link, config.storage_dir)
      if vim.fn.filereadable(filepath) ~= 1 then
         vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
         return
      end
      vim.notify("Opening file: " .. filepath)

      -- Open the file with the system's default application
      if vim.fn.has('mac') == 1 then
         vim.cmd('silent !open ' .. vim.fn.shellescape(filepath))
      elseif vim.fn.has('win32') == 1 then
         vim.cmd('silent !start ' .. vim.fn.shellescape(filepath))
      else
         vim.cmd('silent !xdg-open ' .. vim.fn.shellescape(filepath))
      end
   else
      vim.notify("No valid .excalidraw link found under cursor", vim.log.levels.WARN)
      return
   end
end

-- Create a excalidraw canvas file and a markdown link to it
-- 1. parse input
-- 2. expand to absolute
-- 3. ensure directories exists
-- 4. save file
-- 5. create a link (you can configure the style. Absolute or relative)
-- 6. open it (if configured)
M.create_excalidraw_file = function()
   -- 1. parse the input
   local config      = require("excalidraw.config").get()
   -- Prompt the user for the file name
   local input_path  = vim.fn.input("Enter the name of the new Excalidraw file (without extension): ")
   local storage_dir = config.storage_dir
   -- Check if the filename is not empty
   if input_path == "" then
      vim.notify("Filename cannot be empty!", vim.log.levels.ERROR)
      return
   end

   -- 2. expand to absolute
   local filepath = path_handler.construct_path(input_path .. ".excalidraw", storage_dir)
   --TODO: handle better the difference between displayed relative path and the path where to actually save the file
   -- Check if the file already exists
   if vim.fn.filereadable(filepath) == 1 then
      vim.notify("File already exists: " .. filepath, vim.log.levels.ERROR)
      return -- TODO: handle overwrite
   end

   local path = vim.fn.fnamemodify(filepath, ":p:h")
   -- 3. ensure directories to save file exist
   utils.ensure_directory_exists(path)

   -- Create the new .excalidraw file with a default empty JSON structure.
   -- TODO: handle the default used. For example from templates or a different one from config
   local default_content = [[
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": {
    "gridSize": null,
    "viewBackgroundColor": "#afffff"
  },
  "files": {}
}
]]

   -- 4. Write the default content to the new file
   -- TODO: check if I can use pcall here
   local file = io.open(filepath, "w")
   if file then
      file:write(default_content)
      file:close()
      vim.notify("Created new Excalidraw file: " .. filepath)
   else
      vim.notify("Error creating file: " .. filepath, vim.log.levels.ERROR)
      return
   end

   -- 5. Insert a Markdown link to the new file at the current cursor position
   local markdown_link = "[" .. input_path .. "](" .. filepath .. ")"
   vim.api.nvim_put({ markdown_link }, 'l', true, true)

   -- 6. Open the newly created file
   if config.open_on_create == true then
      vim.fn.searchpos("]", "e")
      M.open_excalidraw_file()
   end
end


---@param configuration table Configuration options.
M.configure = function(configuration)
   require('excalidraw.config').set(configuration)
end

return M
