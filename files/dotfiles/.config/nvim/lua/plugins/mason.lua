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
            'neovim/nvim-lspconfig',
            'mason-org/mason-lspconfig.nvim',
            'jay-babu/mason-nvim-dap.nvim', -- Provides mapping of nvim-dap (DAP) names to Mason names
            'WhoIsSethDaniel/mason-tool-installer.nvim', -- Automatic installation of LSPs/formatters/linters/DAPs
            'j-hui/fidget.nvim',
        },
        config = function()
            local config = require 'config'

            -- Parse all used formatters from the config
            -- Apply per-server overrides on top of nvim-lspconfig defaults
            local lsp_names = {}
            for name, override in pairs(config.lsps) do
                table.insert(lsp_names, name)
                if not vim.tbl_isempty(override) then
                    vim.lsp.config(name, override)
                end
            end

            require('mason').setup {}
            require('mason-lspconfig').setup {
                ensure_installed = lsp_names,
                automatic_enable = lsp_names,
            }

            -- Parse all used linters from the config
            local linters = {}
            for _, ft_linters in pairs(config.linters.ft) do
                for _, linter in ipairs(ft_linters) do
                    if not vim.list_contains(linters, linter) then
                        table.insert(linters, linter)
                    end
                end
            end
            -- Parse all used formatters from the config
            local formatters = {}
            for _, ft_fmts in pairs(config.formatters.ft) do
                for _, fmt in ipairs(ft_fmts) do
                    if not vim.list_contains(formatters, fmt) then
                        table.insert(formatters, fmt)
                    end
                end
            end
            -- Parse all used DAPs from the config
            local daps = vim.tbl_map(function(debugger) return debugger.name end, config.daps)

            local tools = {}
            vim.list_extend(tools, linters)
            vim.list_extend(tools, formatters)
            vim.list_extend(tools, daps)
            require('mason-tool-installer').setup { ensure_installed = tools }
        end,
    },
}
