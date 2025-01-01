---@class excalidraw.Canva
--- The canva is a representation of the excalidraw file and its link and metadata
---
---@field title string|?
---@field filename string|?
---@field absolute_path string|?
---@field relative_path string|?
---@field content string|?
---@field type string|? TODO: change it to enum in case we extend out from excalidaw, for now the string excalidraw

local Canva = {}
Canva.__index = Canva


local default_content = [[
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": {
    "gridSize": null,
    "viewBackgroundColor": "#afffff"
  },
  "files": {}
}
]]


Canva.new = function(title, filename, absolute_path, relative_path, type)
   local self = setmetatable({}, Canva)
   self.title = title
   self.filename = filename
   self.absolute_path = absolute_path
   self.relative_path = relative_path
   self.content = default_content
   self.type = type
   return self
end

function Canva:write_to_file()
   -- TODO: check if I can use pcall here
   local file = io.open(self.absolute_path, "w")
   if file then
      file:write(self.content)
      file:close()
      vim.notify("Created new Excalidraw file: " .. self.absolute_path)
   else
      vim.notify("Error creating file: " .. self.absolute_path, vim.log.levels.ERROR)
   end
end

---@arg type string
---@return string|nil
function Canva:build_markdown_link(relative_path)
      local markdown_link = ""
      if relative_path then
         markdown_link = "[" .. self.title .. "](" .. self.relative_path .. ")"
      else
         markdown_link = "[" .. self.title .. "](" .. self.absolute_path .. ")"
      end
      return markdown_link
end

function Canva:set_content(content)
   if content then
      self.content = content
   end
end


-- ---@type excalidraw.Canva
-- local new_canva = Canva.new(
--    "title",
--    "filename",
--    "/the/path/is/absolute/file.excalidraw",
--    "the/relative/path/file.excalidraw",
--    "excalidraw"
--    )




print(vim.inspect(new_canva))

return Canva
