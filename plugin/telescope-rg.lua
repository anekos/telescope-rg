local picker = require('telescope-rg.picker')

function search_command(args)
  picker(args.args, {})
end


vim.api.nvim_create_user_command(
  'Rg',
  search_command,
  {
    nargs = "*",
  }
)
