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
            local formatters = { 'stylua', 'shfmt', 'markdownlint-cli2' }
            local daps = { 'debugpy' }
            local lsp_servers = { -- :help lspconfig-all
                -- ts_ls = {},
                basedpyright = {
                    settings = {
                        basedpyright = {
                            disableOrganizeImports = true, -- Using Ruff
                            disableTaggedHints = true,
                            analysis = {
                                diagnosticSeverityOverrides = {
                                    -- https://github.com/microsoft/pyright/blob/main/docs/configuration.md#type-check-diagnostics-settings
                                    reportUndefinedVariable = 'none',
                                },
                                typeCheckingMode = 'standard',
                                autoSearchPaths = true,
                                diagnosticMode = 'openFilesOnly',
                                useLibraryCodeForTypes = true,
                                -- ignore = { '*' }, -- Using Ruff
                            },
                        },
                    },
                },
                ruff = {
                    init_options = {
                        settings = {
                            args = { 'server' },
                        },
                    },
                },
                lua_ls = {
                    settings = {
                        Lua = {
                            runtime = { version = 'LuaJIT' },
                            diagnostics = {
                                globals = { 'vim' },
                            },
                            completion = {
                                callSnippet = 'Replace',
                            },
                            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                            -- diagnostics = { disable = { 'missing-fields' } },
                        },
                    },
                },
                bashls = {},
                dockerls = {},
                docker_compose_language_service = {},
                taplo = {
                    formatting = {
                        indent_string = '  ',
                    },
                }, -- toml
            }
            local tools = {}
            vim.list_extend(tools, linters)
            vim.list_extend(tools, formatters)
            vim.list_extend(tools, daps)
            vim.list_extend(tools, vim.tbl_keys(lsp_servers))

            -- Add borders to `hover`, ... windows
            vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
                border = 'rounded',
            })
            vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
                border = 'rounded',
            })

            -- :Mason
            require('mason').setup {
                ui = {
                    border = 'rounded',
                },
            }
            -- `mason-lspconfig` only allows to install LSPs - `mason-tool-installer` can install all tools
            require('mason-tool-installer').setup { ensure_installed = tools }

            -- Setup baseline configs for all used LSPs
            require('mason-lspconfig').setup { ---@diagnostic disable-line: missing-fields
                automatic_installation = false,
                handlers = {
                    -- LSP servers and clients are able to communicate to each other what features they support.
                    --  By default, Neovim doesn't support everything that is in the LSP specification.
                    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
                    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
                    function(lsp_name)
                        -- This handles overriding only values explicitly passed
                        -- by the server configuration above. Useful when disabling
                        -- certain features of an LSP (for example, turning off formatting for tsserver)
                        --
                        local lsp_config = lsp_servers[lsp_name] or {}
                        lsp_config.capabilities = require('blink.cmp').get_lsp_capabilities(lsp_config.capabilities)
                        require('lspconfig')[lsp_name].setup(lsp_config.capabilities)
                    end,
                },
            }

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
