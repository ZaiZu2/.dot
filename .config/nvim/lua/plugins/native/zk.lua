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
      require('zk').setup(opts)

      -- Create a new note after asking for its title.
      vim.api.nvim_set_keymap('n', '<leader>zn', "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", { desc = '[n]ew note' })
      -- Open notes.
      vim.api.nvim_set_keymap('n', '<leader>zo', "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", { desc = '[o]pen notes' })
      -- Open notes associated with the selected tags.
      vim.api.nvim_set_keymap('n', '<leader>zt', '<Cmd>ZkTags<CR>', { desc = 'search through [t]ags' })
      -- Search for the notes matching a given query.
      vim.api.nvim_set_keymap(
        'n',
        '<leader>zf',
        "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
        { desc = 'search through contents' }
      )
      -- Search for the notes matching the current visual selection.
      vim.api.nvim_set_keymap('v', '<leader>zf', ":'<,'>ZkMatch<CR>", {desc='search with selection'})
    end,
  },
}
