return {
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      triggers = {
        { '<auto>', mode = 'nixsotc' },
        { 's', mode = { 'n', 'v' } },
      },
    },
    config = function(_, opts)
      require('which-key').setup(opts)

      -- Updated general key mappings
      require('which-key').add {
        { '<leader>c', group = '[c]opilot' },
        { '<leader>c_', hidden = true },
        { '<leader>g', group = '[g]o to', icon = { icon = '', color = 'purple' } },
        { '<leader>g_', hidden = true },
        { '<leader>s', group = '[s]earch' },
        { '<leader>s_', hidden = true },
        { '<leader>t', group = '[t]oggle' },
        { '<leader>t_', hidden = true },
        { '<leader>w', group = '[w]orkspace' },
        { '<leader>w_', hidden = true },
        { '<leader>h', group = 'Git [h]unk' },
        { '<leader>h_', hidden = true },
        { ',t', group = '[t]ests' },
        { ',t_', hidden = true },
      }

      -- Updated visual mode key mappings
      require('which-key').add {
        { '<leader>h', desc = 'Git [h]unk', mode = 'v' },
      }
    end,
  },
}
