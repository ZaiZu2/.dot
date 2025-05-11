return {
    {
        'mfussenegger/nvim-lint',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            local lint = require 'lint'
            local config = require 'config'
            for lint_name, lint_conf in pairs(config.linters.custom) do
                lint.linters[lint_name] = lint_conf
            end
            lint.linters_by_ft = config.linters.ft

            vim.api.nvim_create_autocmd({ 'TextChanged' }, {
                callback = function()
                    lint.try_lint()
                end,
            })
        end,
    },
}
