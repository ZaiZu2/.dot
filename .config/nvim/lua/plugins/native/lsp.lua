return {
  { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim', -- Automatic installation of formatters/linters/DAPs

      { 'j-hui/fidget.nvim', opts = {} }, -- Useful status updates for LSP.
      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      { 'folke/neodev.nvim', opts = {} },
    },
    config = function()
      -- Soecify all language tools to be installed automatically
      local tools = {}
      local linters = {}
      local formatters = { 'stylua', 'ruff' }
      local daps = { 'debugpy' }
      local lsp_servers = { -- :help lspconfig-all
        ts_ls = {},
        pyright = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }
      vim.list_extend(tools, linters)
      vim.list_extend(tools, formatters)
      vim.list_extend(tools, daps)
      vim.list_extend(tools, vim.tbl_keys(lsp_servers))

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

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
      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = lsp_servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = desc })
          end

          local telescope = require('telescope.builtin')
          local pickers = require('plugins.native.pickers')
          map(';d', telescope.lsp_definitions, '[d]efinition')
          map(';D', vim.lsp.buf.declaration, '[D]eclaration')
          map(';r', telescope.lsp_references, '[r]eferences')
          map(';i', telescope.lsp_implementations, '[i]mplementation')
          map(';t', telescope.lsp_type_definitions, '[t]ype definition')
          map(';s', pickers.prettyDocumentSymbols, '[s]ymbols')
          map(';p', pickers.prettyWorkspaceSymbols, 'symbols in [p]roject')
          map(';R', vim.lsp.buf.rename, '[R]ename')
          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map(';c', vim.lsp.buf.code_action, '[c]ode action')
          map('K', vim.lsp.buf.hover, 'Show documentation') -- :help K
          vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'Show signature' })

          -- The following two autocommands are used to highlight references of the word
          -- :help CursorHold
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
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
