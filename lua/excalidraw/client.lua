--- Client class, a main store for setup options and main api.
--- Directly inspired by Obsidian.nvim CLient class approach, it shares, (although in a simplified version,
--- many of its features). Hopefully this will enable to integrate directly into Obsidian.nvim in the future
--- Reference: https://github.com/epwalsh/obsidian.nvim for the original work.


local path_handler = require "excalidraw.path_handler"
local utils        = require "excalidraw.utils"
local Canva        = require "excalidraw.canva"

---@class excalidraw.Client
---@field opts excalidraw.config.ClientOpts
local Client       = {}
Client.__index     = Client

--TODO: change it to enum in case we extend out from excalidaw, for now the string excalidraw

Client.new         = function(opts)
   local self = setmetatable({}, Client)
   self.opts = opts

   self.opts.storage_dir = vim.fn.expand(self.opts.storage_dir, ":p")
   return self
end

---@class excalidraw.CreateCanvaOpts
---@field title string
---@field dir string
---@field template excalidraw.Canva|?


--- Create a new canva object
---
--- This is a builder method to create the canvas from just a title
---
---@param opts excalidraw.CreateCanvaOpts Options
---
--- Create canva builder from the user input or input argument
--- set filename with extension
--- expand to absolute according to configs or input path
--- save separately the relative path, it might be used for the md link
--- @return excalidraw.Canva
Client.create_canva = function(self, opts)
   -- validate arguments
   if not opts or opts == {} then
      error("Client.create_canva error: no opts")
   end
   if opts.title == nil or opts.title == "" then
      error("Client.create_canva error: missing argument opts.title")
   end
   local filename = opts.title:gsub(" ", "_") .. ".excalidraw"
   local relative_path
   if opts.dir and opts.dir ~= "" then
      relative_path = vim.fs.joinpath(opts.dir, filename)
   else
      relative_path = filename
   end

   local absolute_path = path_handler.expand_to_absolute(relative_path, self.opts.storage_dir)
   if vim.fn.filereadable(absolute_path) == 1 then
      vim.notify("File already exists: " .. absolute_path, vim.log.levels.ERROR)
      error("Client.create_canva error: File already exists")
   end

   local absolute_dir = vim.fn.fnamemodify(absolute_path, ":p:h")

   ---@type excalidraw.Canva
   local new_canva = Canva.new(
      opts.title,
      absolute_path
   )

   -- handle content creation
   if not opts.template then
      new_canva:set_content(self.default_template_content())
   else
      new_canva:set_content(opts.template.content)
   end
   return new_canva
end

Client.save_canva = function(self, canva)
   if canva == nil then -- TODO: make a is_valid method
      error("No Canva to be saved")
   end

   local absolute_path = path_handler.expand_to_absolute(canva.path, self.opts.storage_dir)
   canva.path = absolute_path
   utils.ensure_directory_exists(vim.fn.fnamemodify(absolute_path, ":h"))
   canva:save()
end

Client.clone_canva = function(self, title, path, canva)
   if canva == nil or canva.content == nil then --TODO: make a is_valid method?
      vim.notify("Cannot clone. Provide a valid canva.")
      return
   end
   title = title or canva.title .. "(Copy)"
   if not path or path == "" then
      local dirname = vim.fn.fnamemodify(canva.path, ":h")
      local filename = vim.fn.fnamemodify(canva.path, ":t:r")
      local extension = vim.fn.fnamemodify(canva.path, ":e")

      -- Construct the new filepath
      local new_filename = filename .. "_copy" .. "." .. extension
      local new_filepath = vim.fs.joinpath(dirname, new_filename)

      path = new_filepath
   else
      path = path_handler.expand_to_absolute(path, self.opts.storage_dir)
   end
   return Canva.new(title, path, canva.content)
end

---Create a Canva object from a link
---
---@param self excalidraw.Client
---@param link string
---
---@return excalidraw.Canva
Client.get_canva_from_link = function(self, link)
   return Canva.new(link)
end

---Open a Canva object from a link
---
---@param self excalidraw.Client
---@param link string
Client.open_canva_link = function(self, link)
   -- Check if the link ends with .excalidraw
   if string.match(link, '%.excalidraw$') then
      -- contruct path from the input
      local filepath = path_handler.expand_to_absolute(link, self.opts.storage_dir)
      if vim.fn.filereadable(filepath) ~= 1 or filepath == nil then
         vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
         return
      end
      vim.notify("Opening file: " .. filepath)

      -- Open the file with the system's default application
      if vim.fn.has('mac') == 1 then
         vim.cmd('silent !open ' .. vim.fn.shellescape(filepath))
      elseif vim.fn.has('win32') == 1 then
         vim.cmd('silent !start ' .. vim.fn.shellescape(filepath))
      else
         vim.cmd('silent !xdg-open ' .. vim.fn.shellescape(filepath))
      end
   else
      vim.notify("No valid .excalidraw link found under cursor", vim.log.levels.WARN)
      return
   end
end


local function is_absolute(path)
   if vim.startswith(path, "/") then
      return true
   end
   return false
end

local function relative_to(path, other)
   if not vim.endswith(other, "/") then
      other = other .. "/"
   end

   if vim.startswith(path, other) then
      return string.sub(path, string.len(other) + 1)
   end

   -- Edge cases when the paths are relative or under-specified, see tests.
   if not is_absolute(path) and not vim.startswith(path, "./") and vim.startswith(other, "./") then
      if other == "./" then
         return path
      end

      local path_rel_to_cwd = "./" / path
      if vim.startswith(path_rel_to_cwd, other) then
         return string.sub(path_rel_to_cwd, string.len(other) + 1)
      end
   end
end


--- Make a path relative to the storage_dir
---
---@param path string
---@param opts { strict: boolean|? }|?
---
---@return string|?
Client.relative_path = function(self, path, opts)
   opts = opts or {}

   local ok, relative_path = pcall(function()
      return relative_to(path, self.opts.storage_dir)
   end)

   if ok and relative_path then
      print("1: ", vim.inspect(relative_path))
      return relative_path
   elseif not is_absolute(path) then
      print("2: ")
      return path
   elseif opts.strict then
      error(string.format("failed to resolve '%s' relative to root '%s'", path, self.opts.storage_dir))
   end
end


---@param canva excalidraw.Canva
---@return string|nil
Client.build_markdown_link = function(self, canva)
   local markdown_link = ""
   if not canva.path or canva.path == "" then
      return nil
   end
   if self.opts.relative_path then
      local relative_path = self:relative_path(canva.path, { strict = true })

      markdown_link = "[" .. canva.title .. "](" .. relative_path .. ")"
   else
      markdown_link = "[" .. canva.title .. "](" .. canva.path .. ")"
   end
   return markdown_link
end

Client.default_template_content = function()
   local default_content = [[
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": {
    "gridSize": null,
    "viewBackgroundColor": "#ffffff"
  },
  "files": {}
}
]]
   return default_content
end

--Get the configured picker or default
Client.picker = function(self)
   local TelescopePicker = require "excalidraw.pickers"
   return TelescopePicker.new(self)
end

return Client
