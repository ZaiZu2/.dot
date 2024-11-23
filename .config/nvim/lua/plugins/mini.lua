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
      vim.keymap.set({ 'n', 'x' }, 's', '<Nop>')
      require('mini.surround').setup()

      require('mini.operators').setup {
        exchange = {
          prefix = 'ge',
          reindent_linewise = true, -- Whether to reindent new text to match previous indent
        },
        evaluate = {
          prefix = '',
          func = nil,
        },
      }

      require('mini.trailspace').setup()

      require('mini.splitjoin').setup()

      require('mini.files').setup { -- Module mappings created only inside explorer.
        options = {
          permanent_delete = false,
          use_as_default_explorer = false,
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
      vim.api.nvim_set_keymap('n', '<C-\\>', '<cmd>lua MiniFiles.open()<CR>', { noremap = true, silent = true, desc = 'Open Mini.Files' })

      local hipatterns = require 'mini.hipatterns'
      hipatterns.setup {
        highlighters = {
          fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
          hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
          todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
          note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      }

      local miniIcons = require 'mini.icons'
      miniIcons.setup()
      miniIcons.mock_nvim_web_devicons()

      -- require('mini.completion').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
