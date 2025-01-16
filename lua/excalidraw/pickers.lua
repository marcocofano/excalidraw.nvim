local telescope         = require "telescope.builtin"
local telescope_actions = require "telescope.actions"
local actions_state     = require "telescope.actions.state"

local utils             = require "excalidraw.utils"

---@class excalidraw.TelescopePicker
---
---@field client excalidraw.Client
---@field calling_bufnr integer
local TelescopePicker   = {}
TelescopePicker.__index = TelescopePicker

TelescopePicker.new     = function(client)
   local self = setmetatable({}, TelescopePicker)
   self.client = client
   self.calling_bufnr = vim.api.nvim_get_current_buf()
   return self
end

---@class Excalidraw.AltMapping
---
---@field key string
---@field description string
---@field callback fun(path: string)

-- Build a search command
--
--
local _BASE_CMD         = { "rg", "--no-config" }
local _FIND_CMD         = vim.tbl_flatten { _BASE_CMD, "--files" }
---
---@return string[]
local _build_find_cmd   = function(path)
   local additional_opts = {}
   if path ~= nil and path ~= "." then
      additional_opts[#additional_opts + 1] = path
   end
   local find_command = vim.tbl_flatten { _FIND_CMD, additional_opts }
   return find_command
end


--- Build a prompt
---
---@param opts { prompt_title: string, alt_mappings: Excalidraw.AltMapping[]|Excalidraw.AltMapping|?}
local _build_prompt = function(opts)
   local prompt = opts.prompt_title or "Find Files"
   if string.len(prompt) > 50 then
      prompt = string.sub(prompt, 1, 50) .. "..."
   end

   prompt = prompt .. " | <CR> Open"

   if opts.alt_mappings then
      for _, alt_mapping in ipairs(opts.alt_mappings) do
         prompt = prompt .. " | " .. alt_mapping.key .. " " .. alt_mapping.description
      end
   end
   return prompt
end



---@param opts {callback: fun(path: string)|?, alt_mappings: Excalidraw.AltMapping[]}
local function attach_picker_mappings(map, opts)
   opts = opts or {}
   if opts.callback then
      map({ "i", "n" }, "<CR>", function(prompt_bufnr)
         local selection = actions_state.get_selected_entry()

         telescope_actions.close(prompt_bufnr)
         if selection then
            opts.callback(selection["path"] or "")
         end
      end)
   end

   if opts.alt_mappings then
      for _, alt_mapping in ipairs(opts.alt_mappings) do
         map({ "i", "n" }, alt_mapping.key, function(prompt_bufnr)
            local selection = actions_state.get_selected_entry()

            telescope_actions.close(prompt_bufnr)
            alt_mapping.callback(selection["path"] or "")
         end)
      end
   end
end


---@class Excalidraw.LinkSceneMapping : Excalidraw.AltMapping


---@return Excalidraw.LinkSceneMapping
TelescopePicker._build_link_scene_mapping = function(self)
   ---@type Excalidraw.LinkSceneMapping
   local mapping = {}
   mapping =  {
      key = self.client.opts.picker.link_scene_mapping,
      description = "insert link",
      callback = function (path)
         local scene = self.client:create_scene_from_path("", path)

         local link = self.client:build_markdown_link(scene)
         vim.api.nvim_put({ link }, 'l', true, false)

         if self.client.opts.open_on_create == true then
            vim.fn.searchpos("]", "e")
            self.client:open_scene_link(scene.path)
         end
      end
   }
   return mapping
end


---@class excalidraw.PickerFindOpts
---
---@field prompt_title string|?
---@field dir string|?
---@field callback fun(path: string)|?
---@field alt_mappings Excalidraw.AltMapping[]

---@param opts excalidraw.PickerFindOpts|?
TelescopePicker.find_files = function(self, opts)
   opts = opts or {}

   local prompt_title = _build_prompt {
      prompt_title = opts.prompt_title,
      alt_mappings = opts.alt_mappings
   }

   telescope.find_files {
      prompt_title = prompt_title,
      cwd = opts.dir or self.client.opts.storage_dir,
      find_command = _build_find_cmd("."), -- we are already in cwd = templates_dir
      attach_mappings = function(_, map)
         attach_picker_mappings(map, {
            callback = opts.callback,
            alt_mappings = opts.alt_mappings
         })
         return true
      end
   }
end




---Find scenes in the configured scenes folder
---
---@param opts { prompt_title: string|?, callback: fun(path: string)|?}
TelescopePicker.find_excalidraw_scenes = function(self, opts)
   opts = opts or {}

   local storage_dir = self.client.opts.storage_dir

   if not storage_dir then
      vim.notify("Excalidraw Scenes directory not found.")
      return
   end
   -- print("test: ", vim.inspect(self:_build_link_scene_mapping()))
   return self:find_files {
      prompt_title = opts.prompt_title or "Excalidraw Scenes",
      callback = opts.callback,
      dir = storage_dir,
      alt_mappings = {
         self:_build_link_scene_mapping()
      }
   }
end

---Find templates in the configured templates folder
---
---@param opts { prompt_title: string|?, callback: fun(path: string|?}
TelescopePicker.find_excalidraw_templates = function(self, opts)
   opts = opts or {}

   local templates_dir = self.client.opts.templates_dir

   if not templates_dir then
      vim.notify("Templates directory not found.")
      return
   end

   return self:find_files {
      prompt_title = opts.prompt_title or "Excalidraw Templates",
      callback = opts.callback,
      dir = templates_dir,
   }
end


TelescopePicker.find_scenes_in_buffer = function(self, opts)
   local pickers = require('telescope.pickers')
   local finders = require('telescope.finders')
   local conf = require('telescope.config').values

   local links = utils.search_excalidraw_links(self.calling_bufnr)

   pickers.new({}, {
      prompt_title = "Excalidraw Links",
      finder = finders.new_table {
         results = links,
         entry_maker = function(entry)
            return {
               value = entry.value,
               display = entry.text .. " -> " .. entry.value,
               ordinal = entry.text .. " " .. entry.value,
            }
         end,
      },
      sorter = conf.generic_sorter({}),
      attach_mappings = function(_, map)
         map("i", "<CR>", function(prompt_bufnr)
            local selection = actions_state.get_selected_entry()
            opts.callback(selection.value)
            telescope_actions.close(prompt_bufnr)
         end)
         return true
      end,
   }):find()
end

return TelescopePicker
