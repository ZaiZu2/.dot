-- TODO: Make column_width injectable/derivable from formatter settings (?)
-- TODO: Add support for justification to TODO markers
-- TODO: Recognize strings comments and allow for their formatting (python)
-- TODO: Recognize multiline comments and allow their formatting
local utils = require 'utils'
local p = utils.pprint

local tr = vim.treesitter
local column_width = 80

---Traverse TS tree upwards in search of a closest parent node of the provided type
---@param initial_node TSNode|nil
---@param type string
---@return TSNode|nil
local function find_node(initial_node, type)
  local node = initial_node
  while node ~= nil do
    if node:type() == type then return node end
    node = node:parent()
  end
  return nil -- Didn't find a comment node
end

---Find all row-adjacent nodes of the same type which create a block
---@param initial_node TSNode
---@return TSNode[]
local function find_adjacent_nodes(initial_node)
  local initial_type = initial_node:type()
  local cur_start, _, cur_end, _ = tr.get_node_range(initial_node)
  local found_nodes = { initial_node }

  local node = initial_node
  -- Find downward row-adjacent comments
  local next_node = node:next_named_sibling()
  while true do
    if next_node == nil then
      break
    end

    local next_start, _, next_end, _ = tr.get_node_range(next_node)
    if next_node:type() ~= initial_type or next_start - cur_end > 1 then
      break
    end

    table.insert(found_nodes, next_node)
    next_node = next_node:next_named_sibling()
    cur_end = next_end
  end

  -- Find upward row-adjacent comments
  local prev_node = node:prev_named_sibling()
  while true do
    if prev_node == nil then
      break
    end

    local prev_start, _, prev_end, _ = tr.get_node_range(prev_node)
    if prev_node:type() ~= initial_type or cur_start - prev_end > 1 then
      break
    end

    table.insert(found_nodes, 1, prev_node)
    prev_node = prev_node:prev_named_sibling()
    cur_start = prev_start
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

    table.insert(wrapped_lines, substring)
  end
  return wrapped_lines
end

local function format_comment()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur_win = vim.api.nvim_get_current_win()

  local cur_pos = vim.api.nvim_win_get_cursor(0)
  local cur_x, cur_y = table.unpack(cur_pos)
  cur_x, cur_y = cur_x -1, cur_y -- Switch from (1,0) to (0,0) indexing

  -- Extract the node pointed with the cursor and find the comment
  tr.get_parser(bufnr):parse()
  local init_node = tr.get_node { bufnr = bufnr, pos = {cur_x, cur_y} }
  init_node = find_node(init_node, 'comment')
  if init_node == nil then
    vim.notify('Did not find a comment node.')
    return
  end

  -- Find all row-adjacent comment nodes
  local comment_nodes = find_adjacent_nodes(init_node)

  -- Extract node texts
  local raw_lines = {}
  for _, node in ipairs(comment_nodes) do
    local line = tr.get_node_text(node, bufnr)
    table.insert(raw_lines, line)
  end

  -- Extract comment symbol and concatenate comments into single string
  local com_prefix, com_string = concatenate_comment(raw_lines)

  -- Set comment length based on the current indentation
  local _, col_start, _, _ = tr.get_node_range(init_node)
  local string_length = column_width - col_start - #(com_prefix .. ' ')
  local wrapped_lines = wrap_string(com_string, string_length)

  local indent = string.rep(' ', col_start)
  local buffer_lines = {}
  for i, line in ipairs(wrapped_lines) do
    buffer_lines[i] = indent .. com_prefix .. ' ' .. line
  end

  -- Replace buffer lines
  local rstart, _, _, _ = tr.get_node_range(comment_nodes[1])
  local _, _, rend, _ = tr.get_node_range(comment_nodes[#comment_nodes])
  vim.api.nvim_buf_set_lines(bufnr, rstart, rend + 1, true, buffer_lines)
  vim.api.nvim_win_set_cursor(cur_win, {rstart + 1, cur_y})
end

return format_comment
