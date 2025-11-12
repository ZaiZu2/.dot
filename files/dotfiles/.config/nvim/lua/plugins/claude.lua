return {
    {
        'coder/claudecode.nvim',
        dependencies = { 'folke/snacks.nvim' },
        opts = {
            terminal = {
                provider = 'external',
                provider_opts = {
                    external_terminal_cmd = function(cmd, env)
                        return { 'bash', vim.env.XDG_CONFIG_HOME .. '/tmux/focus_claude_pane.sh' }
                    end,
                },
            },
            focus_after_send = true,
        },
        keys = {
            { '<leader>c', nil, desc = '[c]laude code' },
            { '<leader>cc', '<cmd>ClaudeCode<cr>', desc = 'Toggle [c]laude' },
            -- Add context
            { '<leader>ca', '<cmd>ClaudeCodeAdd %<cr>', desc = '[a]dd current buffer' },
            { '<leader>ca', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = '[a]dd selection' },
            {
                '<leader>ca',
                '<cmd>ClaudeCodeTreeAdd<cr>',
                desc = '[a]dd file',
                ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw' },
            },
            -- Diff management
            { '<leader>cda', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
            { '<leader>cdd', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },

            { '<leader>cm', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select [m]odel' },
        },
    },
}
