local path_handler     = require "excalidraw.path_handler"
local config_mod       = require("excalidraw.config")

local M                = {}

-- Open a excalidraw canva from a markdown link (or just a string with a path to a canva)
M.open_excalidraw_file = function()
   local config = config_mod.get()
   -- Get the link or file name under the cursor
   local link = vim.fn.expand('<cfile>')
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

function M.run()
   return M.open_excalidraw_file()
end

return M
