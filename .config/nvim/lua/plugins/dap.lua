return {
    {
        'mfussenegger/nvim-dap',
        event = 'VeryLazy',
        dependencies = {
            'rcarriga/nvim-dap-ui',
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
                automatic_installation = true,
                handlers = {},
                ensure_installed = {
                    'debugpy',
                },
            }

            local fzflua = require 'fzf-lua'
            vim.keymap.set('n', ',fc', fzflua.dap_commands, { desc = 'List [c]ommands' })
            vim.keymap.set('n', ',fC', fzflua.dap_configurations, { desc = 'List [C]onfigurations' })
            vim.keymap.set('n', ',fv', fzflua.dap_variables, { desc = 'List [v]ariables' })
            vim.keymap.set('n', ',ff', fzflua.dap_frames, { desc = 'List [f]rames' })
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
            vim.keymap.set('n', ',fb', fzflua.dap_breakpoints, { desc = 'List [b]reakpoints' })

            vim.keymap.set('n', ',d', dap.down, { desc = 'Move [d]own the stack frame' })
            vim.keymap.set('n', ',u', dap.up, { desc = 'Move [u]p the stack frame' })

            require('nvim-dap-virtual-text').setup {
                display_callback = function(variable)
                    if #variable.value > 10 then
                        return ''
                    end

                    return ' ' .. variable.value
                end,
            }

            -- :help nvim-dap-ui
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
