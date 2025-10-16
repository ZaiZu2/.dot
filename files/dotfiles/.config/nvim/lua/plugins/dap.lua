return {
    {
        'mfussenegger/nvim-dap',
        event = 'VeryLazy',
        dependencies = {
            {
                'igorlfs/nvim-dap-view',
                opts = {
                    winbar = {
                        show = true,
                        -- You can add a "console" section to merge the terminal with the other views
                        sections = { 'watches', 'exceptions', 'breakpoints', 'threads', 'repl' },
                        default_section = 'repl',
                    },
                    windows = {
                        height = 12,
                        terminal = {
                            position = 'right',
                            hide = {},
                        },
                    },
                },
            },
            'theHamsta/nvim-dap-virtual-text',
            -- Add your own debuggers here
            'mfussenegger/nvim-dap-python',
        },
        config = function()
            local dap = require 'dap'
            local dap_view = require 'dap-view'
            local widgets = require 'dap.ui.widgets'

            -- local fzflua = require 'fzf-lua'
            -- vim.keymap.set('n', ',fc', fzflua.dap_commands, { desc = 'List [c]ommands' })
            -- vim.keymap.set('n', ',fC', fzflua.dap_configurations, { desc = 'List [C]onfigurations' })
            -- vim.keymap.set('n', ',fv', fzflua.dap_variables, { desc = 'List [v]ariables' })
            -- vim.keymap.set('n', ',ff', fzflua.dap_frames, { desc = 'List [f]rames' })
            -- 4 main stepping mechanism are represented by 'hjkl' keys
            vim.keymap.set('n', ',s', dap.continue, { desc = 'Continue/[s]tart' })
            vim.keymap.set('n', ',j', dap.step_into, { desc = 'Step into (down)' })
            vim.keymap.set('n', ',k', dap.step_out, { desc = 'Step out (up)' })
            vim.keymap.set('n', ',l', dap.step_over, { desc = 'Step over (right)' })
            vim.keymap.set('n', ',J', dap.run_to_cursor, { desc = '[J]ump to cursor' })
            vim.keymap.set('n', ',r', dap.restart, { desc = '[r]estart' })
            vim.keymap.set('n', ',S', function()
                dap.disconnect { terminateDebuggee = true }
                dap.close()
                dap_view.close()
            end, { desc = '[S]top debugger' })

            vim.keymap.set('n', ',b', dap.toggle_breakpoint, { desc = 'Toggle [b]reakpoint' })
            vim.keymap.set(
                'n',
                ',B',
                function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
                { desc = 'Set conditional [B]reakpoint' }
            )
            -- vim.keymap.set('n', ',fb', fzflua.dap_breakpoints, { desc = 'List [b]reakpoints' })

            vim.keymap.set('n', ',d', dap.down, { desc = 'Move [d]own the stack frame' })
            vim.keymap.set('n', ',u', dap.up, { desc = 'Move [u]p the stack frame' })
            vim.keymap.set('n', ',w', dap_view.add_expr, { desc = '[w]atch the expression' })

            require('nvim-dap-virtual-text').setup {
                display_callback = function(variable)
                    if #variable.value > 10 then
                        return ''
                    end
                    return ' ' .. variable.value
                end,
            }

            -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
            vim.keymap.set('n', ',U', dap_view.toggle, { desc = 'toggle [U]I' })
            vim.keymap.set(
                'n',
                ',K',
                function() require('dap.ui.widgets').hover(nil, { border = 'rounded' }) end,
                { desc = 'Hover expression' }
            )
            vim.keymap.set(
                'n',
                ',v',
                function() widgets.centered_float(widgets.scopes, { border = 'rounded' }) end,
                { desc = 'Inspect [v]ariables' }
            )

            dap.listeners.before.attach['dap-view-config'] = function() dap_view.open() end
            dap.listeners.before.launch['dap-view-config'] = function() dap_view.open() end
            dap.listeners.before.event_terminated['dap-view-config'] = function() dap_view.close(true) end
            dap.listeners.before.event_exited['dap-view-config'] = function() dap_view.close(true) end

            -- :help dap-configuration
            -- :help dap-python
            require('dap-python').setup 'python3'
            require('dap-python').test_runner = 'pytest'
            -- Following functionalities provided by `neotest`
            -- vim.keymap.set('n', ',f', require('dap-python').test_method, { desc = 'test [f]unction' })
            -- vim.keymap.set('n', ',m', require('dap-python').debug_selection, { desc = 'test selection' })

            for lang, debugger in pairs(require('config').daps) do
                for _, setting in ipairs(debugger.config) do
                    table.insert(dap.configurations[lang], 1, setting)
                end
            end
        end,
    },
}
