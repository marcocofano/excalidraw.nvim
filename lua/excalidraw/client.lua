--- Client class, a main store for setup options and main api.
--- Directly inspired by Obsidian.nvim CLient class approach, it shares, (although in a simplified version,
--- many of its features). Hopefully this will enable to integrate directly into Obsidian.nvim in the future
--- Reference: https://github.com/epwalsh/obsidian.nvim for the original work.


local path_handler = require "excalidraw.path_handler"
local utils        = require "excalidraw.utils"
local Scene        = require "excalidraw.scene"

---@class excalidraw.Client
---@field opts excalidraw.config.ClientOpts
local Client       = {}
Client.__index     = Client


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

   local absolute_path = path_handler.expand_to_absolute(relative_path, self.opts.storage_dir)
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
      new_scene:load_content_from_table(opts.template.content) --TODO: to be adjusted.. including better validation for content, like it is done in load_from_json
   end
   return new_scene
end

-- Load Scene from a file
Client.create_scene_from_path = function(self, filepath)
   --TODO: verify is_absolute and other client validation
   local file = io.open(filepath, "r")
   if not file then
      error("Could not open file: " .. filepath)
   end
   local content = file:read("*a")
   file:close()
   return Scene.from_json(filepath, content)
end

---@param scene excalidraw.Scene
Client.save_scene = function(self, scene)
   if scene == nil then -- TODO: make a is_valid method
      error("No scene to be saved")
   end

   local absolute_path = path_handler.expand_to_absolute(scene.path, self.opts.storage_dir)
   scene.path = absolute_path
   utils.ensure_directory_exists(vim.fn.fnamemodify(absolute_path, ":h"))
   scene:save()
end

-- Client.clone_scene = function(self, title, path, scene)
--    if scene == nil or scene.content == nil then --TODO: make a is_valid method?
--       vim.notify("Cannot clone. Provide a valid scene.")
--       return
--    end
--    title = title or scene.title .. "(Copy)"
--    if not path or path == "" then
--       local dirname = vim.fn.fnamemodify(scene.path, ":h")
--       local filename = vim.fn.fnamemodify(scene.path, ":t:r")
--       local extension = vim.fn.fnamemodify(scene.path, ":e")
--
--       -- Construct the new filepath
--       local new_filename = filename .. "_copy" .. "." .. extension
--       local new_filepath = vim.fs.joinpath(dirname, new_filename)
--
--       path = new_filepath
--    else
--       path = path_handler.expand_to_absolute(path, self.opts.storage_dir)
--    end
--    return Scene.new(path, scene.content)
-- end

-- ---Create a scene object from a link
-- ---
-- ---@param self excalidraw.Client
-- ---@param link string
-- ---
-- ---@return excalidraw.Scene
-- Client.get_scene_from_link = function(self, link)
--    return Scene.new(link)
-- end

-- Client.open_scene = function(self, scene)
--    local scene_json = scene:to_json()
--    local url = "https://excalidraw.com/#json=" .. vim.fn.escape(scene_json, " ")
--
--    local cmd = ""
--    if self.opts.open_as_pwa then
--       cmd = "/opt/google/chrome/google-chrome  --app=" .. url
--       vim.fn.escape(scene_json, " ")
--    else
--       cmd = "xdg-open --app=" .. url -- Adjust for your OS
--    end
--    os.execute(cmd)
-- end


---Open a Scene object from a link
---
---@param self excalidraw.Client
---@param link string
Client.open_scene_link = function(self, link)
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
      error(string.format("failed to resolve '%s' relative to root '%s'", path, self.opts.storage_dir))
   end
end


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

Client.picker = function(self)
   local TelescopePicker = require "excalidraw.pickers"
   return TelescopePicker.new(self)
end


return Client
