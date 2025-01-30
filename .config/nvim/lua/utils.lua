M = {}

function M.find_and_replace()
    local cmd_string, selection
    local mode = vim.fn.mode()
    if mode == 'n' then
        selection = vim.fn.expand '<cword>'
        cmd_string = ':%s/' .. selection .. '//g<Left><Left><Space><BS>'
    elseif vim.list_contains({ 'v', 'V' }, mode) then
        local region = vim.fn.getregion(
            vim.fn.getpos 'v',
            vim.fn.getpos '.',
            { type = mode }
        )
        -- BUG: Somehow concatenating with `\n` breaks `nvim_feedkeys`.
        -- Removing `\n` here and manually adding it after the Command text
        -- is populated works. `\n` might not be escaped?
        selection = table.concat(region, '\n')
        -- Escape potential regex symbols
        selection = vim.fn.escape(selection, '/\\[.*+?^$()[-]')
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<Esc>', true, false, true),
            'n',
            true
        )
        -- Space and Backspace to trigger substitute highlights
        cmd_string = ':%s/' .. selection .. '//g<Left><Left><Space><BS>'
    end
    local escaped_cmd_string =
        vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
    vim.api.nvim_feedkeys(escaped_cmd_string, 'n', true)
end

function M.find_and_replace_globally()
    if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix ~= 1 then
        print 'This function can only be used in a quickfix buffer.'
        return
    end

    local cmd_string = ':cfdo %s/'
        .. vim.fn.expand '<cword>'
        .. '//g<Left><Left><Space><BS>'
    local escaped_cmd_string =
        vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
    vim.api.nvim_feedkeys(escaped_cmd_string, 'n', true)
end

--- Convenience function for printing objects
--- @param args table
function M.pprint(args)
    local str = ''
    for name, value in pairs(args) do
        str = str .. string.format('%s = %s, ', name, vim.inspect(value))
    end
    print(str)
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
