local M = {}

-- Create an excalidraw scene file and a markdown link to it, optionally it opens it
---@param client excalidraw.Client
---@param data table<string>
M.find_scenes = function(client, data)
   if not client.opts.templates_dir then
      vim.notify("Templates folder is not defined or does not exist", vim.log.levels.ERROR)
      return
   end

   ---@type excalidraw.TelescopePicker
   local picker = client:picker()
   if not picker then
      vim.notify("No picker configured", vim.log.levels.ERROR)
      return
   end
   picker:find_excalidraw_scenes {
      callback = function(path)
         client:open_scene_link(path)
      end
   }
end

function M.run(client, data)
   return M.find_scenes(client, data)
end

return M
