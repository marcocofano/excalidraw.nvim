local utils = require "excalidraw.utils"
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
   local config = require("excalidraw.config").get()
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
   relative_path = cwd .. '/' .. link
   if vim.fn.filereadable(relative_path) == 1 then
      return relative_path
   end

   -- 4. Current file directory
   local current_dir = vim.fn.expand("%:p:h")
   relative_path = current_dir .. '/' .. link
   if vim.fn.filereadable(relative_path) == 1 then
      return relative_path
   end

   return nil
end

---Construct the absolute path to the file.
---@param input string The link to construct the path for.
---@return string | nil  The constructed absolute path.
M.expand_to_absolute = function(input, storage_dir)
   if not input then return nil end

   -- 1. Absolute input, return as-is
   if input:sub(1, 1) == "/" then
      return input
   end

   -- 2. Input path starting with "./" or similar, expand relative to CWD
   if input:sub(1, 2) == "./" then
      return vim.fn.getcwd() .. "/" .. input:sub(3)
   end

   -- 3. input starting with "~", expand to home directory
   if input:sub(1, 1) == "~" then
      local home = vim.fn.expand("~")
      return home .. input:sub(2)
   end

   -- 4. Default case: Expand relative to storage_dir
   return vim.fn.fnamemodify(storage_dir, ":p") .. input
end
return M
