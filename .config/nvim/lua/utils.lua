M = {}

function M.find_and_replace()
  local cmd_string, selection
  if vim.fn.mode() == 'n' then
    selection = vim.fn.expand '<cword>'
    cmd_string = ':%s/' .. selection .. '//g<Left><Left><Space><BS>'
  elseif vim.fn.mode() == 'v' then
    local vstart = vim.fn.getpos "'<"
    local vend = vim.fn.getpos "'>"
    selection = table.concat(vim.fn.getregion(vstart, vend), '\n')
    cmd_string = ':<BS><BS><BS><BS><BS>%s/' .. selection .. '//g<Left><Left><Space><BS>'
  end
  local escaped_cmd_string = vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
  vim.api.nvim_feedkeys(escaped_cmd_string, 'n', true)
end

function M.find_and_replace_globally()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix ~= 1 then
    print 'This function can only be used in a quickfix buffer.'
    return
  end

  local cmd_string = ':cfdo %s/' .. vim.fn.expand '<cword>' .. '//g<Left><Left><Space><BS>'
  local escaped_cmd_string = vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
  vim.api.nvim_feedkeys(escaped_cmd_string, 'n', true)
end

--- Convenience function for printing objects
--- @param obj any
--- @param name string?
function M.pprint(obj, name)
  if name ~= nil then
    vim.notify(name .. ' = ' .. vim.inspect(obj))
  else
    vim.notify(vim.inspect(obj))
  end
end

--- Print namespace under cursor
function M.print_value()
  if vim.fn.mode() == 'n' then
    local selection = vim.fn.expand '<cword>'
    local success, obj = pcall(parse_namespace, selection)
    if success then
      M.pprint(obj)
    else
      M.pprint 'Visual selection is not a valid Lua object'
    end
  elseif vim.fn.mode() == 'v' then
    local vstart = vim.fn.getpos "'<"
    local vend = vim.fn.getpos "'>"
    local selection = table.concat(vim.fn.getregion(vstart, vend), '\n')

    local success, obj = pcall(parse_namespace, selection)
    if success then
      M.pprint(obj, 'obj')
    else
      M.pprint 'Visual selection is not a valid Lua object'
    end
  end
end

--- Parse provided `aaa.bbb.ccc` namespace and lookup _G for the referenced object
--- @param namespace string: Namespace string
--- @return any: Looked up object
function parse_namespace(namespace)
  local matched = {}

  local obj = _G
  for g in string.gmatch(namespace, '[^%.]+') do
    table.insert(matched, g)
    if obj[g] == nil then
      local current_namespace = table.concat(matched, '.')
      error(string.format('`%s` namespace does not exist', current_namespace))
    end
    obj = obj[g]
  end
  return obj
end

return M
