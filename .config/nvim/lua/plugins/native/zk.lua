return {
  {
    'zk-org/zk-nvim',
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
      local zk = require 'zk'
      local commands = require 'zk.commands'
      zk.setup(opts)

      -- Create a new daily note
      vim.keymap.set('n', '<leader>zd', function()
        zk.new { dir = vim.loop.os_getenv 'ZK_NOTEBOOK_DIR' .. '/daily' }
      end, { desc = 'open [d]aily note' })
      -- Create a new note after asking for its title.
      vim.keymap.set('n', '<leader>zn', "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", { desc = '[n]ew note' })
      -- Open notes.
      vim.keymap.set('n', '<leader>zo', "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", { desc = '[o]pen notes' })
      -- Open notes associated with the selected tags.
      vim.keymap.set('n', '<leader>zt', '<Cmd>ZkTags<CR>', { desc = 'search through [t]ags' })
    end,
  },
}
