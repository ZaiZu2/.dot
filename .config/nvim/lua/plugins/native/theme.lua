return {
  {
    -- Nvim color scheme
    -- :Telescope colorscheme`
    'rebelot/kanagawa.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      vim.cmd.colorscheme 'kanagawa-wave'
      vim.cmd.hi 'Comment gui=none'
    end,
  },
  {
    'nvim-zh/colorful-winsep.nvim',
    event = { 'WinLeave' },
    opts = { hi = {
      fg = '#dcd7ba',
    }, smooth = false },
  },
}
