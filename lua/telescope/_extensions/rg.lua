local telescope = require('telescope')

local picker = require('telescope-rg.picker')

return telescope.register_extension({
  -- setup = function(ext_conf, conf) end,
  exports = {
    rg = picker,
  },
})
