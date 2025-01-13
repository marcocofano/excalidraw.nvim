---The following classes are a first try at abstract the content and notion of scenes in Excalidraw.
---For now there is nothing more that can be done with the plugin apart from handling .md files and excalidraw relationship.
---
---
---@class excalidraw.SceneContent
---
---@field type string
---@field version integer
---@field source string
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
   self.path = path
   self.title = title
   self.content = {
      type = "excalidraw",                   -- TODO: type excalidraw only
      version = 2,                           -- TODO: only version 2 available
      source = "https://www.excalidraw.com", -- TODO: only this source fixed for now
      elements = {},
      appState = {
         gridSize = 10,
         viewBackgroundColor = "#aaaaaa"
      },
      files = {}
   }
   self:load_content_from_table(content)
   return self
end




Scene.load_content_from_table = function(self, content, overwrite)
   content = content or {}
   overwrite = overwrite or false

   if overwrite == true then
      self.content.elements = content.elements or {}
      self.content.appState = content.appState or {}
      self.content.files = content.files or {}
   else
      self.content.elements = vim.tbl_deep_extend("force", self.content.elements, content.elements or {})
      self.content.appState = vim.tbl_deep_extend("force", self.content.appState, content.appState or {})
      self.content.files = vim.tbl_deep_extend("force", self.content.files, content.files or {})
   end
   return self
end

Scene.from_json = function(path, json_content)
   local scene = Scene.new(path, json_content)
   json_content = json_content or '{}'

   local decoded_content = vim.fn.json_decode(json_content)
   scene:load_content_from_table(decoded_content, false)
   return scene
end

Scene.to_json = function(self)
   return vim.fn.json_encode(self.content)
end

Scene.add_element = function(self, element)
   table.insert(self.content.elements, element)
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


return Scene
