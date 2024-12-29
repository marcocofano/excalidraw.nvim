local M = {}

local uv = vim.loop

---@param path string
---@param mode integer
function M.mkdir_recursive(path, mode)
   local parent = path:match("(.+)/[^/]+")
   if parent and not uv.fs_stat(parent) then
      M.mkdir_recursive(parent, mode) -- Ensure parent directories exist
   end
   if not uv.fs_stat(path) then
      uv.fs_mkdir(path, mode)
   end
end

---@param octal integer
function M.octal_to_decimal(octal)
   return tonumber(octal, 8)
end

---@param dir string The directory path to ensure exists.
function M.ensure_directory_exists(dir)
   if vim.fn.isdirectory(dir) == 1 then
      return 0
   end
   -- Create the directory with 'p' flag to make parent directories if needed
   local success, err = pcall(function()
      vim.fn.mkdir(dir, "p")
   end
   )

   if not success then
      if err:match("Vim:E739") then
         vim.notify("Permission denied: Cannot create directory '" .. dir .. "'", vim.log.levels.ERROR)
      else
         vim.notify("Error creating directory '" .. dir .. "': " .. err, vim.log.levels.ERROR)
      end
   end
end

return M
