---@class excalidraw.Canva
--- The canva is a representation of the excalidraw file and its link and metadata
---
---@field title string|?
---@field filename string|?
---@field absolute_path string|?
---@field relative_path string|?
---@field content string|?
local Canva = {}
Canva.__index = Canva

Canva.new = function(title, filename, absolute_path, relative_path, content)
   local self = setmetatable({}, Canva)
   self.title = title
   self.filename = filename
   self.absolute_path = absolute_path
   self.relative_path = relative_path
   self.content = content
   return self
end

Canva.write_to_file = function (self)
   -- TODO: check if I can use pcall here
   if self.content ~= nil then
      local file = io.open(self.absolute_path, "w")
      print("lets see")
      if file then
         file:write(self.content)
         file:close()
         vim.notify("Created new Excalidraw file: " .. self.absolute_path)
      end
   else
      error("Error creating file: " .. self.absolute_path)
   end
end

---@arg type string
---@return string|nil
Canva.build_markdown_link = function (self, relative_path)
      local markdown_link = ""
      if relative_path then
         markdown_link = "[" .. self.title .. "](" .. self.relative_path .. ")"
      else
         markdown_link = "[" .. self.title .. "](" .. self.absolute_path .. ")"
      end
      return markdown_link
end

Canva.set_content = function (self, content)
   if content then
      self.content = content
   end
end

return Canva
