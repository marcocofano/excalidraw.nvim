local M                = {}

-- Open a excalidraw scene from a markdown link (or just a string with a path to a scene)
M.open_excalidraw_link = function(client, _)
   local link = vim.fn.expand('<cfile>')
   if client:open_scene_link(link) == nil then
      vim.notify("No valid .excalidraw link under cursor", vim.log.levels.WARN)
   end
end

function M.run(client, _)
   return M.open_excalidraw_link(client, _)
end

return M
