return {
  { -- Copilot autocompletion
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        enabled = true,
        auto_trigger = true,
        suggestion = {
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
    branch = 'canary', -- Use the canary branch if you want to test the latest features but it might be unstable
    dependencies = {
      { 'nvim-telescope/telescope.nvim' }, -- Use telescope for help actions
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
      auto_follow_cursor = true, -- Don't follow the cursor after getting response
      insert_at_end = true,
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
      opts.prompts.CommitStaged = {
        prompt = 'Write commit message for the change with commitizen convention',
        selection = function(source)
          return select.gitdiff(source, true)
        end,
      }

      chat.setup(opts)

      vim.api.nvim_create_user_command('CopilotChatVisual', function(args)
        chat.ask(args.args, { selection = select.visual })
      end, { nargs = '*', range = true })

      -- Inline chat with Copilot
      vim.api.nvim_create_user_command('CopilotChatFloat', function(args)
        chat.ask(args.args, {
          selection = select.visual,
          window = {
            layout = 'float',
            relative = 'editor',
            border = 'rounded',
            width = 0.9,
            height = 0.9,
          },
        })
      end, { nargs = '*', range = true })

      -- Restore CopilotChatBuffer
      vim.api.nvim_create_user_command('CopilotChatBuffer', function(args)
        chat.ask(args.args, { selection = select.buffer })
      end, { nargs = '*', range = true })

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
        end,
      })
    end,
    keys = {
      {
        '<leader>cv',
        ':CopilotChatVisual',
        mode = { 'x', 'n' },
        desc = 'Open in vertical split',
      },
      {
        '<leader>cx',
        ':CopilotChatFloat<cr>',
        mode = { 'x', 'n' },
        desc = 'Inline chat',
      },
      {
        '<leader>cq',
        function()
          local input = vim.fn.input 'Quick Chat: '
          if input ~= '' then
            vim.cmd('CopilotChatBuffer ' .. input)
          end
        end,
        desc = 'Quick chat',
      },
      { '<leader>cl', '<cmd>CopilotChatReset<cr>', desc = 'Clear buffer and chat history' }, -- Toggle Copilot Chat Vsplit
      { '<leader>cv', '<cmd>CopilotChatToggle<cr>', desc = 'Toggle' },
      { '<leader>c?', '<cmd>CopilotChatModels<cr>', desc = 'Select Models' },
      { -- Show help actions with telescope
        '<leader>ch',
        function()
          local actions = require 'CopilotChat.actions'
          require('CopilotChat.integrations.telescope').pick(actions.help_actions())
        end,
        desc = 'Help actions',
      },
      { -- Show prompts actions with telescope
        '<leader>cp',
        ":lua require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').prompt_actions({selection = require('CopilotChat.select').visual}))<CR>",
        mode = 'x',
        desc = 'Prompt actions',
      },
      -- Custom input for CopilotChat
      -- {
      --   '<leader>ci',
      --   function()
      --     local input = vim.fn.input 'Ask Copilot: '
      --     if input ~= '' then
      --       vim.cmd('CopilotChat ' .. input)
      --     end
      --   end,
      --   desc = 'Ask input',
      -- },
      -- Generate commit message based on the git diff
      -- {
      --   '<leader>cm',
      --   '<cmd>CopilotChatCommit<cr>',
      --   desc = 'Generate commit message for all changes',
      -- },
      -- {
      --   '<leader>cM',
      --   '<cmd>CopilotChatCommitStaged<cr>',
      --   desc = 'Generate commit message for staged changes',
      -- },
      -- Quick chat with Copilot
      -- Debug
      -- { '<leader>cd', '<cmd>CopilotChatDebugInfo<cr>', desc = 'Debug Info' },
      -- Fix the issue with diagnostic
      -- { '<leader>cf', '<cmd>CopilotChatFixDiagnostic<cr>', desc = 'Fix Diagnostic' },
      -- Clear buffer and chat history
    },
  },
}
