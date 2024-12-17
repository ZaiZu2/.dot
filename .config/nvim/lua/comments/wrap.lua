-- TODO: Make column_width injectable/derivable from formatter settings (?)
-- TODO: Add support for justification to TODO markers
-- TODO: Recognize strings comments and allow for their formatting (python)
-- FIXME: Lua comments act weirdly:
-- E.g. this:
-- Comment with unusual spacing between lines
-- 
--  
-- This is an example with blank lines in between
local utils = require 'utils'
local p = utils.pprint

local com_syntax = require 'comments.map'
local tr = vim.treesitter
local line_width = 80

local is_whitespace_only = function(str)
    return not not string.match(str, '^%s*$')
end

---Extract comment symbols if available inside comment mapping
---@param com_type 'single'|'multi'
---@return string[]|nil
local function get_comment_symbol(com_type)
    local ft_syntax = com_syntax[vim.bo.filetype]
    if ft_syntax == nil then
        return nil
    end
    return ft_syntax[com_type]
end

---Traverse TS tree upwards in search of a closest parent node of the provided type
---@param initial_node TSNode|nil
---@param type string
---@return TSNode|nil
local function find_node(initial_node, type)
    local node = initial_node
    while node ~= nil do
        if node:type() == type then
            return node
        end
        node = node:parent()
    end
    return nil -- Didn't find a comment node
end

---Find all row-adjacent nodes of the same type which create a block
---@param initial_node TSNode
---@param bufnr integer
---@return TSNode[]
local function find_adjacent_nodes(initial_node, bufnr)
    local initial_type = initial_node:type()
    local cur_start, _, cur_end, _ = tr.get_node_range(initial_node)
    local found_nodes = { initial_node }

    -- Find upward row-adjacent comments
    ---@type TSNode|nil
    local prev_node = initial_node
    while prev_node ~= nil do -- Redundant, acts as a type guard so LSP does not complain
        prev_node = prev_node:prev_named_sibling() ---@diagnostic disable-line: need-check-nil
        if prev_node == nil then
            break
        end

        local prev_start, _, prev_end, _ = tr.get_node_range(prev_node)
        local prev_text = tr.get_node_text(prev_node, bufnr)
        if prev_node:type() ~= initial_type or cur_start - prev_end > 1 or is_whitespace_only(prev_text) then
            break
        end
        cur_start = prev_start
        table.insert(found_nodes, 1, prev_node) -- Prepend to table
    end

    -- Find downward row-adjacent comments
    ---@type TSNode|nil
    local next_node = initial_node
    while next_node ~= nil do -- Redundant, acts as a type guard so LSP does not complain
        next_node = next_node:next_named_sibling()
        if next_node == nil then
            break
        end

        local next_start, _, next_end, _ = tr.get_node_range(next_node)
        local next_text = tr.get_node_text(next_node, bufnr)
        if next_node:type() ~= initial_type or next_start - cur_end > 1 or is_whitespace_only(next_text) then
            break
        end
        cur_end = next_end
        table.insert(found_nodes, next_node) -- Append to table
    end

    return found_nodes
end

---Strip raw comment lines from comment symbols and concatenate
---the comment body into a single string
---@param lines string[]
---@return string com_prefix Character/s denoting a string
---@return string com_string Comment string
local function concatenate_comment(lines)
    local comments = {}
    local com_char, com_prefix
    for _, line in ipairs(lines) do
        -- Lua pattern matching does not support backreferences, hence split into 2 matches here
        -- Find what char is used as comment symbol
        com_char = string.match(line, '^%s*.')
        -- Check if it's not repeated like lua's --- or js's //
        com_prefix = string.match(line, '^%s*(' .. com_char .. '*)')
        -- Cut comment symbol from the comment
        line = string.gsub(line, '^%s*' .. com_char .. '*%s*', '')
        -- Cut trailing whitespaces
        line = string.gsub(line, '%s*$', '')
        table.insert(comments, line)
    end
    return com_prefix, table.concat(comments, ' ')
end

--- Take in a string and split it into lines of maximum `line_width`.
--- Respects word boundaries, and split the string only on whitespaces.
--- @param comment string
--- @param line_width integer
--- @return table
local function wrap_string(comment, line_width)
    local wrapped_lines, _ = {}, nil

    --- @type integer|nil
    local com_split_end = 1
    --- @type integer|nil
    local com_split_start = 0

    local is_final_substr = false
    -- Iterate over `comment`, cutting chunks out of it and building lines out of it
    while not is_final_substr do
        comment = string.sub(comment, com_split_start + com_split_end, -1)
        -- Skip over leading whitspaces first
        _, com_split_start = string.find(comment, '^%s*')
        if com_split_start == nil then
            com_split_start = 1
        else
            com_split_start = com_split_start + 1
        end

        -- Find limits of a new line, accounting for comment length available left
        local line_start = com_split_start
        local line_end
        if line_start + line_width > #comment then
            line_end = #comment
            is_final_substr = true
        else
            line_end = line_start + line_width
        end

        -- Substring a new line
        local substring = string.sub(comment, line_start, line_end)
        if not is_final_substr then
            -- Find if the new line is not splitting a word in a middle
            -- If it does, find the closest whitespace to the left of that word
            com_split_end, _ = string.find(substring, '%s*%S*$')
            if com_split_end == nil then -- Text occupies a full line width
                com_split_end = line_width
            -- TODO: Line might consist of only whitespaces (?), this is not handled here
            else
                com_split_end = com_split_end - 1
            end
            substring = string.sub(substring, 1, com_split_end)
        end

        table.insert(wrapped_lines, substring)
    end
    return wrapped_lines
end

--- Escape magic characters which might be part of a comment symbol
local escape = function(s)
    return string.gsub(s, '[.*+?^$()[%%-]', '%%%0')
end

---Parse a comment string to identify whether it's multiline
---@param com_text string Comment raw string
---@return string comment_body
---@return string[] comment_symbols Opening and closing character/s denoting a comment
local function parse_multiline(com_text)
    local multi_symbols = get_comment_symbol 'multi'
    if multi_symbols ~= nil then
        local prefix_rgx = '^%s*' .. escape(multi_symbols[1]) -- Match opening symbol
        local suffix_rgx = escape(multi_symbols[2]) .. '%s*$' -- Match closing symbol
        local body_rgx = '(.*)' -- Match comment content with all whitespaces and newline chars
        local com_body = string.match(com_text, prefix_rgx .. body_rgx .. suffix_rgx)
        if com_body ~= nil then
            return com_body, multi_symbols
        end
    else
        -- TODO: Implement inferred parsing
    end
    vim.notify(('Failed to match multiline %s comment - `%s`'):format(vim.bo.filetype, com_text))
    error(('Failed to match multiline %s comment - `%s`'):format(vim.bo.filetype, com_text))
end

---Split input string on newline characters and trim any leading/trailing whitespaces in lines
---@param com_body string
---@return table
local function split_multiline(com_body)
    com_body = com_body .. '\n' -- Needed for capturing last line

    local com_lines = {}
    for line in com_body:gmatch '(.-)\n' do -- Match groups separated by \n (split string)
        local trimmed_line = string.match(line, '^%s*(.-)%s*$')
        table.insert(com_lines, trimmed_line)
    end
    return com_lines
end

-- TODO: Skip for now, make the grammar based approach work first
---Parse a comment string to identify whether it's single-line
---@param com_text string Comment raw string
---@return 'single'|'multi'|nil comment_type `nil` means text failed to match to a comment using known comment symbols
---@return string comment_body
---@return string|string[] comment_symbol Opening character/s denoting a comment
local function infer_singleline(com_text)
    -- NOTE: Fallback to language-agnostic `prefix_symbol` inferrence if `ft_syntax`
    -- is not provided or the function did not return up to this point
    local com_char, com_prefix
    -- Lua pattern matching does not support backreferences, hence split into 2 matches here
    -- Find what char is used as comment symbol
    com_char = string.match(com_text, '^%s*')
    -- Check if it's not repeated like lua's --- or js's //
    com_prefix = string.match(com_text, '^%s*(' .. com_char .. '*)')
    -- Cut comment symbol from the comment
    com_text = string.gsub(com_text, '^%s*' .. com_char .. '*%s*', '')
    -- Cut trailing whitespaces
    com_text = string.gsub(com_text, '%s*$', '')
    return 'single', 'wrong', com_prefix -- FIXME: WRRONG
end

---Parse a comment string to identify whether it's single-line
---@param com_text string Comment raw string
---@return string comment_body
---@return string comment_symbol Opening character/s denoting a comment
local function parse_singleline(com_text)
    local single_symbols = get_comment_symbol 'single'
    -- p { single_symbols = single_symbols}
    if single_symbols ~= nil then
        -- Some languages have multiple symbols denoting a single-line comment
        for _, symbol in ipairs(single_symbols) do
            local prefix_rgx = '^%s*' .. escape(symbol) -- Match opening symbol
            local body_rgx = '%s*(.-)%s*$' -- Match comment content, but strip all outer whitespaces
            -- p { com_text = com_text, symbol = symbol,  }
            local com_body = string.match(com_text, prefix_rgx .. body_rgx)
            if com_body ~= nil then
                return com_body, symbol
            end
        end
    else
        -- TODO: Implement inferred parsing
        -- infer_singleline()
    end
    vim.notify(('Failed to match single-line %s comment - `%s`'):format(vim.bo.filetype, com_text))
    error(('Failed to match single-line %s comment - `%s`'):format(vim.bo.filetype, com_text))
end

local function find_subarray(array, index)
    if is_whitespace_only(array[index]) then
        return nil
    end

    local left, right = index, index
    for i = index, 1, -1 do
        if is_whitespace_only(array[i]) then
            break
        end
        left = i
    end
    for i = index, #array, 1 do
        if is_whitespace_only(array[i]) then
            break
        end
        right = i
    end
    return left, right
end

local function format_comment()
    local bufnr = vim.api.nvim_get_current_buf()
    local cur_win = vim.api.nvim_get_current_win()

    local cur_pos = vim.api.nvim_win_get_cursor(0)
    local cur_y, cur_x = unpack(cur_pos)
    cur_y, cur_x = cur_y - 1, cur_x -- Switch from (1,0) to (0,0) indexing

    -- Extract the node pointed at with the cursor and find the comment
    tr.get_parser(bufnr):parse()
    local init_node = tr.get_node { bufnr = bufnr, pos = { cur_y, cur_x } }
    init_node = find_node(init_node, 'comment')
    if init_node == nil then
        vim.notify 'Did not find a comment node'
        return
    end

    local init_row_start, init_col_start, init_row_end, _ = tr.get_node_range(init_node)
    local init_text = tr.get_node_text(init_node, bufnr)
    local com_type, com_text, comment_nodes, com_lines

    -- Try parsing as a multiline comment
    local success, com_body, com_symbol = pcall(parse_multiline, init_text)
    local left, right
    if success then
        com_type = 'multi'

        com_lines = split_multiline(com_body)
        -- Find and isolate a paragraph
        local rel_cur_y = cur_y - init_row_start + 1
        left, right = find_subarray(com_lines, rel_cur_y)
        if left == nil then
            vim.notify 'Selected line consists only of whitespaces'
            return
        end
        local paragraph_lines = table.move(com_lines, left, right, 1, {})
        com_text = table.concat(paragraph_lines, ' ')
    else -- Multiline didn't match, must be single-line
        com_type = 'single'
        -- Find all row-adjacent comment nodes
        comment_nodes = find_adjacent_nodes(init_node, bufnr)
        -- Extract node texts
        com_lines = {}
        for _, node in ipairs(comment_nodes) do
            local line = tr.get_node_text(node, bufnr)
            com_body, com_symbol = parse_singleline(line)
            table.insert(com_lines, com_body)
        end
        com_text = table.concat(com_lines, ' ')
    end

    local string_length, wrapped_lines, buffer_lines = nil, nil, {}
    if com_type == 'single' then
        -- Set comment length based on the current indentation
        string_length = line_width - init_col_start - #(com_symbol .. ' ')
        wrapped_lines = wrap_string(com_text, string_length)
        local indent = string.rep(' ', init_col_start)
        for i, line in ipairs(wrapped_lines) do
            buffer_lines[i] = indent .. com_symbol .. ' ' .. line
        end
        -- Replace buffer lines
        local rstart, _, _, _ = tr.get_node_range(comment_nodes[1])
        local _, _, rend, _ = tr.get_node_range(comment_nodes[#comment_nodes])
        vim.api.nvim_buf_set_lines(bufnr, rstart, rend + 1, true, buffer_lines)
        vim.api.nvim_win_set_cursor(cur_win, { rstart + 1, cur_x })
    elseif com_type == 'multi' then
        string_length = line_width - init_col_start
        wrapped_lines = wrap_string(com_text, string_length)

        local merged_lines = {}
        -- Remove old paragraph lines
        for i, line in ipairs(com_lines) do
            if i < left or i > right then
                table.insert(merged_lines, line)
            end
        end
        -- Inject formatted paragraph lines under correct index
        for i = #wrapped_lines, 1, -1 do
            table.insert(merged_lines, left, wrapped_lines[i])
        end

        -- Build buffer lines
        local indent = string.rep(' ', init_col_start)
        for i, line in ipairs(merged_lines) do
            local buffer_line, space
            space = is_whitespace_only(line) and '' or ' ' -- Ternary expr alternative
            if #merged_lines == 1 then -- If comment spans only 1 line
                buffer_line = indent .. com_symbol[1] .. space .. line .. space .. com_symbol[2]
            elseif i == 1 then -- If first line
                buffer_line = indent .. com_symbol[1] .. space .. line
            elseif i == #merged_lines then -- If last line
                buffer_line = indent .. line .. space .. com_symbol[2]
            else -- If any 'normal' line inside
                buffer_line = indent .. line
            end
            table.insert(buffer_lines, buffer_line)
        end
        -- Replace buffer lines
        local rstart, rend = init_row_start, init_row_end
        vim.api.nvim_buf_set_lines(bufnr, rstart, rend + 1, true, buffer_lines)
        vim.api.nvim_win_set_cursor(cur_win, { rstart + 1, cur_x })
    end
end

vim.keymap.set('n', '<leader>F', format_comment, { desc = '[F]ormat comment string' })
