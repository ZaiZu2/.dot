return {
    {
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
            },
        },
    },
    { -- LSP Configuration & Plugins
        'williamboman/mason.nvim',
        dependencies = {
            { 'WhoIsSethDaniel/mason-tool-installer.nvim' }, -- Automatic installation of formatters/linters/DAPs
            { 'j-hui/fidget.nvim' },
        },
        config = function()
            -- Specify all language tools to be installed automatically
            local linters = { 'shellcheck', 'hadolint', 'markdownlint-cli2' }
            local formatters = { 'stylua', 'shfmt', 'markdownlint-cli2', 'prettier' }
            local daps = { 'debugpy' }
            local tools = {}
            vim.list_extend(tools, linters)
            vim.list_extend(tools, formatters)
            vim.list_extend(tools, daps)

            require('mason').setup {
                -- ui = { border = 'rounded' }
            }
            require('mason-tool-installer').setup { ensure_installed = tools }
        end,
    },
}
