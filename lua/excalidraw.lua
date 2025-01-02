local config = require "excalidraw.config"
local commands = require "excalidraw.commands.commands"
local Client = require "excalidraw.client"

local excalidraw = {}


---@param opts excalidraw.config.ClientOpts
---
---@return excalidraw.Client
excalidraw.new = function(opts)
   return Client.new(opts)
end

--- Setup a new Excalidraw client. Overrides default configuration
---
---@param opts excalidraw.config.ClientOpts | table<string, any>
---
---@return excalidraw.Client
excalidraw.setup = function(opts)
   opts = config.ClientOpts.set(opts)
   local client = excalidraw.new(opts)

   commands.install(client)

   -- Set global client.
   excalidraw._client = client
   return client
end


return excalidraw
