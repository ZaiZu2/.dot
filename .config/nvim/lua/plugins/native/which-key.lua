return {
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    config = function()
      require('which-key').setup()

      -- Updated general key mappings
      require('which-key').add {
        { '<leader>c', group = '[c]opilot' },
        { '<leader>c_', hidden = true },
        { '<leader>d', group = '[d]ebuger', icon = { icon = '', color = 'purple' } },
        { '<leader>d_', hidden = true },
        { '<leader>r', group = '[r]ename' },
        { '<leader>r_', hidden = true },
        { '<leader>s', group = '[s]earch' },
        { '<leader>s_', hidden = true },
        { '<leader>t', group = '[t]oggle' },
        { '<leader>t_', hidden = true },
        { '<leader>w', group = '[w]orkspace' },
        { '<leader>w_', hidden = true },
        { '<leader>h', group = 'Git [h]unk' },
        { '<leader>h_', hidden = true },
      }

      -- Updated visual mode key mappings
      require('which-key').add {
        { '<leader>h', desc = 'Git [h]unk', mode = 'v' },
      }
    end,
  },
}
