-- Shows how to use the DAP plugin to debug your code.
return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui', -- Creates a beautiful debugger UI
      'nvim-neotest/nvim-nio', -- Required dependency for nvim-dap-ui
      'theHamsta/nvim-dap-virtual-text',
      -- Installs the debug adapters for you
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',
      -- Add your own debuggers here
      'mfussenegger/nvim-dap-python',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      require('mason-nvim-dap').setup {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_installation = true,
        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},
        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
          'debugpy',
        },
      }

      vim.keymap.set('n', '<leader>dj', dap.run_to_cursor, { desc = '[j]ump to Cursor' })
      vim.keymap.set('n', '<leader>dc', dap.continue, { desc = '[c]ontinue/Start' })
      vim.keymap.set('n', '<leader>dd', dap.step_into, { desc = 'Step [d]own (Into)' })
      vim.keymap.set('n', '<leader>do', dap.step_over, { desc = 'Step [o]ver' })
      vim.keymap.set('n', '<leader>du', dap.step_out, { desc = 'Step [u]p (Out)' })
      vim.keymap.set('n', '<leader>dr', dap.restart, { desc = '[r]estart' })
      vim.keymap.set('n', '<leader>ds', function()
        dap.disconnect { terminateDebuggee = true }
        dap.close()
      end, { desc = '[s]top' })
      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle [b]reakpoint' })
      vim.keymap.set('n', '<leader>dB', function()
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end, { desc = 'Set conditional [B]reakpoint' })

      require('nvim-dap-virtual-text').setup {
        display_callback = function(variable)
          if #variable.value > 15 then
            return ' ' .. string.sub(variable.value, 1, 15) .. '... '
          end

          return ' ' .. variable.value
        end,
      }

      -- -- Dap UI setup
      -- -- :help nvim-dap-ui
      dapui.setup()
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      vim.keymap.set('n', '<leader>dt', dapui.toggle, { desc = '[t]oggle last session results' })
      vim.keymap.set('n', '<leader>dk', function()
        require('dapui').eval(nil, { enter = True })
      end, { desc = 'inspect variable' })

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      -- :help dap-configuration
      -- :help dap-python
      require('dap-python').setup 'python'
      -- require('dap-python').test_runner = 'pytest'
    end,
  },
}
