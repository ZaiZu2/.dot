return {
    { -- Copilot autocompletion
        'zbirenbaum/copilot.lua',
        cmd = 'Copilot',
        event = 'InsertEnter',
        config = function()
            require('copilot').setup {
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    keymap = {
                        accept = '<M-y>',
                        accept_line = '<M-l>',
                        accept_word = '<M-w>',
                        next = '<M-n>',
                        prev = '<M-p>',
                    },
                },
            }
        end,
    },
    {
        'CopilotC-Nvim/CopilotChat.nvim',
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
            { 'zbirenbaum/copilot.lua' },
        },
        event = 'VeryLazy',
        build = 'make tiktoken', -- Only on MacOS or Linux
        ---@type CopilotChat.config
        opts = {
            model = 'gpt-4o',
            question_header = '# User ',
            answer_header = '# Copilot ',
            error_header = '# Error ',
            selection = function(source)
                local select = require 'CopilotChat.select'
                return select.visual(source) or select.buffer(source)
            end,
            system_prompt = [[
You are a code-focused AI programming assistant that specializes in practical software
engineering solutions. Follow the user's requirements carefully & to the letter. Keep your
answers short and impersonal. The user works in an IDE called Neovim which has a concept
for editors with open files, integrated unit test support, an output pane that shows the
output of running the code as well as an integrated terminal. The user is working on
a Linux machine. Please respond with system specific commands if applicable. You will
receive code snippets that include line number prefixes - use these to maintain correct
position references but remove them when generating output.

When presenting code changes:
1. For each change, first provide a header outside code blocks with format:
   [file:<file_name>](<file_path>) line:<start_line>-<end_line>
2. Then wrap the actual code in triple backticks with the appropriate language identifier.
3. Keep changes minimal and focused to produce short diffs.
4. Include complete replacement code for the specified line range with:
   - Proper indentation matching the source
   - All necessary lines (no eliding with comments)
   - No line number prefixes in the code
5. Address any diagnostics issues when fixing code.
6. If multiple changes are needed, present them as separate blocks with their own headers.
]],
            mappings = {
                reset = { normal = 'gR' },
            },
            show_help = true,
            highlight_headers = false,
        },
        config = function(_, opts)
            local chat = require 'CopilotChat'
            chat.setup(opts)

            local docstring_prompt = [[
Write a docstring for the selected object - function/method/class.
1. Use GOOGLE type of a docstring for python, but:
   - skip type hint next to arguments if the code itself is type hinted.
   - Merge the header with the description block into one.
2. Docstring quotes should be defined on separate lines.
3. Provide only the docstring enclosed in quotes in the code block.
4. Specify the object for which the docstring was generated above the code block.
5. If selection spans multiple objects, always choose the outermost one. If there
   are multiple outermost objects, choose first.
]]
            local rewrite_prompt = 'Please rewrite the selected text to make it flow and sound better'

            local open_floating_chat = function()
                if require('CopilotChat').chat:visible() then
                    chat.close()
                else
                    chat.open {
                        window = {
                            layout = 'float',
                            relative = 'editor',
                            border = 'rounded',
                            width = 0.9,
                            height = 0.9,
                        },
                    }
                end
            end

            local open_inline_chat = function(prompt)
                chat.open {
                    title = '',
                    ---@type CopilotChat.config.window
                    window = {
                        title='',
                        layout = 'float',
                        border = 'rounded',
                        relative = 'cursor',
                        width = 1,
                        height = 0.4,
                        row = 1,
                    },
                }
                chat.ask(prompt)
            end

            local open_vertical_chat = function()
                if require('CopilotChat').chat:visible() then
                    chat.close()
                else
                    chat.open()
                end
            end

            -- Custom buffer for CopilotChat
            vim.api.nvim_create_autocmd('BufEnter', {
                pattern = 'copilot-*',
                callback = function()
                    vim.opt_local.relativenumber = true
                    vim.opt_local.number = true
                    vim.keymap.set({ 'x', 'n' }, 'gS', chat.stop, { desc = '[S]top current chat output' })
                end,
            })

            vim.keymap.set({ 'x', 'n' }, '<leader>cx', open_floating_chat, { desc = 'Floating chat' })
            vim.keymap.set({ 'x', 'n' }, '<leader>cv', open_vertical_chat, { desc = 'Vertical split chat' })
            vim.keymap.set({ 'x', 'n' }, '<leader>cd', function()
                open_inline_chat(docstring_prompt)
            end, { desc = 'Generate a docstring' })
            vim.keymap.set({ 'x', 'n' }, '<leader>cr', function()
                open_inline_chat(rewrite_prompt)
            end, { desc = 'Rewrite text' })
            vim.keymap.set('n', '<leader>cm', chat.select_model, { desc = 'Select Models' })
        end,
    },
}
