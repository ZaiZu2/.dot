return {
    { -- Autoformat
        'stevearc/conform.nvim',
        lazy = false,
        config = function(_, _)
            local fmtr_configs = require 'fmt_configs'
            local opts = {
                formatters_by_ft = fmtr_configs.ft_configs,
                notify_on_error = false,
                format_on_save = function(bufnr)
                    -- local disable_filetypes = { c = true, cpp = true }
                    -- return {
                    --   timeout_ms = 500,
                    --   lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
                    -- }
                end,
                lsp_format = 'fallback',
                formatters = {}, -- Must stay initialized to empty
            }

            -- Following code prioritizes local formatter configs. It traverses upwards
            -- searching for a local config. In case no config files are found, it
            -- defaults to a global config file specified in Neovim configuration under
            -- `nvim/fmts/`. Each formatter can have a global config set up in
            -- `fmt_configs.lua`
            local fmt_names = {}
            local fmt_path = vim.fn.stdpath 'config' .. '/fmts/'
            -- Collect all used formatters
            for _, _fmt_names in pairs(opts.formatters_by_ft) do
                fmt_names = vim.tbl_extend('keep', fmt_names, _fmt_names)
            end

            --- Recurse up the filesystem, searching for one of the specified files
            --- @param local_dir string
            --- @param conf_filenames string[]
            --- @return boolean, string|nil
            local function find_files_upwards(local_dir, conf_filenames)
                local has, found_files = false, nil
                for i in pairs(conf_filenames) do
                    found_files = vim.fs.find(conf_filenames[i], { upward = true, type = 'file', path = local_dir })
                    if found_files[1] ~= nil then
                        has = true
                        break
                    end
                end
                return has, found_files[1]
            end

            -- Extend Conform.nvim config with `prepend_args`,
            -- effectively injecting config into formatters CLI command
            for _, fmt_name in ipairs(fmt_names) do
                local fmt_conf = fmtr_configs.fmtr_configs[fmt_name]
                if fmt_conf ~= nil then
                    opts.formatters[fmt_name] = {
                        inherit = true,
                        prepend_args = function(_, ctx)
                            -- Check if there is no formatter config file available locally in project dir
                            local is_local, local_conf_path = find_files_upwards(ctx.dirname, fmt_conf.conf_files)
                            if is_local then
                                vim.notify(string.format('Formatted the file (local config - %s)', local_conf_path))
                                return
                            -- Fallback to global config
                            else
                                vim.notify(
                                    string.format(
                                        'Formatted the file (global config - %s)',
                                        fmt_path .. fmt_conf.filename
                                    )
                                )
                                return { fmt_conf.arg, fmt_path .. fmt_conf.filename }
                            end
                        end,
                    }
                end
            end

            local conform = require 'conform'
            conform.setup(opts)
            vim.keymap.set({ 'v', 'n' }, '<leader>f', function()
                conform.format({ lsp_format = 'fallback' }, function(err, did_edit)
                    -- if did_edit then
                    --     vim.notify 'Code formatted'
                    -- end
                end)
            end, { desc = '[f]ormat buffer' })
        end,
    },
}
