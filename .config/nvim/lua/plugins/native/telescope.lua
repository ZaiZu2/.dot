return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      -- :Telescope help_tags
      -- - Insert mode: <c-/>
      -- - Normal mode: ?
      require('telescope').setup {
        defaults = {
          -- path_display = filename_first,
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- :help telescope.builtin
      local builtin = require 'telescope.builtin'
      local pickers = require 'plugins.native.pickers'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[s]earch [h]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[s]earch [k]eymaps' })

      vim.keymap.set('n', '<leader>sf', function()
        pickers.prettyFilesPicker { picker = 'find_files', hidden = true, no_ignore = true }
      end, { desc = '[s]earch [f]iles' })
      pickers.prettyFilesPicker { picker = 'find_files' }

      vim.keymap.set('n', '<leader>sw', function()
        pickers.prettyGrepPicker { picker = 'grep_string' }
      end, { desc = '[s]earch current [w]ord' })

      vim.keymap.set('n', '<leader>sg', function()
        pickers.prettyGrepPicker { picker = 'live_grep' }
      end, { desc = '[s]earch by [g]rep' })

      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[s]earch [d]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[s]earch [r]esume' })
      -- vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[s]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'search existing buffers' })
      vim.keymap.set('n', '<leader>s?', builtin.builtin, { desc = '[s]earch by custom picker' })
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      -- :help telescope.builtin.live_grep()
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[s]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[s]earch [n]eovim files' })
    end,
  },
}
