local telescope_installed, telescope = pcall(require, 'telescope')

if not telescope_installed then
    error('This plugin requires nvim-telescope/telescope.nvim')
end

local picker = require('telescope._extensions.rg.picker')

return telescope.register_extension({
  setup = function(ext_conf, conf)
  end,
  exports = {
  },
})
