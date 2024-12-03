M = {}

function M.findAndReplace()
  local cmd_string = ':%s/' .. vim.fn.expand '<cword>' .. '//g<Left><Left><Space><BS>'
  local escaped_cmd_string = vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
  vim.api.nvim_feedkeys(escaped_cmd_string, 'n', true)
end

function M.findAndReplaceGlobally()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix ~= 1 then
    print 'This function can only be used in a quickfix buffer.'
    return
  end

  local cmd_string = ':cfdo %s/' .. vim.fn.expand '<cword>' .. '//g<Left><Left><Space><BS>'
  local escaped_cmd_string = vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
  vim.api.nvim_feedkeys(escaped_cmd_string, 'n', true)
end

return M
