M = {}

function M.find_and_replace()
  local cmd_string = ':%s/' .. vim.fn.expand '<cword>' .. '//g<Left><Left><Space><BS>'
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
function pprint(obj, name)
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














function M.hard_wrap_comment(line_length)
  -- Get the current line number
  local current_line = vim.fn.line '.'

  -- Get the current line content
  local line_content = vim.fn.getline(current_line)

  -- If the line is empty, do nothing
  if #line_content == 0 then
    return
  end

  -- Break the line into words
  local words = vim.split(line_content, '%s+')

  -- Accumulate wrapped lines
  local wrapped_lines = {}
  local current_line_content = ''

  for _, word in ipairs(words) do
    -- Check if adding the word exceeds the line length
    if #current_line_content + #word + 1 > line_length then
      -- Push the current line content to wrapped_lines
      table.insert(wrapped_lines, current_line_content)
      -- Start a new line with the current word
      current_line_content = word
    else
      -- Append the word to the current line
      if #current_line_content > 0 then
        current_line_content = current_line_content .. ' '
      end
      current_line_content = current_line_content .. word
    end
  end

  -- Add the last line content
  if #current_line_content > 0 then
    table.insert(wrapped_lines, current_line_content)
  end

  -- Replace the current line with the wrapped lines
  vim.fn.setline(current_line, wrapped_lines)
  vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), current_line, current_line + 1, false, wrapped_lines)
end

vim.keymap.set('n', '<leader>F', function()
  M.hard_wrap_comment(88)
end, { desc = '[s]earch and [r]eplace' })

return M
