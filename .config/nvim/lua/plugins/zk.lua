return {
    {
        'zk-org/zk-nvim',
        event = 'VeryLazy',
        opts = {
            picker = 'fzf_lua',
            lsp = {
                -- `config` is passed to `vim.lsp.start_client(config)`
                config = {
                    cmd = { 'zk', 'lsp' },
                    name = 'zk',
                    -- on_attach = ...
                    -- etc, see `:h vim.lsp.start_client()`
                },
                -- automatically attach buffers in a zk notebook that match the given filetypes
                auto_attach = {
                    enabled = true,
                    filetypes = { 'markdown' },
                },
            },
        },
        config = function(_, opts)
            local ZK_PATH = vim.uv.os_getenv 'ZK_NOTEBOOK_DIR'
            if ZK_PATH == nil then
                error 'Could not find `ZK_NOTEBOOK_DIR` environment variable'
            end
            local zk = require 'zk'
            zk.setup(opts)

            local fzflua = require 'fzf-lua'

            ---Create a note after prompting user with 2 consecutive pickers - first
            ---asking for location of the note, second for what tags should be attached to
            ---the note
            local function create_new_note()
                local tags = {}
                local note_paths = {}
                local picked_path = nil

                -- Find all 'type' directories, while skipping hidden ones
                for dir_name, type_ in vim.fs.dir(ZK_PATH) do
                    if not vim.list_contains({ '.git', '.zk' }, dir_name) and type_ == 'directory' then
                        table.insert(note_paths, dir_name)
                    end
                end

                -- Recursively traverse found directories to find all nested directories
                for _, parent_path in ipairs(note_paths) do
                    local nested_paths = vim.fs.find(function(name, _)
                        return name:sub(1, 1) ~= '.'
                    end, {
                        path = vim.fs.joinpath(ZK_PATH, parent_path),
                        type = 'directory',
                        limit = math.huge,
                    })
                    local rel_nested_paths = vim.tbl_map(function(path)
                        return string.gsub(path, '^' .. ZK_PATH, ''):sub(2)
                    end, nested_paths)

                    vim.list_extend(note_paths, rel_nested_paths)
                end

                -- Feed it all found locations to the location picker.
                -- Set up main tag based on the 'type' directory
                local function pick_note_loc(paths, cb)
                    fzflua.fzf_exec(paths, {
                        winopts = {
                            height = 0.35,
                            width = 0.35,
                        },
                        actions = {
                            ['default'] = function(selected, _)
                                picked_path = selected[1]
                                local path_tag = string.match(picked_path, '^[^/]+')
                                table.insert(tags, path_tag)
                                vim.print(tags)
                                cb()
                            end,
                        },
                    })
                end

                -- Set up tag picker
                pick_note_loc(note_paths, function()
                    zk.pick_tags({}, { multi_select = true }, function(picked_tags)
                        -- Process selected tags into a string
                        vim.list_extend(
                            tags,
                            vim.tbl_map(function(tag)
                                return "'" .. tag.name .. "', "
                            end, picked_tags)
                        )
                        local tags_str = '[' .. table.concat(tags, ', ') .. ']'

                        -- Stringified tags are passed as `extra` variables and used in the
                        -- note template
                        -- https://github.com/zk-org/zk/blob/main/docs/notes/template-creation.md
                        require('zk.commands').get 'ZkNew' {
                            dir = picked_path,
                            extra = { tags = tags_str },
                        }
                    end)
                end)
            end

            vim.keymap.set('n', '<leader>zn', create_new_note, { desc = '[n]ew note with tags' })
            vim.keymap.set('n', '<leader>zb', '<Cmd>ZkBacklinks<CR>', { desc = 'Open [b]acklinks' })
            vim.keymap.set('n', '<leader>zd', function()
                zk.new { dir = ZK_PATH .. '/daily' }
            end, { desc = 'Open [d]aily note' })
            vim.keymap.set('n', '<leader>zo', "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", { desc = '[o]pen notes' })
            vim.keymap.set('n', '<leader>zt', '<Cmd>ZkTags<CR>', { desc = 'search through [t]ags' })
        end,
    },
}
