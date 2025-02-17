local M = {}

M.subcommands = {}

function M.register_subcommand(name, handler)
   M.subcommands[name] = handler
end

function M.install(client)
   vim.api.nvim_create_user_command("Excalidraw",
      function(args)
         local cmd = args.fargs[1]
         if M.subcommands[cmd] then
            M.subcommands[cmd].run(client, vim.list_slice(args.fargs, 2))
         else
            vim.api.nvim_err_writeln("Invalid subcommand: " .. (cmd or ""))
         end
      end,
      {
         nargs = "+",
         complete = function(arg_lead, _, _)
            local matches = {}
            for _, cmd in pairs(vim.tbl_keys(M.subcommands)) do
               if vim.startswith(cmd, arg_lead) then
                  table.insert(matches, cmd)
               end
            end
            return matches
         end,
      }
   )
end

local open_link = require "excalidraw.commands.open_link"
local create = require "excalidraw.commands.create"
local create_from_template = require "excalidraw.commands.create_from_template"
local find_scenes = require "excalidraw.commands.find_scenes"
local find_scenes_in_buffer = require "excalidraw.commands.find_scenes_in_buffer"

M.register_subcommand("open_link", open_link)
M.register_subcommand("create", create)
M.register_subcommand("create_from_template", create_from_template)
M.register_subcommand("find_scenes", find_scenes)
M.register_subcommand("find_scenes_in_buffer", find_scenes_in_buffer)


return M
