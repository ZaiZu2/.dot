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
        'neovim/nvim-lspconfig',
        dependencies = {
            { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
            { 'williamboman/mason-lspconfig.nvim' },
            { 'WhoIsSethDaniel/mason-tool-installer.nvim' }, -- Automatic installation of formatters/linters/DAPs
            { 'j-hui/fidget.nvim' }, -- Useful status updates for LSP.
            { 'saghen/blink.cmp' },
        },
        config = function()
            -- Specify all language tools to be installed automatically
            local linters = { 'shellcheck', 'hadolint' }
            local formatters = { 'stylua', 'shfmt', 'markdownlint-cli2', 'prettier'}
            local daps = { 'debugpy' }
            local lsp_servers = { -- :help lspconfig-all
                -- ts_ls = {},
                -- jedi_language_server = {},
                -- basedpyright = {
                --     -- settings = {
                --     --     basedpyright = {
                --     --         disableOrganizeImports = true, -- Using Ruff
                --     --         disableTaggedHints = false,
                --     --         analysis = {
                --     --             diagnosticSeverityOverrides = {
                --     --                 -- https://github.com/microsoft/pyright/blob/main/docs/configuration.md#type-check-diagnostics-settings
                --     --                 reportUndefinedVariable = 'none',
                --     --             },
                --     --             typeCheckingMode = 'standard',
                --     --             autoImportCompletions = true,
                --     --             -- autoSearchPaths = true,
                --     --             diagnosticMode = 'openFilesOnly',
                --     --             useLibraryCodeForTypes = false,
                --     --             -- inlayHints = {
                --     --             --     variableTypes = true,
                --     --             --     callArgumentNames = true,
                --     --             --
                --     --             -- }
                --     --         },
                --     --     },
                --     -- },
                -- },
                -- ruff = {
                --     init_options = {
                --         settings = {
                --             args = { 'server' },
                --         },
                --     },
                -- },
                -- lua_ls = {
                --     settings = {
                --         Lua = {
                --             runtime = { version = 'LuaJIT' },
                --             diagnostics = {
                --                 globals = { 'vim' },
                --             },
                --             completion = {
                --                 callSnippet = 'Replace',
                --             },
                --             -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                --             -- diagnostics = { disable = { 'missing-fields' } },
                --         },
                --     },
                -- },
                -- bashls = {
                --     filetypes = { 'bash', 'sh', 'zsh' },
                -- },
                -- dockerls = {},
                docker_compose_language_service = {},
                -- taplo = {}, -- toml
            }
            local tools = {}
            vim.list_extend(tools, linters)
            vim.list_extend(tools, formatters)
            vim.list_extend(tools, daps)
            vim.list_extend(tools, vim.tbl_keys(lsp_servers))

            -- :Mason
            require('mason').setup {
                ui = {
                    border = 'rounded',
                },
            }
            -- `mason-lspconfig` only allows to install LSPs - `mason-tool-installer` can install all tools
            require('mason-tool-installer').setup { ensure_installed = tools }

            -- Setup baseline configs for all used LSPs
            require('mason-lspconfig').setup()
            for lsp_name, lsp_conf in pairs(lsp_servers) do
                lsp_conf.capabilities = require('blink.cmp').get_lsp_capabilities(lsp_conf.capabilities)
                require('lspconfig')[lsp_name].setup(lsp_conf)
            end

            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set('n', keys, func, { buffer = event.buf, desc = desc })
                    end

                    map(';D', vim.lsp.buf.declaration, '[D]eclaration')
                    map(';R', vim.lsp.buf.rename, '[R]ename')
                    map('K', vim.lsp.buf.hover, 'Show documentation') -- :help K
                    vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'Show signature' })

                    local fzflua = require 'fzf-lua'
                    map(';c', fzflua.lsp_code_actions, '[c]ode action')
                    map(';d', fzflua.lsp_definitions, '[d]efinition')
                    map(';r', fzflua.lsp_references, '[r]eferences')
                    map(';i', fzflua.lsp_implementations, '[i]mplementation')
                    map(';t', fzflua.lsp_typedefs, '[t]ype definition')
                    map(';s', fzflua.lsp_document_symbols, '[s]ymbols')
                    map(';p', fzflua.lsp_workspace_symbols, 'symbols in [p]roject')

                    -- The following two autocommands are used to highlight references of the word
                    -- :help CursorHold
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client.server_capabilities.documentHighlightProvider then
                        local highlight_augroup =
                            vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
                        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        })

                        vim.api.nvim_create_autocmd('LspDetach', {
                            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
                            callback = function(event2)
                                vim.lsp.buf.clear_references()
                                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
                            end,
                        })
                    end

                    -- The following autocommand is used to enable inlay hints in your
                    -- code, if the language server you are using supports them
                    if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
                        map('<leader>th', function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
                        end, '[t]oggle Inlay [h]ints')
                    end
                end,
            })
        end,
    },
}
