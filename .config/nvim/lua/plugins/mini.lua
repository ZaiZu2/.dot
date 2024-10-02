return {
  {
    'echasnovski/mini.nvim',
    opts = {},
    config = function()
      -- Better Around/Inside textobjects
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      require('mini.operators').setup()

      require('mini.trailspace').setup()

      require('mini.splitjoin').setup()

      require('mini.files').setup { -- Module mappings created only inside explorer.
        options = {
          permanent_delete = false,
          use_as_default_explorer = true,
        },
        windows = {
          -- Maximum number of windows to show side by side
          max_number = math.huge,
          -- Whether to show preview of file/directory under cursor
          preview = true,
          -- Width of focused window
          width_focus = 50,
          -- Width of non-focused window
          width_nofocus = 15,
          -- Width of preview window
          width_preview = 25,
        },
      }
      vim.api.nvim_set_keymap('n', '<C-\\>', '<cmd>lua MiniFiles.open()<CR>', { noremap = true, silent = true, desc = '[g]o to [s]ource Control' })

      require('mini.notify').setup()

      require('mini.starter').setup()

      require('mini.sessions').setup { autoread = true }

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
