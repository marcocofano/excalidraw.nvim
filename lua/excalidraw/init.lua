local M = {}


---@class PathHandler
---@field storage_dir string The base directory for storing Excalidraw files.
local PathHandler = {}
PathHandler.__index = PathHandler

---Creates a new PathHandler instance.
---@param storage_dir string The base storage directory for Excalidraw files.
---@return PathHandler
function PathHandler.new(storage_dir)
   return setmetatable({ storage_dir = storage_dir }, PathHandler)
end

---Resolve and find path based on the link, handling relative, absolute paths
-- For relative paths it will search the file in a list of path by importance
-- 1. storage_dir
-- 2. default storage_dir = ~/.excalidraw/ this might be just handled by configuring the default in setup or config.
-- 3. CWD/.excalidraw/
-- 4. Current file directory
---@param link string The link or file path to resolve.
---@return string | nil The resolved absolute file path, or nil if the path cannot be resolved
function PathHandler:resolve_path(link)
   if string.match(link, "^/") then
      if vim.fn.filereadable(link) == 1 then
         return link
      else
         return nil
      end
   end
   -- relative path cases:

   -- 1. storage_dir or 2. storage_dir default
   local relative_path = self.storage_dir .. '/' .. link
   if vim.fn.filereadable(relative_path) == 1 then
      return relative_path
   end

   -- 3. CWD/.excalidraw -- TODO: Missing case only with cwd and not .excalidraw done
   local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
   print(cwd)
   local relative_path = cwd .. '/' .. link
   if vim.fn.filereadable(relative_path) == 1 then
      return relative_path
   end

   -- 4. Current file directory
   local current_dir = vim.fn.expand("%:p:h")
   local relative_path = current_dir .. '/' .. link
   if vim.fn.filereadable(relative_path) == 1 then
      return relative_path
   end

   return nil
end

---Construct the absolute path to the file.
---@param link string The link to construct the path for.
---@return string The constructed absolute path.
local construct_path     = function(link)
   -- Construct the absolute path to the file
   return vim.fn.expand('%:p:h') .. '/' .. link
end

M.open_excalidraw_file   = function()
   -- Get the link or file name under the cursor
   local link = vim.fn.expand('<cfile>')

   -- Check if the link ends with .excalidraw
   if string.match(link, '%.excalidraw$') then
      -- contruct path from the input
      local filepath = M.path_handler:resolve_path(link)
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
         vim.notify("File not found: ", vim.log.levels.ERROR)
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
   local filepath = construct_path(filename .. ".excalidraw")

   -- Check if the file already exists
   if vim.fn.filereadable(filepath) == 1 then
      vim.notify("File already exists: " .. filepath, vim.log.levels.ERROR)
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
    "viewBackgroundColor": "#ffffff"
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
   local markdown_link = "[" .. filename .. "](" .. filepath .. ")"
   vim.api.nvim_put({ markdown_link }, 'l', true, true)
end



---@type PathHandler|nil
M.path_handler = nil

---Setup function to initialize the PathHandler.
---@param opts table Configuration options.
M.setup = function(opts)
   local storage_dir = opts.storage_dir or vim.fn.expand("~/.excalidraw")
   M.path_handler = PathHandler.new(storage_dir)
   vim.notify("Excalidraw plugin configured with storage directory: " .. storage_dir)
end

return M
