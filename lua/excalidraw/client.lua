--- Excalidraw.nvim. Lua API Documentation
---
--- ============================================================================
---
--- Table of Contents
---
---@toc

local utils = require "excalidraw.utils"
local Scene = require "excalidraw.scene"


--- The Client class, a main store for setup options and main api.
---
--- The Excalidraw.nvim plugin manages your scenes in md files. It keeps
--- organized and linked all your drawings in your note-taking vault. If using
--- Obsidian, this should remind you of the Excalidraw plugin there. For this 
--- reason this plugin is directly inspired by Obsidian.nvim as it is clear from
--- the following client class (although in a simplified fashion)
---
--- Reference: https://github.com/epwalsh/obsidian.nvim for the original 
--- obsidian.nvim work.
---
---@toc_entry excalidraw.Client
---@class excalidraw.Client
---@field opts excalidraw.config.ClientOpts
local Client   = {}
Client.__index = Client


Client.new = function(opts)
   local self = setmetatable({}, Client)
   self.opts = opts

   self.opts.storage_dir = vim.fn.expand(self.opts.storage_dir)
   return self
end

---@class excalidraw.CreateSceneOpts
---@field title string
---@field dir string
---@field template excalidraw.Scene|?


--- Create a new scene object
---
--- This is a builder method to create the scenes from just a title
---
---@param opts excalidraw.CreateSceneOpts Options
---
--- Create scene builder from the user input or input argument
--- set filename with extension
--- expand to absolute according to configs or input path
--- save separately the relative path, it might be used for the md link
--- @return excalidraw.Scene
Client.create_scene = function(self, opts)
   -- validate arguments
   if not opts or opts == {} then
      error("Client.create_scene error: no opts")
   end
   if opts.title == nil or opts.title == "" then
      error("Client.create_scene error: missing argument opts.title")
   end
   local filename = opts.title:gsub(" ", "_") .. ".excalidraw"
   local relative_path
   if opts.dir and opts.dir ~= "" then
      relative_path = vim.fs.joinpath(opts.dir, filename)
   else
      relative_path = filename
   end

   local absolute_path = self:resolve_path(relative_path)
   if vim.fn.filereadable(absolute_path) == 1 then
      vim.notify("File already exists: " .. absolute_path, vim.log.levels.ERROR)
      error("Client.create_scene error: File already exists")
   end


   ---@type excalidraw.Scene
   local new_scene = Scene.new(
      opts.title,
      absolute_path
   )

   -- handle content creation
   if not opts.template then
      new_scene:load_content_from_table(self.default_template_content())
   else
      new_scene:load_content_from_table(opts.template.content)
   end
   return new_scene
end

-- Load Scene from a file
Client.create_scene_from_path = function(self, title, filepath)
   --TODO: add scene content validation like a is_valid method
   --
   filepath = self:resolve_path(filepath)
   local file = io.open(filepath, "r")
   if not file then
      error("Could not open file: " .. filepath)
   end
   local content = file:read("*a")
   file:close()
   return Scene.from_json(title, filepath, content)
end

---@param scene excalidraw.Scene
Client.save_scene = function(self, scene)
   if scene == nil then -- TODO: make a is_valid method
      error("No scene to be saved")
   end

   local absolute_path = self:resolve_path(scene.path)
   scene.path = absolute_path
   utils.ensure_directory_exists(vim.fn.fnamemodify(absolute_path, ":h"))
   scene:save()
end


--- Open a Scene object from a link
---
---@param self excalidraw.Client
---@param link string
Client.open_scene_link = function(self, link)
   -- Check if the link ends with .excalidraw
   if string.match(link, '%.excalidraw$') then
      -- contruct path from the input
      local filepath = self:resolve_path(link)
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
      vim.notify("No valid .excalidraw link", vim.log.levels.DEBUG)
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
   -- taken from Obsidian.nvim could use plenary's version from Path, given that Telescope is mandatory for now
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
      return relative_path
   elseif not is_absolute(path) then
      return path
   elseif opts.strict then
      error(string.format("failed to resolve '%s' relative to storage_dir '%s'", path, self.opts.storage_dir))
   end
end

--- Build the links string in Markdown format, from the scene data: title and 
--- path.
---@param scene excalidraw.Scene
---@return string|nil
Client.build_markdown_link = function(self, scene)
   local markdown_link = ""
   if not scene.path or scene.path == "" then
      return nil
   end
   if self.opts.relative_path then
      local relative_path = self:relative_path(scene.path, { strict = true })

      markdown_link = "[" .. scene.title .. "](" .. relative_path .. ")"
   else
      markdown_link = "[" .. scene.title .. "](" .. scene.path .. ")"
   end
   return markdown_link
end

--- Construct the absolute path to the file, with various options. 
--- If storage_dir is given and the path is relative, resolve from there.
---@param input string The link to construct the path for.
---@return string  The constructed absolute path.
Client.resolve_path = function(self, input)
   if not input then
      error("input path is mandatory to be expanded")
   end

   -- 1. Absolute input, return as-is
   if input:sub(1, 1) == "/" then
      return input
   end

   -- 2. Input path starting with "./" or similar, expand relative to CWD
   if input:sub(1, 2) == "./" then
      return vim.fn.getcwd() .. "/" .. input:sub(3)
   end

   -- 3. input starting with "~", expand to home directory
   if input:sub(1, 1) == "~" then
      local home = vim.fn.expand("~")
      return home .. input:sub(2)
   end

   -- 4. Default case: Expand relative to storage_dir
   return vim.fs.joinpath(vim.fn.fnamemodify(self.opts.storage_dir, ":p"), input)
end

--- The default content used to create new Scenes
Client.default_template_content = function()
   local default_content = {
      type = "excalidraw",                   -- TODO: type excalidraw only
      version = 2,                           -- TODO: only version 2 available
      source = "https://www.excalidraw.com", -- TODO: only this source fixed for now
      elements = {},
      appState = {
         gridSize = nil,
         viewBackgroundColor = "#aaaaaa"
      },
      files = {}
   }
   return default_content
end

--- Get a new Telescope Picker and load the Client reference to it 
Client.picker = function(self)
   local TelescopePicker = require "excalidraw.pickers"
   return TelescopePicker.new(self)
end


return Client
