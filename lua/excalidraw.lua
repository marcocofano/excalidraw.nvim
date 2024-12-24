local path_handler       = require("excalidraw.path_handler")

local M                  = {}

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

M.create_excalidraw_file = function()
   -- Prompt the user for the file name
   local filename = vim.fn.input("Enter the name of the new Excalidraw file (without extension): ")

   -- Check if the filename is not empty
   if filename == "" then
      vim.notify("Filename cannot be empty!", vim.log.levels.ERROR)
      return
   end

   -- Append the .excalidraw extension
   local filepath = path_handler.construct_path(filename .. ".excalidraw")
   local expanded_filepath = vim.fn.fnamemodify(filepath, ":p")
   print(vim.inspect(expanded_filepath))
   -- Check if the file already exists
   if vim.fn.filereadable(expanded_filepath) == 1 then
      vim.notify("File already exists: " .. expanded_filepath, vim.log.levels.ERROR)
      return
   end

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
   local file = io.open(expanded_filepath, "w")
   if file then
      file:write(default_content)
      file:close()
      vim.notify("Created new Excalidraw file: " .. expanded_filepath)
   else
      vim.notify("Error creating file: " .. expanded_filepath, vim.log.levels.ERROR)
      return
   end

   -- Insert a Markdown link to the new file at the current cursor position
   local markdown_link = "[" .. filename .. "](" .. expanded_filepath .. ")"
   vim.api.nvim_put({ markdown_link }, 'l', true, true)
end

---@param dir string The directory path to ensure exists.
local function ensure_directory_exists(dir)
   if vim.fn.isdirectory(dir) == 0 then
      -- Create the directory with 'p' flag to make parent directories if needed
      vim.fn.mkdir(dir, "p")
      vim.notify("Created storage directory: " .. dir)
   end
end


---@param config table Configuration options.
M.configure = function(config)
   require('excalidraw.config').set(config)
end

return M
