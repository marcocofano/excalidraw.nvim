local config = require("excalidraw.config").get()

M = {}

---Resolve and find path based on the link, handling relative, absolute paths
-- For relative paths it will search the file in a list of path by importance
-- 1. storage_dir
-- 2. default storage_dir = ~/.excalidraw/ this might be just handled by configuring the default in setup or config.
-- 3. CWD/.excalidraw/
-- 4. Current file directory
---@param link string The link or file path to resolve.
---@return string | nil The resolved absolute file path, or nil if the path cannot be resolved
M.resolve_path = function(link)
   if string.match(link, "^/") then
      if vim.fn.filereadable(link) == 1 then
         return link
      else
         return nil
      end
   end
   -- relative path cases:

   -- 1. storage_dir or 2. storage_dir default
   local relative_path = config.storage_dir .. '/' .. link
   if vim.fn.filereadable(relative_path) == 1 then
      return relative_path
   end

   -- 3. CWD/.excalidraw -- TODO: Missing case only with cwd and not .excalidraw done
   local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
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
M.construct_path = function(link)
   -- Construct the absolute path to the file
   if string.match(link, "^/") then
      return link
   end
   return config.storage_dir .. '/' .. link
end

return M
