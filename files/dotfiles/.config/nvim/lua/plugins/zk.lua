return {
    {
        'zk-org/zk-nvim',
        event = 'VeryLazy',
        opts = {
            picker = 'snacks_picker',
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
            local ZK_ABSA_DIR = vim.uv.os_getenv 'ZK_ABSA_DIR'
            local ZK_NOTEBOOK_DIR = vim.uv.os_getenv 'ZK_NOTEBOOK_DIR'
            if ZK_NOTEBOOK_DIR == nil then
                error 'Could not find `ZK_NOTEBOOK_DIR` environment variable'
            end

            local zk = require 'zk'
            zk.setup(opts)

            local snacks = require 'snacks'

            ---Create a note after prompting user with 2 consecutive pickers - first
            ---asking for location of the note, second for what tags should be attached to
            ---the note
            local function create_new_note()
                local path_tag = {}
                local note_paths = {}
                local picked_path = nil

                -- Find all 'type' directories, while skipping hidden ones
                for dir_name, type_ in vim.fs.dir(ZK_NOTEBOOK_DIR) do
                    if not vim.list_contains({ '.git', '.zk' }, dir_name) and type_ == 'directory' then
                        table.insert(note_paths, dir_name)
                    end
                end

                -- Recursively traverse found 'type' directories to find all nested directories
                local all_paths = vim.list_extend({}, note_paths)
                for _, parent_path in ipairs(note_paths) do
                    local nested_paths = vim.fs.find(function(name, _) return name:sub(1, 1) ~= '.' end, {
                        path = vim.fs.joinpath(ZK_NOTEBOOK_DIR, parent_path),
                        type = 'directory',
                        limit = math.huge,
                    })
                    local rel_nested_paths = vim.tbl_map(
                        function(path) return string.gsub(path, '^' .. ZK_NOTEBOOK_DIR, ''):sub(2) end,
                        nested_paths
                    )

                    vim.list_extend(all_paths, rel_nested_paths)
                end

                local function pick_note_loc(paths, cb)
                    snacks.picker.select(paths, {
                        prompt = 'Note location> ',
                        layout = {
                            preset = 'dropdown',
                            layout = { height = 0.35, width = 0.35 },
                        },
                    }, function(item, _)
                        picked_path = item
                        path_tag = string.match(item, '^[^/]+')
                        cb()
                    end)
                end

                -- Set up tag picker
                pick_note_loc(all_paths, function()
                    zk.pick_tags({}, { multi_select = true }, function(picked_tags)
                        -- Process selected tags into a string
                        local tags_str =
                            table.concat(vim.tbl_map(function(tag) return "'" .. tag.name .. "', " end, picked_tags))
                        tags_str = "'" .. path_tag .. "', " .. tags_str
                        tags_str = '[' .. tags_str .. ']'

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
            vim.keymap.set(
                'n',
                '<leader>zl',
                function()
                    require('zk.commands').get 'ZkNew' {
                        dir = ZK_NOTEBOOK_DIR .. 'dsa/leetcode',
                        template = 'leetcode.md',
                    }
                end,
                { desc = '[n]ew leetcode note' }
            )
            vim.keymap.set(
                'n',
                '<leader>zd',
                function() zk.new { dir = 'daily', template = 'daily.md' } end,
                { desc = 'Open [d]aily note' }
            )

            vim.keymap.set(
                'n',
                '<leader>zad',
                function() zk.new { notebook_path = ZK_ABSA_DIR, dir = ZK_ABSA_DIR .. 'daily', template = 'daily.md' } end,
                { desc = 'Open absa [d]aily note' }
            )
            vim.keymap.set(
                'n',
                '<leader>zan',
                function() zk.new { notebook_path = ZK_ABSA_DIR, extra = { tags = "['absa', ]" } } end,
                { desc = '[n]ew absa note' }
            )
            vim.keymap.set(
                'n',
                '<leader>zao',
                function() zk.edit { notebook_path = ZK_ABSA_DIR } end,
                { desc = '[o]pen absa note' }
            )

            vim.keymap.set('n', '<leader>zb', '<Cmd>ZkBacklinks<CR>', { desc = 'Open [b]acklinks' })
            vim.keymap.set('n', '<leader>zo', "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", { desc = '[o]pen notes' })
            vim.keymap.set('n', '<leader>zt', '<Cmd>ZkTags<CR>', { desc = 'search through [t]ags' })
        end,
    },
}
