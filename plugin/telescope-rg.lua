local picker = require('telescope-rg.picker')

function search_command(args)
  if args.bang then
    return picker({ args = args.args })
  else
    return picker({ query = args.args })
  end
end


vim.api.nvim_create_user_command(
  'Rg',
  search_command,
  {
    nargs = "*",
    bang = true,
  }
)
