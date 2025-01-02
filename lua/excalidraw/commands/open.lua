local M                = {}

-- Open a excalidraw canva from a markdown link (or just a string with a path to a canva)
M.open_excalidraw_file = function(client, _)
   local link = vim.fn.expand('<cfile>')
   print("client: ", vim.inspect(client))
   client:open_canva_link(link)
end

function M.run(client, _)
   return M.open_excalidraw_file(client, _)
end

return M
