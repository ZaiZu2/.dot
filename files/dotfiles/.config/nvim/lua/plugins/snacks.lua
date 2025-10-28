return {
    {
        'folke/snacks.nvim',
        ---@type snacks.Config
        opts = {
            image = { enabled = true },
            scroll = {
                animate = {
                    duration = { step = 5, total = 100 },
                    easing = 'linear',
                },
            },
            picker = {
                ui_select = true,
                win = {
                    input = {
                        keys = {
                            ['<C-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
                            ['<C-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
                            ['<C-b>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
                            ['<C-f>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
                        },
                    },
                    list = {
                        ['<C-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
                        ['<C-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
                        ['<C-b>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
                        ['<C-f>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
                    },
                },
                formatters = {
                    file = { filename_first = true, truncate = 80 },
                },
            },
        },
        keys = {
            {
                '<leader>sf',
                function() require('snacks').picker.files { hidden = true, follow = true } end,
                desc = '[s]earch [f]iles',
            },
            {
                '<leader>ss',
                function() require('snacks').picker.smart { hidden = true, follow = true } end,
                desc = '[s]earch [s]mart',
            },
            { '<leader>sg', function() require('snacks').picker.grep() end, desc = '[s]earch by [g]rep' },
            {
                '<leader>sw',
                function() require('snacks').picker.grep_word() end,
                mode = { 'n', 'x' },
                desc = '[s]earch current [w]ord',
            },
            { '<leader>sh', function() require('snacks').picker.help() end, desc = '[s]earch [h]elp' },
            { '<leader>sk', function() require('snacks').picker.keymaps() end, desc = '[s]earch [k]eymaps' },
            { '<leader>sd', function() require('snacks').picker.diagnostics() end, desc = '[s]earch [d]iagnostics' },
            { '<leader>sp', function() require('snacks').picker.resume() end, desc = '[s]earch [p]revious' },
            { '<leader>so', function() require('snacks').picker.recent() end, desc = '[s]earch recent files' },
            { '<leader><leader>', function() require('snacks').picker.buffers() end, desc = 'Search existing buffers' },
            {
                '<leader>s/',
                function() require('snacks').picker.lines() end,
                desc = '[/] Fuzzily search in current buffer',
            },
            {
                '<leader>sn',
                function()
                    require('snacks').picker.files { cwd = vim.fn.stdpath 'config', hidden = true, follow = true }
                end,
                desc = '[s]earch [n]eovim files',
            },
            {
                '<leader>sc',
                function()
                    require('snacks').picker.files { cwd = os.getenv 'XDG_CONFIG_HOME', hidden = true, follow = true }
                end,
                desc = '[s]earch [c]onfig files',
            },
            { '<leader>su', function() Snacks.picker.undo() end, desc = '[s]earch [u]ndo history' },
            { ';c', function() vim.lsp.buf.code_action() end, desc = '[c]ode action' },
            { ';d', function() require('snacks').picker.lsp_definitions() end, desc = '[d]efinition' },
            { ';r', function() require('snacks').picker.lsp_references() end, desc = '[r]eferences' },
            { ';i', function() require('snacks').picker.lsp_implementations() end, desc = '[i]mplementation' },
            { ';t', function() require('snacks').picker.lsp_type_definitions() end, desc = '[t]ype definition' },
            { ';s', function() require('snacks').picker.lsp_symbols() end, desc = '[s]ymbols' },
            { ';p', function() require('snacks').picker.lsp_workspace_symbols() end, desc = 'symbols in [p]roject' },
            { '<leader>s?', function() require('snacks').picker.pickers() end, desc = '[s]earch pickers' },
        },
    },
}
