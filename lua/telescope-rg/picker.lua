local actions = require('telescope.actions')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local state = require('telescope.actions.state')

local conf = require("telescope.config").values
local utils = require('telescope.utils')

local entry_display = require('telescope.pickers.entry_display')


local digits = function (x)
  return math.floor(math.log10(x)) + 1
end


local pad = function (x, digits)
  return vim.fn.printf('%' .. tostring(digits) .. 'd', x)
end


local displayer = function (lnum_digits, col_digits)
  return entry_display.create {
    separator = ' ▏ ',
    items = {
      { width = lnum_digits },
      { width = col_digits },
      { remaining = true },
    },
  }
end


local make_display = function (lnum_digits, col_digits)
  return function (entry)
    return displayer(lnum_digits, col_digits) {
      { pad(entry.lnum, lnum_digits), 'TelescopeResultsLineNr' },
      { pad(entry.value.col, col_digits), 'TelescopeResultsLineNr' },
      { entry.value.filename, 'TelescopeResultsIdentifier' },
    }
  end
end


local entry_maker = function (lnum_digits, col_digits)
  return function (data)
    return {
      value = data,
      display = make_display(lnum_digits, col_digits),
      ordinal = data.filename,
      path = data.filename,
      lnum = data.lnum,
    }
  end
end


local qf_entry = function (data)
  return {
    filename = data.path.text,
    lnum = data.line_number,
    col = data.submatches[1].start + 2,
    text = data.submatches[1].text,
  }
end


local command = function (opts)
  local query = opts.query or vim.fn.input('Query: ')

  local result = 'rg --json --regexp ' .. vim.fn.shellescape(query)
  if opts.type then
    result = result .. ' --type ' .. vim.fn.shellescape(opts.type)
  end
  return result
end


return function (opts)
  opts = opts or {}

  local qf_entries = {}
  local max_lnum = 0
  local max_col = 0

  for _, line in pairs(vim.fn.systemlist(command(opts))) do
    local entry = vim.fn.json_decode(line)
    if entry['type'] == 'match' then
      table.insert(qf_entries, qf_entry(entry.data))
      max_lnum = math.max(max_lnum, entry.data.line_number)
      max_col = math.max(max_col, entry.data.submatches[1].start + 2)
    end
  end

  vim.fn.setqflist(qf_entries)

  pickers.new(opts, {
    prompt_title = 'rg',
    finder = finders.new_table {
      results = qf_entries,
      entry_maker = entry_maker(digits(max_lnum), digits(max_col)),
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
