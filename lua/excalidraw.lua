local M = {}

---@param configuration table Configuration options.
M.configure = function(configuration)
   require('excalidraw.config').set(configuration)
end

return M
