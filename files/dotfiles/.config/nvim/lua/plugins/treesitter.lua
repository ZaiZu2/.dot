return {
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
        config = function()
            require('nvim-treesitter').install {
                'bash',
                'c',
                'diff',
                'html',
                'lua',
                'luadoc',
                'markdown',
                'vim',
                'vimdoc',
                'python',
                'javascript',
                'typescript',
                'tsx',
            }

            vim.keymap.set(
                { 'x' },
                '[n',
                function() require('vim.treesitter._select').select_prev(vim.v.count1) end,
                { desc = 'Select previous treesitter node' }
            )
            vim.keymap.set(
                { 'x' },
                ']n',
                function() require('vim.treesitter._select').select_next(vim.v.count1) end,
                { desc = 'Select next treesitter node' }
            )
            vim.keymap.set({ 'x', 'o' }, 'an', function()
                if vim.treesitter.get_parser(nil, nil, { error = false }) then
                    require('vim.treesitter._select').select_parent(vim.v.count1)
                else
                    vim.lsp.buf.selection_range(vim.v.count1)
                end
            end, { desc = 'Select parent treesitter node or outer incremental lsp selections' })
            vim.keymap.set({ 'x', 'o' }, 'in', function()
                if vim.treesitter.get_parser(nil, nil, { error = false }) then
                    require('vim.treesitter._select').select_child(vim.v.count1)
                else
                    vim.lsp.buf.selection_range(-vim.v.count1)
                end
            end, { desc = 'Select child treesitter node or inner incremental lsp selections' })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        config = function()
            require('nvim-treesitter-textobjects').setup {
                select = {
                    lookahead = true,
                },
            }

            local text_obj_map = {
                ['af'] = { '@function.outer', '[f]unction' },
                ['if'] = { '@function.inner', '[f]unction' },
                ['ac'] = { '@class.outer', '[c]lass' },
                ['ic'] = { '@class.inner', '[c]lass' },
                ['aB'] = { '@block.outer', '[B]lock' },
                ['iB'] = { '@block.inner', '[B]lock' },
                ['iC'] = { '@call.inner', 'function [C]all' },
                ['aC'] = { '@call.outer', 'function [C]all' },
                ['iP'] = { '@parameter.inner', '[P]arameter' },
                ['aP'] = { '@parameter.outer', '[P]arameter' },
                ['ia'] = { '@assignment.rhs', 'RHS [a]ssignment' },
                ['aa'] = { '@assignment.lhs', 'LHS [a]ssignment' },
                ['iA'] = { '@attribute.inner', '[A]ttribute' },
                ['aA'] = { '@attribute.outer', '[A]ttribute' },
                ['as'] = { '@statement.outer', '[s]tatement' },
            }
            for key, val in pairs(text_obj_map) do
                vim.keymap.set(
                    { 'x', 'o' },
                    key,
                    function() require('nvim-treesitter-textobjects.select').select_textobject(val[1], 'textobjects') end,
                    { desc = val[2] }
                )
            end
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-context',
        opts = {
            enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
            max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
            min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
            line_numbers = true,
            multiline_threshold = 10, -- Maximum number of lines to show for a single context
            trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
            mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
            separator = nil,
            zindex = 20,
            on_attach = nil,
        },
    },
}
