return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-python',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-python' {
            dap = { justMyCode = false }, -- optional DAP configuration
          },
        },
      }

      vim.keymap.set('n', ',tt', require('neotest').run.run, { desc = '[t]est case run' })
      vim.keymap.set('n', ',tT', function()
        require('neotest').run { suite = true }
      end, { desc = '[T]est suite run' })
      vim.keymap.set('n', ',ts', require('neotest').run.stop, { desc = '[t]est case [s]top' })
      vim.keymap.set('n', ',tS', function()
        require('neotest').run.stop { suite = true }
      end, { desc = '[t]est suite [S]top' })
      vim.keymap.set('n', ',td', function()
        require('neotest').run.run { strategy = 'dap', suite = true }
      end, { desc = '[t]est case [d]ebug' })

      vim.keymap.set('n', ',o', function()
        require('neotest').output.open { enter = true }
      end, { desc = 'toggle [o]utput' })
      vim.keymap.set('n', ',O', function()
        require('neotest').output_panel.toggle()
      end, { desc = 'toggle [O]utput panel' })
      vim.keymap.set('n', ',T', function()
        require('neotest').summary.toggle()
      end, { desc = 'open test [T]ree' })
    end,
  },
}
