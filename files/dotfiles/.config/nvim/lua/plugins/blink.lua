return {
    {
        'saghen/blink.cmp',
        dependencies = 'rafamadriz/friendly-snippets',
        version = '*',
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            -- 'default' for mappings similar to built-in completion
            -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
            -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
            -- See the full "keymap" documentation for information on defining your own keymap.
            keymap = {
                preset = 'default',
                -- ['M-u'] = { 'scroll_documentation_up' },
                -- ['M-d'] = { 'scroll_documentation_down' },
            },
            completion = {
                menu = {
                    draw = {
                        columns = { { 'label', 'label_description' }, { 'kind' } },
                        treesitter = { 'lsp' },
                    },
                    -- border = 'single',
                },
                documentation = {
                    auto_show = true,
                    -- window = { border = 'single' },
                },
            },
            signature = {
                enabled = true,
                window = {
                    show_documentation = true,
                    -- border = 'single',
                },
            },
            appearance = {
                -- Sets the fallback highlight groups to nvim-cmp's highlight groups
                -- Useful for when your theme doesn't support blink.cmp
                -- Will be removed in a future release
                -- use_nvim_cmp_as_default = true,
                nerd_font_variant = 'mono',
            },

            -- Default list of enabled providers defined so that you can extend it
            -- elsewhere in your config, without redefining it, due to `opts_extend`
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer', 'markdown' },
                providers = {
                    markdown = {
                        name = 'RenderMarkdown',
                        module = 'render-markdown.integ.blink',
                        fallbacks = { 'lsp' },
                    },
                },
            },
        },
        opts_extend = { 'sources.default' },
    },
}
