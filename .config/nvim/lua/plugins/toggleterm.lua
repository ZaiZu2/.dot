return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    config = function()
      require('toggleterm').setup {
        -- open_mapping = [[<leader>gt]],
        size = function(term)
          if term.direction == 'horizontal' then
            return 15
          elseif term.direction == 'vertical' then
            return vim.o.columns * 0.4
          end
        end,
        hide_numbers = true, -- hide the number column in toggleterm buffers
        shade_filetypes = {},
        autochdir = false, -- when neovim changes it current directory the terminal will change it's own when next it's opened
        shade_terminals = false, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
        start_in_insert = true,
        insert_mappings = true, -- whether or not the open mapping applies in insert mode
        terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
        persist_size = true,
        persist_mode = true, -- if set to true (default) the previous terminal mode will be remembered
        direction = 'horizontal', -- 'vertical' | 'horizontal' | 'tab' | 'float'
        close_on_exit = true, -- close the terminal window when the process exits
        clear_env = false, -- use only environmental variables from `env`, passed to jobstart()
        shell = vim.o.shell,
        auto_scroll = true, -- automatically scroll to the bottom on terminal output
        float_opts = {
          -- The border key is *almost* the same as 'nvim_open_win'
          -- see :h nvim_open_win for details on borders however
          -- the 'curved' border is a custom border type
          -- not natively supported but implemented in this plugin.
          border = 'rounded', -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
          -- like `size`, width, height, row, and col can be a number or function which is passed the current terminal
          -- width = <value>,
          -- height = <value>,
          -- row = <value>,
          -- col = <value>,
          winblend = 0,
          -- zindex = <value>,
          title_pos = 'center', -- 'left' | 'center' | 'right', position of the title of the floating window
        },
        winbar = {
          enabled = false,
          name_formatter = function(term) --  term: Terminal
            return term.name
          end,
        },
      }

      function _G.set_terminal_keymaps()
        local opts = { buffer = 0 }
        vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
        vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
      end
      -- if you only want these mappings for toggle term use term://*toggleterm#* instead
      vim.cmd 'autocmd! TermOpen term://* lua set_terminal_keymaps()'

      local Terminal = require('toggleterm.terminal').Terminal
      local lazygit = Terminal:new {
        cmd = 'lazygit',
        direction = 'float', -- the layout for the terminal, same as the main config options
        close_on_exit = true, -- close the terminal window when the process exits
        hidden = true,
      }
      function _Lazygit_toggle()
        lazygit:toggle()
      end
      vim.api.nvim_set_keymap('n', '<leader>gg', '<cmd>lua _Lazygit_toggle()<CR>', { noremap = true, silent = true, desc = '[g]it' })

      local pythonInteractive = Terminal:new {
        cmd = 'python3',
        direction = 'float', -- the layout for the terminal, same as the main config options
        close_on_exit = true, -- close the terminal window when the process exits
        hidden = true,
      }
      function _Python_interactive_toggle()
        pythonInteractive:toggle()
      end
      vim.keymap.set('n', '<leader>gp', _Python_interactive_toggle, { noremap = true, silent = true, desc = '[p]ython Interactive Shell' })
    end,
  },
}
