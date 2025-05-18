M = {}

function M.find_and_replace()
    local cmd_string, selection
    local mode = vim.fn.mode()
    if mode == 'n' then
        selection = vim.fn.expand '<cword>'
        cmd_string = ':%s/' .. selection .. '//g<Left><Left><Space><BS>'
    elseif vim.list_contains({ 'v', 'V' }, mode) then
        local region = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = mode })
        -- BUG: Cannot replace multiple rows - somehow passing string to be replaced which
        -- is concatenated with `\n` breaks `nvim_feedkeys`. Adding `\n` after the Command
        -- text is populated works. `\n` might not be escaped?
        selection = table.concat(region, '\n')
        -- Escape potential regex symbols
        selection = vim.fn.escape(selection, '/\\[.*+?^$[-]')
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
        -- Space and Backspace to trigger substitute highlights
        cmd_string = ':%s/' .. selection .. '//g<Left><Left><Space><BS>'
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

--- Recurse up the filesystem, searching for any of the specified files
--- BUG: Should search each directory for the files, then traverse up, not try to find each
--- file by traversing up
--- @param start_dir string
--- @param filenames string[]
--- @return boolean, string|nil
function M.find_files_upwards(start_dir, filenames)
    local has, found_files = false, nil
    for i in pairs(filenames) do
        found_files = vim.fs.find(filenames[i], { upward = true, type = 'file', path = start_dir })
        if found_files[1] ~= nil then
            has = true
            break
        end
    end
    return has, found_files[1]
end

return M
