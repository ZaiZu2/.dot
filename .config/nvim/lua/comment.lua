local utils = require 'utils'
local p = utils.pprint

local column_width = 80

--- Take in a string and split it into lines of maximum `line_width`.
--- Respects word boundaries, and split the string only on whitespaces.
--- @param comment string
--- @param line_width integer
--- @return table
local function wrap_string(comment, line_width)
  local wrapped_lines = {}

  --- @type integer|nil
  local com_split_end = 1
  --- @type integer|nil
  local com_split_start = 0

  local is_final_substr = false
  -- Iterate over `comment`, cutting chunks out of it and building lines out of it
  while not is_final_substr do
    comment = string.sub(comment, com_split_start + com_split_end, -1)
    -- print '------------------------------'
    -- p(comment, 'comment')
    -- Skip any whitespaces before the text
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
    -- vim.notify(
    --   'sub_start = '
    --     .. vim.inspect(line_start)
    --     .. ', sub_end = '
    --     .. vim.inspect(line_end)
    --     .. ', str_end = '
    --     .. vim.inspect(com_split_end)
    --     .. ', str_start  = '
    --     .. vim.inspect(com_split_start)
    -- )

    -- Substring a new line
    local substring = string.sub(comment, line_start, line_end)
    if not is_final_substr then
      -- Find if the new line is not splitting a word in a middle
      -- If it does, find the closest whitespace to the left
      com_split_end, _ = string.find(substring, '%s*%S*$')
      if com_split_end == nil then -- Text occupies a full line width
        com_split_end = line_width
      -- TODO: Line might consist of only whitespaces (?), this is not handled here
      else
        com_split_end = com_split_end - 1
      end
      substring = string.sub(substring, 1, com_split_end)
    end

    -- p(substring, 'substring')
    table.insert(wrapped_lines, substring)
  end
  -- p(wrapped_lines, 'new_comments')
  return wrapped_lines
end

local function run()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur_pos = vim.api.nvim_win_get_cursor(0)

  local tr = vim.treesitter
  tr.get_parser(bufnr):parse()

  local init_node = tr.get_node { bufnr = bufnr, pos = cur_pos }

  if init_node == nil or init_node:type() ~= 'comment' then
    vim.notify 'Not a comment'
    return
  end

  local cur_start, col_start, cur_end, _ = tr.get_node_range(init_node)
  local comment_nodes = { init_node }

  -- Find downward adjacent comments
  local next_node = init_node:next_named_sibling()
  while true do
    if next_node == nil then
      break
    end

    local next_start, _, next_end, _ = tr.get_node_range(next_node)
    if next_node:type() ~= 'comment' or next_start - cur_end > 1 then
      break
    end

    table.insert(comment_nodes, next_node)
    next_node = next_node:next_named_sibling()
    cur_end = next_end
  end

  -- Find upward adjacent comments
  local prev_node = init_node:prev_named_sibling()
  while true do
    if prev_node == nil then
      break
    end

    local prev_start, _, prev_end, _ = tr.get_node_range(prev_node)
    if prev_node:type() ~= 'comment' or cur_start - prev_end > 1 then
      break
    end

    table.insert(comment_nodes, 1, prev_node)
    prev_node = prev_node:prev_named_sibling()
    cur_start = prev_start
  end

  local comments = {}
  local com_char
  local com_prefix
  local dog
  for _, node in ipairs(comment_nodes) do
    local comment = tr.get_node_text(node, bufnr)
    -- Lua pattern matching does not support backreferences, hence split into 2 matches here
    -- Find what char is used as comment symbol
    com_char = string.match(comment, '^%s*.')
    -- Check if it's not repeated like lua's --- or js's //
    com_prefix, dog = string.match(comment, '^%s*(' .. com_char .. '*)')
    -- Cut comment symbol from the comment
    comment = string.gsub(comment, '^%s*' .. com_char .. '*%s*', '')
    -- Cut trailing whitespaces
    comment = string.gsub(comment, '%s*$', '')
    table.insert(comments, comment)
  end
  local com_string = table.concat(comments, ' ')
  print '-------------------------------------------------------------------------'
  -- p(com_char, 'com_char')
  -- p(com_prefix, 'com_prefix')
  -- p(dog, 'dog')
  -- p(com_string, 'com_string')

  -- Set comment length based on the current indentation
  local com_char_length = column_width - col_start - #(com_prefix .. ' ')
  local wrapped_lines = wrap_string(com_string, com_char_length)
  --
  local indent_string = string.rep(' ', col_start)
  local buffer_lines = {}
  for i, line in ipairs(wrapped_lines) do
    buffer_lines[i] = string.format('%s%s %s', indent_string, com_prefix, line)
  end

  local rstart, _, _, _ = tr.get_node_range(comment_nodes[1])
  local _, _, rend, _ = tr.get_node_range(comment_nodes[#comment_nodes])
  local diff = (rend - rstart + 1) - #buffer_lines

  if diff > 0 then
    for _ = 0, diff do
      table.insert(buffer_lines, '')
    end
  end
  p(buffer_lines)
  print('#lines = ' .. #buffer_lines .. ', diff = ' .. diff .. ', ' .. rstart .. ' ' .. rend)
  vim.api.nvim_buf_set_lines(bufnr, rstart, rend, true, buffer_lines)
end

vim.keymap.set('n', '<leader>F', run, { desc = '[F]ormat comment string' })
-- run()
