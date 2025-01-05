---The following classes are a first try at abstract the content and notion of scenes in Excalidraw.
---For now there is nothing more that can be done with the plugin apart from handling .md files and excalidraw relationship.
---
---
---@class excalidraw.SceneContent
---
---@field type string
---@field version string
---@field source string
---@field title string
---@field elements table
---@field appState table
---@field files table


---@class excalidraw.Scene
--- The scene is a representation of the excalidraw file, its link and metadata
---
---@field title string
---@field path string
---@field content excalidraw.SceneContent|?
local Scene = {}
Scene.__index = Scene

Scene.new = function(title, path, content)
   local self = setmetatable({}, Scene)
   self.title = title or "Untitled Scene"
   self.path = path
   self.content = content or {
      type = "excalidraw",       -- TODO: type excalidraw only
      version = 2,               -- TODO: only version 2 available
      title = self.title,
      source = "https://www.excalidraw.com", -- TODO: only this source fixed for now
      elements = {},
      appState = {
         gridSize = nil,
         viewBackgroundColor = "#aaaaaa"
      }
   }
   return self
end

Scene.load_from_json = function(self, json_content)
   local decoded = vim.fn.json_decode(json_content)

   self.content.elements = decoded.elements or self.content.elements
   self.content.appState = vim.tbl_deep_extend("force", self.content.appState, decoded.appState or {})
   self.content.files = decoded.files or self.content.files
end

Scene.to_json = function(self)
   return vim.fn.json_encode(self.content)
end

Scene.add_element = function(self, element)
   table.insert(self.content.elements, element)
end

Scene.get_title = function(self)
   return self.title
end

Scene.set_title = function(self, new_title)
   self.title = new_title
end

Scene.exists = function(self)
   if self.path ~= nil then
      return vim.loop.fs_stat(self.path) ~= nil
   end
   return false
end

---@return string|?
Scene.filename = function(self)
   if self.path == nil then
      return nil
   end
   return vim.fs.basename(self.path)
end

Scene.save = function(self)
   -- TODO: check if I can use pcall here
   if not self.content or self.content == "" then
      error("No content in the Scene to write")
   end
   local file, err = io.open(self.path, "w")
   if not file then
      error("Cannot open the file: " .. self.path .. err)
   end
   local json_content = self:to_json()
   local ok, write_err = pcall(function()
      file:write(json_content)
   end)
   file:close()

   if not ok then
      file:close()
      return error("Cannot create content in " .. self.path .. (write_err or "unknown error"))
   end
   vim.notify("Created new Excalidraw file: " .. self.path)
end


Scene.set_content = function(self, content)
   if content then
      self.content = content
   end
end

return Scene
