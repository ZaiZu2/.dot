-- Fallback to global config
-- Fallback to global config
-- Fallback to global config
-- Fallback to global config
-- Fallback to global config
-- Fallback to global config
return {
  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        -- markdown = { 'markdownlint' },
        python = { 'ruff' },
        shell = { 'shellcheck' },
        bash = { 'shellcheck' },
        dockerfile = { 'hadolint' },
      }

      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
  },
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
        python = { 'ruff' },
      },
      formatters = {}, -- Must stay initialized to empty
    },
    config = function(_, opts)
      -- Default global formatter configs
      local fmt_configs = {
        stylua = {
          arg = '--config', -- CLI arg for injecting fmt config
          conf_files = { '.stylua.toml' }, -- All files which might be used for local fmt config
          filename = '.stylua.toml', -- Name of the default global fmt config file
        },
        ruff = {
          arg = '--config',
          conf_files = { 'ruff.toml', 'pyproject.toml' },
          filename = 'ruff.toml',
        },
      }

      local fmt_names = {}
      local fmt_path = vim.fn.stdpath 'config' .. '/fmts/'
      for _, _fmt_names in pairs(opts.formatters_by_ft) do
        fmt_names = vim.tbl_extend('keep', fmt_names, _fmt_names)
      end

      --- Recurse upwards searching directories for a local config file
      --- @param local_dir string
      --- @param conf_filenames string[]
      --- @return boolean, string|nil
      local function has_local_config(local_dir, conf_filenames)
        local has, found_files = false, nil
        for i in pairs(conf_filenames) do
          found_files = vim.fs.find(conf_filenames[i], { upward = true, type = 'file', path = local_dir })
          print('result = ', vim.inspect(found_files))
          if found_files[1] ~= nil then
            has = true
            break
          end
        end
        return has, found_files[1]
      end

      for _, fmt_name in ipairs(fmt_names) do
        local fmt_conf = fmt_configs[fmt_name]
        if fmt_conf ~= nil then
          opts.formatters[fmt_name] = {
            inherit = true,
            prepend_args = function(_, ctx)
              -- Check if there is no formatter config file available locally in project dir
              local is_local, conf_path = has_local_config(ctx.dirname, fmt_conf.conf_files)
              if is_local then
                print(string.format('Formatted the file (local config - %s)', conf_path))
                return
              -- Fallback to global config
              else
                print(
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
      vim.keymap.set('n', '<leader>f', function()
        conform.format { async = false, lsp_fallback = true }
      end, { desc = '[f]ormat buffer' })
    end,
  },
}
