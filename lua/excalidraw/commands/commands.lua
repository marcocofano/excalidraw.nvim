local M = {}

M.subcommands = {}

function M.register_subcommand(name, handler)
   M.subcommands[name] = handler
end

function M.build_commands()
   vim.api.nvim_create_user_command("Excalidraw",
      function(args)
         local cmd = args.fargs[1]
         if M.subcommands[cmd] then
            M.subcommands[cmd].run(args.fargs)
         else
            vim.api.nvim_err_writeln("Invalid subcommand: " .. (cmd or ""))
         end
      end,
      {
         nargs = "+",
         complete = function()
            return vim.tbl_keys(M.subcomnands)
         end
      }
   )
end

return M
