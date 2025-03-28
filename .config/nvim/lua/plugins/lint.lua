return {
    { -- Linting
        'mfussenegger/nvim-lint',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            local lint = require 'lint'
            lint.linters_by_ft = {
                shell = { 'shellcheck' },
                bash = { 'shellcheck' },
                zsh = { 'shellcheck' },
                dockerfile = { 'hadolint' },
                markdown = { 'markdownlint-cli2' },
            }
        end,
    },
}
