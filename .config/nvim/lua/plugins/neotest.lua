return {
    {
        'nvim-neotest/neotest',
        event = 'VeryLazy',
        dependencies = {
            'nvim-neotest/neotest-python',
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            local neo_python_conf = {
                dap = { justMyCode = false },
            }
            local neotest = require 'neotest'
            neotest.setup {
                adapters = {
                    require 'neotest-python'(neo_python_conf),
                },
            }

            vim.keymap.set('n', ',tt', neotest.run.run, { desc = '[t]est case run' })
            vim.keymap.set('n', ',tT', function()
                neotest.run { suite = true }
            end, { desc = '[T]est suite run' })
            vim.keymap.set('n', ',ts', neotest.run.stop, { desc = '[t]est case [s]top' })
            vim.keymap.set('n', ',tS', function()
                neotest.run.stop { suite = true }
            end, { desc = '[t]est suite [S]top' })
            vim.keymap.set('n', ',td', function()
                neotest.run.run { strategy = 'dap', suite = false }
            end, { desc = '[t]est case [d]ebug' })

            vim.keymap.set('n', ',o', function()
                neotest.output.open { enter = true }
            end, { desc = 'toggle [o]utput' })
            vim.keymap.set('n', ',O', function()
                neotest.output_panel.toggle()
            end, { desc = 'toggle [O]utput panel' })
            vim.keymap.set('n', ',T', function()
                neotest.summary.toggle()
            end, { desc = 'open test [T]ree' })
        end,
    },
}
