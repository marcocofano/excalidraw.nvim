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

local open = require "excalidraw.commands.open"
local create = require "excalidraw.commands.create"
local create_from_template = require "excalidraw.commands.create_from_template"

M.register_subcommand("open", open)
M.register_subcommand("create", create)
M.register_subcommand("create_from_template", create_from_template)


return M
