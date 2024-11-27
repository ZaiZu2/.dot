return {
  {
    'zk-org/zk-nvim',
    event = 'VeryLazy',
    opts = {
      picker = 'telescope',
      lsp = {
        -- `config` is passed to `vim.lsp.start_client(config)`
        config = {
          cmd = { 'zk', 'lsp' },
          name = 'zk',
          -- on_attach = ...
          -- etc, see `:h vim.lsp.start_client()`
        },
        -- automatically attach buffers in a zk notebook that match the given filetypes
        auto_attach = {
          enabled = true,
          filetypes = { 'markdown' },
        },
      },
    },
    config = function(_, opts)
      local ZK_PATH = vim.loop.os_getenv 'ZK_NOTEBOOK_DIR'
      local zk = require 'zk'
      local commands = require 'zk.commands'
      zk.setup(opts)

      local pickers = require 'telescope.pickers'
      local finders = require 'telescope.finders'
      local conf = require('telescope.config').values
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'
      local picker_opts = require('telescope.themes').get_dropdown {
        previewer = false,
        prompt_title = 'Note type',
      }

      local pick_new_note = function()
        pickers
          .new(picker_opts, {
            finder = finders.new_table { results = { 'daily', 'knowledge', 'absa' } },
            sorter = conf.generic_sorter {},
            attach_mappings = function(bufnr, map)
              actions.select_default:replace(function()
                actions.close(bufnr)
                local selection = action_state.get_selected_entry()
                print(vim.inspect(selection))
                zk.new { dir = selection[1], edit = true }
              end)
              return true
            end,
          })
          :find()
      end

      -- Create a new daily note
      vim.keymap.set('n', '<leader>zd', function()
        zk.new { dir = ZK_PATH .. '/daily' }
      end, { desc = 'open [d]aily note' })
      vim.keymap.set('n', '<leader>zn', pick_new_note, { desc = '[n]ew note' })
      vim.keymap.set('n', '<leader>zo', "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", { desc = '[o]pen notes' })
      vim.keymap.set('n', '<leader>zt', '<Cmd>ZkTags<CR>', { desc = 'search through [t]ags' })
    end,
  },
}
