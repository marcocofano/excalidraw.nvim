local telescope         = require "telescope.builtin"
local telescope_actions = require "telescope.actions"
local actions_state     = require "telescope.actions.state"

local utils             = require "excalidraw.utils"
local Scene             = require "excalidraw.scene"

---@class excalidraw.TelescopePicker
---
---@field client excalidraw.Client
---@field calling_bufnr integer -- TODO: not sure it is needed
local TelescopePicker   = {}
TelescopePicker.__index = TelescopePicker

TelescopePicker.new     = function(client)
   local self = setmetatable({}, TelescopePicker)
   self.client = client
   self.calling_bufnr = vim.api.nvim_get_current_buf()
   return self
end

local function get_entry(prompt_bufnr, keep_open)
   local entry = actions_state.get_selected_entry()
   if entry and not keep_open then
      telescope_actions.close(prompt_bufnr)
   end
   return entry
end

---@param prompt_bufnr integer
---@param keep_open boolean|?
---@param allow_multiple boolean|?
---@return table[]|?
local function get_selected(prompt_bufnr, keep_open, allow_multiple)
   local picker = actions_state.get_current_picker(prompt_bufnr)
   local entries = picker:get_multi_selection()
   if entries and #entries > 0 then
      if #entries > 1 and not allow_multiple then
         vim.notify("This mapping does not allow multiple entries !!!", vim.log.levels.ERROR)
         return
      end

      if not keep_open then
         telescope_actions.close(prompt_bufnr)
      end

      return entries
   else
      local entry = get_entry(prompt_bufnr, keep_open)

      if entry then
         return { entry }
      end
   end
end


---@param opts { entry_key: string|?, callback: fun(path: string)|?, allow_multiple: boolean|?, query_mappings:excalidraw.PickerMappingTable|?, selection_mappings: excalidraw.PickerMappingTable|?, initial_query: string|? }
local function attach_picker_mappings(map, opts)
   local function entry_to_value(entry)
      if opts.entry_key then
         return entry[opts.entry_key]
      else
         return entry
      end
   end

   if opts.callback then
      map({ "i", "n" }, "<CR>", function(prompt_bufnr)
         local entries = get_selected(prompt_bufnr, false, false)
         if entries then
            local values = vim.tbl_map(entry_to_value, entries)
            opts.callback(unpack(values))
         end
      end)
   end
end

---@class excalidraw.PickerFindOpts
---
---@field prompt_title string|?
---@field dir string|?
---@field callback fun(path: string)|?
---@field selection_mapping excalidraw.PickerMappingsOpts|?

---@param opts excalidraw.PickerFindOpts|?
TelescopePicker.find_files = function(self, opts)
   opts = opts or {}

   local prompt_title = self:_build_prompt {
      prompt_title = opts.prompt_title,
      selection_mappings = opts.selection_mappings,
   }

   telescope.find_files {
      prompt_title = prompt_title,
      cwd = opts.dir or self.client.opts.storage_dir,
      find_command = self:_build_find_cmd("."), -- we are already in cwd = templates_dir
      attach_mappings = function(_, map)
         attach_picker_mappings(map, {
            entry_key = "path",
            callback = opts.callback,
            selection_mappings = opts.selection_mappings,
         })
         return true
      end
   }
end


---Find scenes for the configured scenes folder
---
---@param opts { prompt_title: string|?, callback: fun(path: string)|?, no_default_mappings: boolean|?}
TelescopePicker.find_excalidraw_scenes = function(self, opts)
   self.calling_bufnr = vim.api.nvim_get_current_buf()
   opts = opts or {}

   local storage_dir = self.client.opts.storage_dir

   if not storage_dir then
      vim.notify("Excalidraw Scenes directory not found.")
      return
   end

   return self:find_files {
      prompt_title = opts.prompt_title or "Excalidraw Scenes",
      callback = opts.callback,
      dir = storage_dir,
      no_default_mappings = true
   }
end

---Find templates for the configured templates folder
---
---@param opts { prompt_title: string|?, callback: fun(path: string)|?, no_default_mappings: boolean|?}
TelescopePicker.find_excalidraw_templates = function(self, opts)
   self.calling_bufnr = vim.api.nvim_get_current_buf()
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
      no_default_mappings = true
   }
end


TelescopePicker._BASE_CMD = { "rg", "--no-config" }
TelescopePicker._SEARCH_CMD = vim.tbl_flatten { TelescopePicker._BASE_CMD, "--json" }
TelescopePicker._FIND_CMD = vim.tbl_flatten { TelescopePicker._BASE_CMD, "--files" }
---
---@return string[]
TelescopePicker._build_find_cmd = function(self, path)
   local additional_opts = {}
   if path ~= nil and path ~= "." then
      additional_opts[#additional_opts + 1] = path
   end
   local find_command = vim.tbl_flatten { TelescopePicker._FIND_CMD, additional_opts }
   return find_command
end


--- Build a prompt
---
---@param opts { prompt_title: string, selection_mapping: excalidraw.PickerMappingTable|?}
TelescopePicker._build_prompt = function(self, opts)
   local prompt = opts.prompt_title or "Find"
   if string.len(prompt) > 50 then
      prompt = string.sub(prompt, 1, 50) .. "..."
   end

   prompt = prompt .. " | <CR> confirm"

   --TODO: add selection mappings
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
