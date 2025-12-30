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
            'williamboman/mason-lspconfig.nvim', -- Provides mapping of lspconfig (LSP) names to Mason names
            'jay-babu/mason-nvim-dap.nvim', -- Provides mapping of nvim-dap (DAP) names to Mason names
            'WhoIsSethDaniel/mason-tool-installer.nvim', -- Automatic installation of LSPs/formatters/linters/DAPs
            'j-hui/fidget.nvim',
        },
        config = function()
            -- Recognize LSP config files and enable corresponding LSPs
            local lsp_path = vim.fn.stdpath 'config' .. '/lsp'
            -- package.path = package.path .. lsp_path .. '/?.lua;'
            local lsps = {} ---@type string[]
            for file_name in vim.fs.dir(lsp_path, {}) do
                local lsp_name = vim.fs.basename(file_name):match '^(.+)%.lua$'
                if lsp_name then
                    local lsp_conf = require(lsp_name)
                    -- Ignore commented-out LSP files (empty modules)
                    if lsp_conf ~= true then
                        table.insert(lsps, lsp_name)
                    end
                end
            end
            vim.lsp.enable(lsps)

            local config = require 'config'
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
            for _, ft_fmts in pairs(config.linters.ft) do
                for _, fmt in ipairs(ft_fmts) do
                    if not vim.list_contains(formatters, fmt) then
                        table.insert(formatters, fmt)
                    end
                end
            end
            -- Parse all used DAPs from the config
            local daps = vim.tbl_map(function(debugger)
                return debugger.name
            end, config.daps)

            local tools = {}
            vim.list_extend(tools, linters)
            vim.list_extend(tools, formatters)
            vim.list_extend(tools, daps)
            vim.list_extend(tools, lsps)

            require('mason').setup {
                -- ui = { border = 'rounded' }
            }
            require('mason-tool-installer').setup { ensure_installed = tools }
        end,
    },
}
