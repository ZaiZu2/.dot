local utils = require 'utils'
local p = utils.pprint

local column_width = 80

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
  p(com_char, 'com_char')
  p(com_prefix, 'com_prefix')
  p(dog, 'dog')
  p(com_string, 'com_string')

  local sub_start = 1
  local sub_end

  -- Set comment length based on the current indentation
  local com_char_length = column_width - col_start - #(com_prefix .. ' ')
  if com_char_length > #com_string then
    sub_end = #com_string
  else
    sub_end = com_char_length
  end

  local new_comments = {}
  --- @type integer|nil
  local last_whitespace_pos = 0
  --- @type integer|nil
  local first_char_pos = sub_start
  local whitespaces = ''
  while true do
    --  Create a substring
    sub_start = sub_start + last_whitespace_pos + #whitespaces - 1
    if sub_start + com_char_length > #com_string then
      sub_end = #com_string
    else
      sub_end = sub_start + com_char_length
    end
    local substring = string.sub(com_string, sub_start, sub_end)
    print '\n'
    p(substring, 'substring')

    -- Skip matching whitespaces and break out of the loop for the final substring
    if sub_end == #com_string then
      table.insert(new_comments, substring)
      break
    end

    -- Find the final whitespace in the substring
    last_whitespace_pos, _, whitespaces = string.find(substring, '(%s*)%S*$')
    if whitespaces == nil then
      last_whitespace_pos = com_char_length
      whitespaces = ''
    end
    _, first_char_pos, _ = string.find(substring, '^%s*(%S)')
    assert(first_char_pos) -- FIXME: Not true, comment might be whitespace only string

    p(sub_start, 'sub_start')
    p(sub_end, 'sub_end')
    p(whitespaces, 'whitespaces')
    p(first_char_pos, 'first_char_pos')
    p(last_whitespace_pos, 'last_whitespace_pos')

    -- Adjust substring to remove whitespaces and ensure split between words
    local new_comment = string.sub(substring, first_char_pos, last_whitespace_pos - 1)
    p(new_comment, 'new_comment')
    table.insert(new_comments, new_comment)
  end
  p(new_comments, 'new_comments')

  --
  local indent_string = string.rep(' ', col_start)
  for i, comment in ipairs(new_comments) do
    new_comments[i] = string.format('%s%s %s', indent_string, com_prefix, comment)
  end
  p(new_comments)

  local rstart, _, _, _ = tr.get_node_range(comment_nodes[1])
  local _, _, rend, _ = tr.get_node_range(comment_nodes[#comment_nodes])
  p(rstart, 'rstart')
  p(rend, 'rend')
  vim.api.nvim_buf_set_lines(bufnr, rstart, rend, true, new_comments)
end

vim.keymap.set('n', '<leader>F', run, { desc = '[F]ormat comment string' })
-- run()
