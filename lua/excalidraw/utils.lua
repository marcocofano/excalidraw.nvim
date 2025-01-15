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
function M.ensure_directory_exists(dir, opts)
   opts = opts or { notify = true } -- Default behavior includes notifications

   if vim.fn.isdirectory(dir) == 1 then
      return true
   end

   -- Attempt to create the directory
   local success, err = pcall(function()
      vim.fn.mkdir(dir, "p")
   end)

   if not success then
      if err:match("Vim:E739") then
         if opts.notify then
            vim.notify("Permission denied: Cannot create directory '" .. dir .. "'", vim.log.levels.ERROR)
         end
         return false, "Permission denied"
      else
         if opts.notify then
            vim.notify("Error creating directory '" .. dir .. "': " .. err, vim.log.levels.ERROR)
         end
         return false, err
      end
   end

   return true
end

M.search_excalidraw_links = function (bufnr)
   local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
   local results = {}

   local pattern = "%[(.-)%]%((.-%.excalidraw)%)"

   for _, line in ipairs(lines) do
      for link_text, file_name in line:gmatch(pattern) do
         table.insert(results, {
            text = link_text,
            value = file_name,
         })
      end
   end

   return results
end
return M
