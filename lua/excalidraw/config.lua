M = {}

local config = {
   storage_dir = "~/.excalidraw",
   open_on_create = true,
}

function M.set(config_overrides)
   config = vim.tbl_deep_extend("force", config, config_overrides or {})
end

function M.get()
   vim.inspect(config)
   return config
end

return M
