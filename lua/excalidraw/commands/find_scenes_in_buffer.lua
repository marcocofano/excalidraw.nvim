local M = {}

---@param client excalidraw.Client
---@param data table<string>
M.find_scenes_in_buffer = function(client, data)
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
   picker:find_scenes_in_buffer {
      callback = function(path)
         client:open_scene_link(path)
      end
   }
end

function M.run(client, data)
   return M.find_scenes_in_buffer(client, data)
end

return M
