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

      vim.keymap.set('n', '<leader>dt', function()
        require('neotest').run.run { strategy = 'dap' }
      end, { desc = '[d]ebug [t]est case' })
      vim.keymap.set('n', '<leader>do', function()
        require('neotest').output.open { enter = true }
      end, { desc = 'toggle [o]utput' })
      vim.keymap.set('n', '<leader>dO', function()
        require('neotest').output_panel.toggle()
      end, { desc = 'toggle [O]utput panel' })
      vim.keymap.set('n', '<leader>dT', function()
        require('neotest').summary.toggle()
      end, { desc = 'open test [T]ree' })
    end,
  },
}
