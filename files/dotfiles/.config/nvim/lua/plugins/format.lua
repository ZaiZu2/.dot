return {
    { -- Autoformat
        'stevearc/conform.nvim',
        lazy = false,
        config = function(_, _)
            local formatters = require('config').formatters
            ---@type conform.setupOpts
            local opts = {
                formatters_by_ft = formatters.ft,
                notify_on_error = false,
                lsp_format = 'fallback',
                formatters = {}, -- Must stay initialized to empty
            }

            -- Following code prioritizes local formatter configs. It traverses upwards
            -- searching for a local config. In case no config files are found, it
            -- defaults to a global config file specified in Neovim configuration under
            -- `nvim/fmts/`. Each formatter can have a global config set up in
            -- `fmt_configs.lua`
            local fmt_path = vim.fn.stdpath 'config' .. '/fmts/'
            -- Collect all used formatters
            local fmt_names = {}
            for _, _fmt_names in pairs(opts.formatters_by_ft) do
                fmt_names = vim.tbl_extend('keep', fmt_names, _fmt_names)
            end

            local utils = require 'utils'
            local conform = require 'conform'
            local last_conf_message = ''
            vim.keymap.set({ 'v', 'n' }, '<leader>f', function()
                -- Extend Conform.nvim config with `prepend_args`,
                -- effectively injecting config into formatters CLI command
                local ft_fmts = formatters.ft[vim.bo.filetype] or {}
                for _, fmt_name in ipairs(ft_fmts) do
                    local fmt_conf = formatters.config[fmt_name]
                    if fmt_conf ~= nil then
                        opts.formatters[fmt_name] = {
                            inherit = true,
                            prepend_args = function(_, ctx)
                                -- Check if there is no formatter config file available locally in project dir
                                local is_local, local_conf_path =
                                    utils.find_files_upwards(ctx.dirname, fmt_conf.conf_files)
                                if is_local then
                                    last_conf_message =
                                        string.format("'%s' using local '%s'", fmt_name, local_conf_path)
                                    return {}
                                -- Fallback to global config
                                else
                                    last_conf_message =
                                        string.format("'%s' using global '%s'", fmt_name, fmt_path .. fmt_conf.filename)
                                    return { fmt_conf.arg, fmt_path .. fmt_conf.filename }
                                end
                            end,
                        }
                    end
                end
                conform.setup(opts)
                conform.format({ lsp_format = 'fallback' }, function(err, did_edit)
                    if did_edit then
                        vim.notify(string.format('Formatted (%s)', last_conf_message))
                    elseif not did_edit and err == nil then
                        vim.notify(string.format('Nothing to format (%s)', last_conf_message))
                    else
                        vim.notify('Failed to format file - ' .. tostring(err))
                    end
                end)
            end, { desc = '[f]ormat buffer' })
        end,
    },
}
