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
    opts = {
      question_header = '## User ',
      answer_header = '## Copilot ',
      error_header = '## Error ',
      prompts = {
        -- Code related prompts
        Explain = 'Please explain how the following code works.',
        Review = 'Please review the following code and provide suggestions for improvement.',
        Tests = 'Please explain how the selected code works, then generate unit tests for it.',
        Refactor = 'Please refactor the following code to improve its clarity and readability.',
        FixCode = 'Please fix the following code to make it work as intended.',
        FixError = 'Please explain the error in the following text and provide a solution.',
        BetterNamings = 'Please provide better names for the following variables and functions.',
        Documentation = 'Please provide documentation for the following code.',
        SwaggerApiDocs = 'Please provide documentation for the following API using Swagger.',
        SwaggerJsDocs = 'Please write JSDoc for the following API using Swagger.',
        -- Text related prompts
        Summarize = 'Please summarize the following text.',
        Spelling = 'Please correct any grammar and spelling errors in the following text.',
        Wording = 'Please improve the grammar and wording of the following text.',
        Concise = 'Please rewrite the following text to make it more concise.',
      },
      -- auto_follow_cursor = true, -- Don't follow the cursor after getting response
      -- insert_at_end = true,
      show_help = true,
    },
    config = function(_, opts)
      local chat = require 'CopilotChat'
      local select = require 'CopilotChat.select'
      -- Use unnamed register for the selection
      opts.selection = select.unnamed
      -- Override the git prompts message
      opts.prompts.Commit = {
        prompt = 'Write commit message for the change with commitizen convention',
        selection = select.gitdiff,
      }

      chat.setup(opts)
      -- Fallback to buffer source if selection does not exist
      local set_default_selection = function(source)
        return select.visual(source) or select.buffer(source)
      end

      -- Inline chat with Copilot
      local open_floating_chat = function()
        chat.open {
          selection = set_default_selection,
          window = {
            layout = 'float',
            relative = 'editor',
            border = 'rounded',
            width = 0.9,
            height = 0.9,
          },
        }
      end

      local open_vertical_chat = function()
        chat.ask(nil, { selection = set_default_selection })
      end

      -- Custom buffer for CopilotChat
      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = 'copilot-*',
        callback = function()
          vim.opt_local.relativenumber = true
          vim.opt_local.number = true

          -- Get current filetype and set it to markdown if the current filetype is copilot-chat
          local ft = vim.bo.filetype
          if ft == 'copilot-chat' then
            vim.bo.filetype = 'markdown'
          end

          vim.keymap.set({ 'x', 'n' }, 'gS', '<CMD>CopilotChatStop<CR>', { desc = 'Open in vertical split' })
        end,
      })

      vim.keymap.set({ 'x', 'n' }, '<leader>cv', open_vertical_chat, { desc = 'Open in vertical split' })
      vim.keymap.set({ 'x', 'n' }, '<leader>cx', open_floating_chat, { desc = 'Inline chat' })
      vim.keymap.set('n', '<leader>c?', '<CMD>CopilotChatModels<CR>', { desc = 'Select Models' })
      vim.keymap.set('x', '<leader>cp', function()
        require('CopilotChat.integrations.fzflua').pick(require('CopilotChat.actions').prompt_actions { selection = require('CopilotChat.select').visual })
      end, { desc = 'Prompt actions' })
    end,
  },
}
