---@class excalidraw.Canva
--- The canva is a representation of the excalidraw file and its link and metadata
---
---@field title string
---@field path string
---@field content string|?
local Canva = {}
Canva.__index = Canva

Canva.new = function(title, path, content)
   local self = setmetatable({}, Canva)
   self.title = title
   self.path = path
   self.content = content
   return self
end

Canva.exists = function(self)
   if self.path ~= nil then
      return vim.loop.fs_stat(self.path) ~= nil
   end
   return false
end

---@return string|?
Canva.filename = function(self)
   if self.path == nil then
      return nil
   end
   return vim.fs.basename(self.path)
end

Canva.save = function(self)
   -- TODO: check if I can use pcall here
   if not self.content or self.content == "" then
     error("No content in the Canva to write")
   end
   local file, err = io.open(self.path, "w")
   if not file then
      error("Cannot open the file: " .. self.path .. err)
   end

   local ok, write_err = pcall(function()
      file:write(self.content)
   end)
   file:close()

   if not ok then
      file:close()
      return error("Cannot create content in " .. self.path .. (write_err or "unknown error"))
   end
   vim.notify("Created new Excalidraw file: " .. self.path)
end


Canva.set_content = function(self, content)
   if content then
      self.content = content
   end
end

return Canva
