vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'TextChangedT', 'TextChangedP', 'TextYankPost' }, {
    desc = 'Autosave files on any changes',
    group = vim.api.nvim_create_augroup('auto-save', { clear = true }),
    callback = function(ctx)
        if not vim.bo.buftype == '' or not vim.bo.modified or vim.fn.findfile(ctx.file, '.') == '' then
            return
        end

        vim.cmd 'silent w'
    end,
})

-- Highlight when yanking (copying) text
-- :help lua-guide-autocommands
-- :help vim.highlight.on_yank()
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

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
