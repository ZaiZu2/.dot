return {
    {
        'coder/claudecode.nvim',
        dependencies = { 'folke/snacks.nvim' },
        config = function()
            require('claudecode').setup {
                terminal = {
                    provider = 'external',
                    provider_opts = {
                        external_terminal_cmd = function(cmd, env)
                            return { 'sh', vim.env.XDG_CONFIG_HOME .. '/tmux/focus_claude_pane.sh' }
                        end,
                    },
                },
                focus_after_send = true,
            }

            -- Keymaps
            -- vim.keymap.set({ 'n', 'v' }, '<leader>cc', '<cmd>ClaudeCode<cr>gv', { desc = 'Toggle [c]laude' })
            vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<cr>', { desc = 'Toggle [c]laude' })
            -- Reselect after trigger `ClaudeCode` command
            vim.keymap.set('v', '<leader>cc', '<cmd>ClaudeCode<cr>gv', { desc = 'Toggle [c]laude' })

            -- Add context
            vim.keymap.set('n', '<leader>ca', '<cmd>ClaudeCodeAdd %<cr>', { desc = '[a]dd current buffer' })
            vim.keymap.set('v', '<leader>ca', '<cmd>ClaudeCodeSend<cr>', { desc = '[a]dd selection' })

            -- Add file from file explorer (using autocmd for filetype-specific mapping)
            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw' },
                callback = function()
                    vim.keymap.set(
                        'n',
                        '<leader>ca',
                        '<cmd>ClaudeCodeTreeAdd<cr>',
                        { desc = '[a]dd file', buffer = true }
                    )
                end,
            })

            -- Diff management
            vim.keymap.set('n', '<leader>cy', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = 'Accept diff' })
            vim.keymap.set('n', '<leader>cn', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = 'Deny diff' })

            vim.keymap.set('n', '<leader>cm', '<cmd>ClaudeCodeSelectModel<cr>', { desc = 'Select [m]odel' })
        end,
    },
}
