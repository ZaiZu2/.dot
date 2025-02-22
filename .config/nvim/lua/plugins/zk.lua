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
            local ZK_PATH = vim.loop.os_getenv 'ZK_NOTEBOOK_DIR'
            local zk = require 'zk'
            zk.setup(opts)

            local fzflua = require 'fzf-lua'
            local function pick_new_note()
                fzflua.fzf_exec({ 'daily', 'knowledge', 'absa', 'dsa' }, {
                    winopts = {
                        height = 0.35,
                        width = 0.35,
                    },
                    actions = {
                        ['default'] = function(selected, _)
                            require('zk').new { dir = selected[1], edit = true }
                        end,
                    },
                })
            end
            vim.keymap.set('n', '<leader>zn', pick_new_note, { desc = '[n]ew note' })
            vim.keymap.set('n', '<leader>zb', '<Cmd>ZkBacklinks<CR>', { desc = 'Open [b]acklinks' })
            vim.keymap.set('n', '<leader>zd', function()
                zk.new { dir = ZK_PATH .. '/daily' }
            end, { desc = 'Open [d]aily note' })
            vim.keymap.set('n', '<leader>zo', "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", { desc = '[o]pen notes' })
            vim.keymap.set('n', '<leader>zt', '<Cmd>ZkTags<CR>', { desc = 'search through [t]ags' })
        end,
    },
}
