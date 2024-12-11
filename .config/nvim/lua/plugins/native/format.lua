return {
  { -- Autoformat
    'stevearc/conform.nvim',
    lazy = false,
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- local disable_filetypes = { c = true, cpp = true }
        -- return {
        --   timeout_ms = 500,
        --   lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        -- }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'ruff_format' },
      },
      formatters = {}, -- Must stay initialized to empty
    },
    config = function(_, opts)
      -- Following code prioritizes local formatter configs. It traverses upwards searching for a local config.
      -- In case no config files are found, it default to a global config file specified in Neovim configuration
      -- under `nvim/fmts/`. Each formatter can have a global config set up in the config table below.
      local fmt_configs = {
        stylua = {
          arg = '--config', -- CLI arg for injecting fmt config
          conf_files = { '.stylua.toml' }, -- All files which might be used for local fmt config
          filename = '.stylua.toml', -- Name of the default global fmt config file
        },
        ruff_format = {
          arg = '--config',
          conf_files = { 'ruff.toml', 'pyproject.toml' },
          filename = 'ruff.toml',
        },
      }

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
        local fmt_conf = fmt_configs[fmt_name]
        if fmt_conf ~= nil then
          opts.formatters[fmt_name] = {
            inherit = true,
            prepend_args = function(_, ctx)
              -- Check if there is no formatter config file available locally in project dir
              local is_local, conf_path = find_files_upwards(ctx.dirname, fmt_conf.conf_files)
              if is_local then
                vim.notify(string.format('Formatted the file (local config - %s)', conf_path))
                return
              -- Fallback to global config
              else
                vim.notify(string.format('Formatted the file (global config - %s)', fmt_path .. fmt_conf.filename))
                return { fmt_conf.arg, fmt_path .. fmt_conf.filename }
              end
            end,
          }
        end
      end

      local conform = require 'conform'
      conform.setup(opts)
      vim.keymap.set({ 'v', 'n' }, '<leader>f', function()
        conform.format({ async = false, lsp_fallback = true }, function(err, did_edit)
          -- if did_edit then
          --   vim.notify 'Code formatted'
          -- elseif err then
          --   vim.notify('Error happened while formatting: ' .. vim.inspect(err))
          -- end
        end)
      end, { desc = '[f]ormat buffer' })
    end,
  },
}
