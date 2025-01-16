local config = {}

---@class Excalidraw.config.PickerOpts
---
---@field link_scene_mapping string

---@class excalidraw.config.ClientOpts
---@field storage_dir string
---@field templates_dir string
---@field open_on_create boolean
---@field relative_path boolean
---@field picker Excalidraw.config.PickerOpts


config.ClientOpts = {}


--- Get defaults
---
--- @return excalidraw.config.ClientOpts
config.ClientOpts.default = function()
   return {
      storage_dir = "~/.excalidraw",
      templates_dir = "~/.excalidraw/templates",
      open_on_create = true,
      relative_path = true,
      picker = {
         link_scene_mapping = "<C-l>"
      }
   }
end

--- TODO: Missing validation
---
---Override defaults with new opts
---
---@param config_overrides table<string, any>
---@param defaults excalidraw.config.ClientOpts|?-
---
---@return excalidraw.config.ClientOpts
config.ClientOpts.set = function(config_overrides, defaults)
   if not defaults then
      defaults = config.ClientOpts.default()
   end
   return vim.tbl_deep_extend("force", defaults, config_overrides or {})
end

return config
