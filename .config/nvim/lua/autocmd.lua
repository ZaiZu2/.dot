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
