local actions = require('telescope.actions')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local state = require('telescope.actions.state')

local conf = require("telescope.config").values
local utils = require('telescope.utils')

local entry_display = require('telescope.pickers.entry_display')


local displayer = entry_display.create {
  separator = ' ▏ ',
  items = {
    { width = 3 },
    { width = 3 },
    { remaining = true },
  },
}


local pad = function (n)
  return vim.fn.printf('%3d', n)
end


local make_display = function (entry)
  return displayer {
    { pad(entry.lnum), 'TelescopeResultsLineNr' },
    { pad(entry.value.col), 'TelescopeResultsLineNr' },
    { entry.value.filename, 'TelescopeResultsIdentifier' },
  }
end


local entry_maker = function (data)
  return {
    value = data,
    display = make_display,
    ordinal = data.filename,
    path = data.filename,
    lnum = data.lnum,
  }
end


local qf_entry = function (data)
  return {
    filename = data.path.text,
    lnum = data.line_number,
    col = data.submatches[1].start + 2,
    text = data.submatches[1].text,
  }
end


return function (query, opts)
  opts = opts or {}

  local qf_entries = {}
  for _, line in pairs(vim.fn.systemlist('rg --json ' .. vim.fn.shellescape(query))) do
    local entry = vim.fn.json_decode(line)
    if entry['type'] == 'match' then
      table.insert(qf_entries, qf_entry(entry.data))
    end
  end

  vim.fn.setqflist(qf_entries)

  pickers.new(opts, {
    prompt_title = 'rg',
    finder = finders.new_table {
      results = qf_entries,
      entry_maker = entry_maker,
    },
    sorter = conf.file_sorter(opts),
    previewer = conf.grep_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local data = state.get_selected_entry().value
        vim.cmd('edit ' .. data.filename)
        vim.fn.cursor(data.lnum, data.col)
      end)
      return true
    end,
  }):find()
end
