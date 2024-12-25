local path_handler = require("excalidraw.path_handler")

local M            = {}

---@param dir string The directory path to ensure exists.
local function ensure_directory_exists(dir)
   if vim.fn.isdirectory(dir) == 0 then
      -- Create the directory with 'p' flag to make parent directories if needed
      vim.fn.mkdir(dir, "p")
      vim.notify("Created storage directory: " .. dir)
   end
end

M.open_excalidraw_file   = function()
   -- Get the link or file name under the cursor
   local link = vim.fn.expand('<cfile>')

   -- Check if the link ends with .excalidraw
   if string.match(link, '%.excalidraw$') then
      -- contruct path from the input
      local filepath = path_handler.resolve_path(link)
      if filepath ~= nil then
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
         vim.notify("File not found", vim.log.levels.ERROR)
      end
   else
      vim.notify("No valid .excalidraw link found under cursor", vim.log.levels.WARN)
   end
end

--
-- 1. parse input
-- 2. expand to absolute
-- 3. ensure directories exists
-- 4. save file
-- 5. open it (if configured)
--
M.create_excalidraw_file = function()
   local config      = require("excalidraw.config").get()
   -- Prompt the user for the file name
   local input_path  = vim.fn.input("Enter the name of the new Excalidraw file (without extension): ")
   local storage_dir = config.storage_dir
   -- Check if the filename is not empty
   if input_path == "" then
      vim.notify("Filename cannot be empty!", vim.log.levels.ERROR)
      return
   end

   local filepath = path_handler.construct_path(input_path .. ".excalidraw", storage_dir)
   --TODO: handle better the difference between displayed relative path and the path where to actually save the file
   -- Check if the file already exists TODO: handle overwrite
   if vim.fn.filereadable(filepath) == 1 then
      vim.notify("File already exists: " .. filepath, vim.log.levels.ERROR)
      return
   end

   local path = vim.fn.fnamemodify(filepath, ":p:h")
   ensure_directory_exists(path)

   -- Create the new .excalidraw file with a default empty JSON structure
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

   -- Write the default content to the new file
   local file = io.open(filepath, "w")
   if file then
      file:write(default_content)
      file:close()
      vim.notify("Created new Excalidraw file: " .. filepath)
   else
      vim.notify("Error creating file: " .. filepath, vim.log.levels.ERROR)
      return
   end

   -- Insert a Markdown link to the new file at the current cursor position
   local markdown_link = "[" .. input_path .. "](" .. filepath .. ")"
   vim.api.nvim_put({ markdown_link }, 'l', true, true)
   -- Open the newly created file
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
