local actions = require('telescope.actions')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local state = require('telescope.actions.state')

local conf = require('telescope.config').values

local entry_display = require('telescope.pickers.entry_display')

local n_of_digits = function(x)
  return math.floor(math.log10(x)) + 1
end

local pad = function(x, digits)
  return vim.fn.printf('%' .. tostring(digits) .. 'd', x)
end

local displayer = function(lnum_digits, col_digits)
  return entry_display.create {
    separator = ' ▏ ',
    items = {
      { width = lnum_digits },
      { width = col_digits },
      { remaining = true },
    },
  }
end

local make_display = function(lnum_digits, col_digits)
  return function(entry)
    return displayer(lnum_digits, col_digits) {
      { pad(entry.lnum, lnum_digits), 'TelescopeResultsLineNr' },
      { pad(entry.value.col, col_digits), 'TelescopeResultsLineNr' },
      { entry.value.filename, 'TelescopeResultsIdentifier' },
    }
  end
end

local entry_maker = function(lnum_digits, col_digits)
  return function(data)
    return {
      value = data,
      display = make_display(lnum_digits, col_digits),
      ordinal = data.filename,
      path = data.filename,
      lnum = data.lnum,
    }
  end
end

local qf_entry = function(data)
  return {
    filename = data.path.text,
    lnum = data.line_number,
    col = data.submatches[1].start + 2,
    text = data.submatches[1].text,
  }
end

local arg_key = function(key)
  if #key == 1 then
    return ' -' .. key
  else
    return ' --' .. key
  end
end

local make_command = function(opts)
  if opts.args then
    return 'rg --json ' .. opts.args
  end

  local query = opts.query
  if query == nil or query == '' then
    query = vim.fn.input('rg: ')
  end

  if query == nil or query == '' then
    return nil
  end

  local result = 'rg --json --regexp ' .. vim.fn.shellescape(query)

  for key, value in pairs(opts) do
    if key ~= 'query' then
      if type(value) == 'boolean' then
        result = result .. arg_key(key)
      else
        result = result .. arg_key(key) .. '=' .. vim.fn.shellescape(tostring(value))
      end
    end
  end

  return result
end

return function(opts)
  opts = opts or {}

  local qf_entries = {}
  local max_lnum = 0
  local max_col = 0

  local command = make_command(opts)
  if command == nil then
    return
  end

  for _, line in pairs(vim.fn.systemlist(command)) do
    local entry = vim.fn.json_decode(line)
    if entry['type'] == 'match' then
      table.insert(qf_entries, qf_entry(entry.data))
      max_lnum = math.max(max_lnum, entry.data.line_number)
      max_col = math.max(max_col, entry.data.submatches[1].start + 2)
    end
  end

  vim.fn.setqflist(qf_entries)

  pickers
    .new(opts, {
      prompt_title = 'rg',
      finder = finders.new_table {
        results = qf_entries,
        entry_maker = entry_maker(n_of_digits(max_lnum), n_of_digits(max_col)),
      },
      sorter = conf.file_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local data = state.get_selected_entry().value
          vim.cmd('edit ' .. data.filename)
          vim.fn.cursor(data.lnum, data.col)
        end)
        return true
      end,
    })
    :find()
end
