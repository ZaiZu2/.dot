return {
    {
        'echasnovski/mini.nvim',
        opts = {},
        config = function()
            require('mini.ai').setup { n_lines = 500 }

            vim.keymap.set({ 'n', 'x' }, 's', '<Nop>') -- Unbind default vim `s`
            require('mini.surround').setup()

            require('mini.operators').setup {
                exchange = {
                    prefix = 'ge',
                    reindent_linewise = true, -- Whether to reindent new text to match previous indent
                },
                evaluate = { prefix = '', func = nil },
            }

            require('mini.trailspace').setup()

            require('mini.test').setup()

            require('mini.splitjoin').setup()

            local hipatterns = require 'mini.hipatterns'
            hipatterns.setup {
                highlighters = {
                    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
                    hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
                    todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
                    note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
                    hex_color = hipatterns.gen_highlighter.hex_color(),
                },
            }

            local miniIcons = require 'mini.icons'
            miniIcons.setup()
            miniIcons.mock_nvim_web_devicons()

            -- require('mini.completion').setup()

            local statusline = require 'mini.statusline'
            statusline.setup { use_icons = vim.g.have_nerd_font }

            ---@diagnostic disable-next-line: duplicate-set-field
            statusline.section_location = function()
                return '%2l:%-2v'
            end
        end,
    },
}
