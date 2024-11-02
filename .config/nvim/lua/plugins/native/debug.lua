return {
  {
    'mfussenegger/nvim-dap',
    event = 'VeryLazy',
    dependencies = {
      'rcarriga/nvim-dap-ui', -- Creates a beautiful debugger UI
      'nvim-neotest/nvim-nio', -- Required dependency for nvim-dap-ui
      'theHamsta/nvim-dap-virtual-text',
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

      -- 4 main stepping mechanism are represented by 'hjkl' keys
      vim.keymap.set('n', ',s', dap.continue, { desc = 'Continue/start' })
      vim.keymap.set('n', ',j', dap.step_into, { desc = 'Step into (down)' })
      vim.keymap.set('n', ',k', dap.step_out, { desc = 'Step out (up)' })
      vim.keymap.set('n', ',l', dap.step_over, { desc = 'Step over (right)' })
      vim.keymap.set('n', ',J', dap.run_to_cursor, { desc = '[J]ump to cursor' })
      vim.keymap.set('n', ',r', dap.restart, { desc = '[r]estart' })
      vim.keymap.set('n', ',S', function()
        dap.disconnect { terminateDebuggee = true }
        dap.close()
        dapui.close()
      end, { desc = '[S]top debugger' })

      vim.keymap.set('n', ',b', dap.toggle_breakpoint, { desc = 'Toggle [b]reakpoint' })
      vim.keymap.set('n', ',B', function()
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end, { desc = 'Set conditional [B]reakpoint' })

      vim.keymap.set('n', ',d', dap.down, { desc = 'Move [d]own the stack frame' })
      vim.keymap.set('n', ',u', dap.up, { desc = 'Move [u]p the stack frame' })

      require('nvim-dap-virtual-text').setup {
        display_callback = function(variable)
          if #variable.value > 15 then
            return ' ' .. string.sub(variable.value, 1, 15) .. '... '
          end

          return ' ' .. variable.value
        end,
      }

      -- -- :help nvim-dap-ui
      dapui.setup()
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      vim.keymap.set('n', ',U', dapui.toggle, { desc = 'toggle [U]I' })
      vim.keymap.set('n', ',K', function()
        require('dapui').eval()
      end, { desc = 'Inspect variable' })

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close

      -- Shortcuts to focus nvim-dap-ui windows
      ---@diagnostic disable-next-line: unused-local, unused-function
      local focusDapuiElement = function(el_name)
        local buf_id = require('dapui').elements[el_name].buffer()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf_id then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
      end
      vim.keymap.set('n', ',v', '<cmd>lua focusDapuiElement("repl")<CR>i', { desc = 'Focus REPL' })
      vim.keymap.set('n', ',c', '<cmd>lua focusDapuiElement("stacks")<CR>', { desc = 'Focus Stacks' })
      vim.keymap.set('n', ',x', '<cmd>lua focusDapuiElement("breakpoints")<CR>', { desc = 'Focus Breakpoints' })
      vim.keymap.set('n', ',z', '<cmd>lua focusDapuiElement("scopes")<CR>', { desc = 'Focus Scopes' })

      -- :help dap-configuration
      -- :help dap-python
      require('dap-python').setup 'python'
      require('dap-python').test_runner = 'pytest'
      -- Following functionalities provided by `neotest`
      -- vim.keymap.set('n', ',f', require('dap-python').test_method, { desc = 'test [f]unction' })
      -- vim.keymap.set('n', ',m', require('dap-python').debug_selection, { desc = 'test selection' })

      -- table.insert(require('dap').configurations.python, {
      --   type = 'python',
      --   request = 'launch',
      --   name = 'My custom launch configuration',
      --   program = '${file}',
      --   -- ... more options, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
      -- })
    end,
  },
}
