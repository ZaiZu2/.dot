return {
    {
        'MeanderingProgrammer/render-markdown.nvim',
        event = 'VeryLazy',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
        opts = {
            file_types = { 'markdown', 'vimwiki', 'copilot-chat' },
            completions = { blink = { enabled = true } },
            render_modes = { 'n', 'i' },
            paragraph = {},
            anti_conceal = {
                disabled_modes = { 'n' },
                -- ignore = {
                --     code_background = false,
                --     indent = true,
                --     sign = false,
                --     virtual_lines = false,
                -- },
            },
            code = { conceal_delimiters = false },
            checkbox = {
                enabled = false,
                unchecked = {
                    icon = '[ ]',
                    highlight = 'RenderMarkdownUnchecked',
                    scope_highlight = nil,
                },
                checked = {
                    icon = '[x]',
                    highlight = 'RenderMarkdownChecked',
                    scope_highlight = nil,
                },
            },
            pipe_table = {
                cell = 'trimmed',
            },
            indent = {
                enabled = true,
                per_level = 3,
                skip_level = 0,
                skip_heading = true,
                icon = ' ',
            },
        },
    },
}
