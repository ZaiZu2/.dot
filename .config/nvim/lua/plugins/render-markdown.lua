return {
    {
        'MeanderingProgrammer/render-markdown.nvim',
        event = 'VeryLazy',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
        opts = {
            render_modes = true,
            paragraph = {},
            code = {},
            checkbox = {
                enabled = false,
                unchecked = {
                    icon = '✗ ',
                    highlight = 'RenderMarkdownUnchecked',
                    scope_highlight = nil,
                },
                checked = {
                    icon = '✔ ',
                    highlight = 'RenderMarkdownChecked',
                    scope_highlight = nil,
                },
            },
            pipe_table = {
                cell = 'trimmed'
            },
            indent = {
                enabled = true,
                per_level = 2,
                skip_level = 1,
            }
        },
    },
}
