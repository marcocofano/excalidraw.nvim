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
   return self
end

---@class excalidraw.CreateCanvaOpts
---@field title string
---@field dir string
---@field template string|?


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
   if opts.dir then
      relative_path = vim.fs.joinpath(opts.dir, filename)
   end
      relative_path = filename

   local absolute_path = path_handler.expand_to_absolute(relative_path, self.opts.storage_dir)
   if vim.fn.filereadable(absolute_path) == 1 then
      vim.notify("File already exists: " .. absolute_path, vim.log.levels.ERROR)
      error("Client.create_canva error: File already exists")
   end

   local absolute_dir = vim.fn.fnamemodify(absolute_path, ":p:h")

   utils.ensure_directory_exists(absolute_dir)


   ---@type excalidraw.Canva
   local new_canva = Canva.new(
      opts.title,
      opts.title,
      absolute_path,
      relative_path
   )
   return new_canva
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

---Create a Canva object from a link
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

return Client
