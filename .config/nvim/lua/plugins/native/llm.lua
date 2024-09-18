local prompts = {
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
}

return {
  { -- Copilot autocompletion
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
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
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
      question_header = '## User ',
      answer_header = '## Copilot ',
      error_header = '## Error ',
      prompts = prompts,
      auto_follow_cursor = false, -- Don't follow the cursor after getting response
      show_help = true, -- Show help in virtual text, set to true if that's 1st time using Copilot Chat
      mappings = {
        -- Use tab for completion
        complete = {
          detail = 'Use @<Tab> or /<Tab> for options.',
          insert = '<Tab>',
        },
        -- Close the chat
        close = {
          normal = 'q',
          insert = '<C-c>',
        },
        -- Reset the chat buffer
        reset = {
          normal = '<C-x>',
          insert = '<C-x>',
        },
        -- Submit the prompt to Copilot
        submit_prompt = {
          normal = '<CR>',
          insert = '<C-CR>',
        },
        -- Accept the diff
        accept_diff = {
          normal = '<C-y>',
          insert = '<C-y>',
        },
        -- Yank the diff in the response to register
        yank_diff = {
          normal = 'gmy',
        },
        -- Show the diff
        show_diff = {
          normal = 'gmd',
        },
        -- Show the prompt
        show_system_prompt = {
          normal = 'gmp',
        },
        -- Show the user selection
        show_user_selection = {
          normal = 'gms',
        },
        -- Show help
        show_help = {
          normal = 'gmh',
        },
      },
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
      -- Setup the CMP integration
      require('CopilotChat.integrations.cmp').setup()

      vim.api.nvim_create_user_command('CopilotChatVisual', function(args)
        chat.ask(args.args, { selection = select.visual })
      end, { nargs = '*', range = true })

      -- Inline chat with Copilot
      vim.api.nvim_create_user_command('CopilotChatInline', function(args)
        chat.ask(args.args, {
          selection = select.visual,
          window = {
            layout = 'float',
            relative = 'cursor',
            width = 1,
            height = 0.4,
            row = 1,
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
    event = 'VeryLazy',
    keys = {
      -- Show help actions with telescope
      {
        '<leader>ah',
        function()
          local actions = require 'CopilotChat.actions'
          require('CopilotChat.integrations.telescope').pick(actions.help_actions())
        end,
        desc = 'CopilotChat - Help actions',
      },
      -- Show prompts actions with telescope
      {
        '<leader>ap',
        function()
          local actions = require 'CopilotChat.actions'
          require('CopilotChat.integrations.telescope').pick(actions.prompt_actions())
        end,
        desc = 'CopilotChat - Prompt actions',
      },
      {
        '<leader>ap',
        ":lua require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').prompt_actions({selection = require('CopilotChat.select').visual}))<CR>",
        mode = 'x',
        desc = 'CopilotChat - Prompt actions',
      },
      -- Code related commands
      { '<leader>ae', '<cmd>CopilotChatExplain<cr>', desc = 'CopilotChat - Explain code' },
      { '<leader>at', '<cmd>CopilotChatTests<cr>', desc = 'CopilotChat - Generate tests' },
      { '<leader>ar', '<cmd>CopilotChatReview<cr>', desc = 'CopilotChat - Review code' },
      { '<leader>aR', '<cmd>CopilotChatRefactor<cr>', desc = 'CopilotChat - Refactor code' },
      { '<leader>an', '<cmd>CopilotChatBetterNamings<cr>', desc = 'CopilotChat - Better Naming' },
      -- Chat with Copilot in visual mode
      {
        '<leader>av',
        ':CopilotChatVisual',
        mode = 'x',
        desc = 'CopilotChat - Open in vertical split',
      },
      {
        '<leader>ax',
        ':CopilotChatInline<cr>',
        mode = 'x',
        desc = 'CopilotChat - Inline chat',
      },
      -- Custom input for CopilotChat
      {
        '<leader>ai',
        function()
          local input = vim.fn.input 'Ask Copilot: '
          if input ~= '' then
            vim.cmd('CopilotChat ' .. input)
          end
        end,
        desc = 'CopilotChat - Ask input',
      },
      -- Generate commit message based on the git diff
      {
        '<leader>am',
        '<cmd>CopilotChatCommit<cr>',
        desc = 'CopilotChat - Generate commit message for all changes',
      },
      {
        '<leader>aM',
        '<cmd>CopilotChatCommitStaged<cr>',
        desc = 'CopilotChat - Generate commit message for staged changes',
      },
      -- Quick chat with Copilot
      {
        '<leader>aq',
        function()
          local input = vim.fn.input 'Quick Chat: '
          if input ~= '' then
            vim.cmd('CopilotChatBuffer ' .. input)
          end
        end,
        desc = 'CopilotChat - Quick chat',
      },
      -- Debug
      { '<leader>ad', '<cmd>CopilotChatDebugInfo<cr>', desc = 'CopilotChat - Debug Info' },
      -- Fix the issue with diagnostic
      { '<leader>af', '<cmd>CopilotChatFixDiagnostic<cr>', desc = 'CopilotChat - Fix Diagnostic' },
      -- Clear buffer and chat history
      { '<leader>al', '<cmd>CopilotChatReset<cr>', desc = 'CopilotChat - Clear buffer and chat history' },
      -- Toggle Copilot Chat Vsplit
      { '<leader>av', '<cmd>CopilotChatToggle<cr>', desc = 'CopilotChat - Toggle' },
      -- Copilot Chat Models
      { '<leader>a?', '<cmd>CopilotChatModels<cr>', desc = 'CopilotChat - Select Models' },
    },
  },
  -- { -- LLM chat integration
  --   'robitx/gp.nvim',
  --   config = function()
  --     require('gp').setup {
  --       providers = {
  --         copilot = {
  --           disable = false,
  --           endpoint = 'https://api.githubcopilot.com/chat/completions',
  --           secret = {
  --             'bash',
  --             '-c',
  --             "cat ~/.config/github-copilot/apps.json | sed -e 's/.*oauth_token...//;s/\".*//'",
  --           },
  --         },
  --       },
  --       agents = {
  --         {
  --           name = 'ChatGPT3-5',
  --           disable = true,
  --         },
  --         {
  --           provider = 'copilot',
  --           name = 'ChatCopilot',
  --           chat = true,
  --           command = true,
  --           -- string with model name or table with model name and parameters
  --           model = { model = 'gpt-4o', temperature = 1.1, top_p = 1 },
  --           -- system prompt (use this to specify the persona/role of the AI)
  --           system_prompt = require('gp.defaults').chat_system_prompt,
  --         },
  --       },
  --     }
  --
  --     require('which-key').add {
  --       -- VISUAL mode mappings
  --       -- s, x, v modes are handled the same way by which_key
  --       {
  --         mode = { 'v' },
  --         nowait = true,
  --         remap = false,
  --         { '<C-g><C-t>', ":<C-u>'<,'>GpChatNew tabnew<cr>", desc = 'ChatNew tabnew' },
  --         { '<C-g><C-v>', ":<C-u>'<,'>GpChatNew vsplit<cr>", desc = 'ChatNew vsplit' },
  --         { '<C-g><C-x>', ":<C-u>'<,'>GpChatNew split<cr>", desc = 'ChatNew split' },
  --         { '<C-g>a', ":<C-u>'<,'>GpAppend<cr>", desc = 'Visual Append (after)' },
  --         { '<C-g>b', ":<C-u>'<,'>GpPrepend<cr>", desc = 'Visual Prepend (before)' },
  --         { '<C-g>c', ":<C-u>'<,'>GpChatNew<cr>", desc = 'Visual Chat New' },
  --         { '<C-g>g', group = 'generate into new ..' },
  --         { '<C-g>ge', ":<C-u>'<,'>GpEnew<cr>", desc = 'Visual GpEnew' },
  --         { '<C-g>gn', ":<C-u>'<,'>GpNew<cr>", desc = 'Visual GpNew' },
  --         { '<C-g>gp', ":<C-u>'<,'>GpPopup<cr>", desc = 'Visual Popup' },
  --         { '<C-g>gt', ":<C-u>'<,'>GpTabnew<cr>", desc = 'Visual GpTabnew' },
  --         { '<C-g>gv', ":<C-u>'<,'>GpVnew<cr>", desc = 'Visual GpVnew' },
  --         { '<C-g>i', ":<C-u>'<,'>GpImplement<cr>", desc = 'Implement selection' },
  --         { '<C-g>n', '<cmd>GpNextAgent<cr>', desc = 'Next Agent' },
  --         { '<C-g>p', ":<C-u>'<,'>GpChatPaste<cr>", desc = 'Visual Chat Paste' },
  --         { '<C-g>r', ":<C-u>'<,'>GpRewrite<cr>", desc = 'Visual Rewrite' },
  --         { '<C-g>s', '<cmd>GpStop<cr>', desc = 'GpStop' },
  --         { '<C-g>t', ":<C-u>'<,'>GpChatToggle<cr>", desc = 'Visual Toggle Chat' },
  --         { '<C-g>w', group = 'Whisper' },
  --         { '<C-g>wa', ":<C-u>'<,'>GpWhisperAppend<cr>", desc = 'Whisper Append' },
  --         { '<C-g>wb', ":<C-u>'<,'>GpWhisperPrepend<cr>", desc = 'Whisper Prepend' },
  --         { '<C-g>we', ":<C-u>'<,'>GpWhisperEnew<cr>", desc = 'Whisper Enew' },
  --         { '<C-g>wn', ":<C-u>'<,'>GpWhisperNew<cr>", desc = 'Whisper New' },
  --         { '<C-g>wp', ":<C-u>'<,'>GpWhisperPopup<cr>", desc = 'Whisper Popup' },
  --         { '<C-g>wr', ":<C-u>'<,'>GpWhisperRewrite<cr>", desc = 'Whisper Rewrite' },
  --         { '<C-g>wt', ":<C-u>'<,'>GpWhisperTabnew<cr>", desc = 'Whisper Tabnew' },
  --         { '<C-g>wv', ":<C-u>'<,'>GpWhisperVnew<cr>", desc = 'Whisper Vnew' },
  --         { '<C-g>ww', ":<C-u>'<,'>GpWhisper<cr>", desc = 'Whisper' },
  --         { '<C-g>x', ":<C-u>'<,'>GpContext<cr>", desc = 'Visual GpContext' },
  --       },
  --
  --       -- NORMAL mode mappings
  --       {
  --         mode = { 'n' },
  --         nowait = true,
  --         remap = false,
  --         { '<C-g><C-t>', '<cmd>GpChatNew tabnew<cr>', desc = 'New Chat tabnew' },
  --         { '<C-g><C-v>', '<cmd>GpChatNew vsplit<cr>', desc = 'New Chat vsplit' },
  --         { '<C-g><C-x>', '<cmd>GpChatNew split<cr>', desc = 'New Chat split' },
  --         { '<C-g>a', '<cmd>GpAppend<cr>', desc = 'Append (after)' },
  --         { '<C-g>b', '<cmd>GpPrepend<cr>', desc = 'Prepend (before)' },
  --         { '<C-g>c', '<cmd>GpChatNew<cr>', desc = 'New Chat' },
  --         { '<C-g>f', '<cmd>GpChatFinder<cr>', desc = 'Chat Finder' },
  --         { '<C-g>g', group = 'generate into new ..' },
  --         { '<C-g>ge', '<cmd>GpEnew<cr>', desc = 'GpEnew' },
  --         { '<C-g>gn', '<cmd>GpNew<cr>', desc = 'GpNew' },
  --         { '<C-g>gp', '<cmd>GpPopup<cr>', desc = 'Popup' },
  --         { '<C-g>gt', '<cmd>GpTabnew<cr>', desc = 'GpTabnew' },
  --         { '<C-g>gv', '<cmd>GpVnew<cr>', desc = 'GpVnew' },
  --         { '<C-g>n', '<cmd>GpNextAgent<cr>', desc = 'Next Agent' },
  --         { '<C-g>r', '<cmd>GpRewrite<cr>', desc = 'Inline Rewrite' },
  --         { '<C-g>s', '<cmd>GpStop<cr>', desc = 'GpStop' },
  --         { '<C-g>t', '<cmd>GpChatToggle<cr>', desc = 'Toggle Chat' },
  --         { '<C-g>w', group = 'Whisper' },
  --         { '<C-g>wa', '<cmd>GpWhisperAppend<cr>', desc = 'Whisper Append (after)' },
  --         { '<C-g>wb', '<cmd>GpWhisperPrepend<cr>', desc = 'Whisper Prepend (before)' },
  --         { '<C-g>we', '<cmd>GpWhisperEnew<cr>', desc = 'Whisper Enew' },
  --         { '<C-g>wn', '<cmd>GpWhisperNew<cr>', desc = 'Whisper New' },
  --         { '<C-g>wp', '<cmd>GpWhisperPopup<cr>', desc = 'Whisper Popup' },
  --         { '<C-g>wr', '<cmd>GpWhisperRewrite<cr>', desc = 'Whisper Inline Rewrite' },
  --         { '<C-g>wt', '<cmd>GpWhisperTabnew<cr>', desc = 'Whisper Tabnew' },
  --         { '<C-g>wv', '<cmd>GpWhisperVnew<cr>', desc = 'Whisper Vnew' },
  --         { '<C-g>ww', '<cmd>GpWhisper<cr>', desc = 'Whisper' },
  --         { '<C-g>x', '<cmd>GpContext<cr>', desc = 'Toggle GpContext' },
  --       },
  --
  --       -- INSERT mode mappings
  --       {
  --         mode = { 'i' },
  --         nowait = true,
  --         remap = false,
  --         { '<C-g><C-t>', '<cmd>GpChatNew tabnew<cr>', desc = 'New Chat tabnew' },
  --         { '<C-g><C-v>', '<cmd>GpChatNew vsplit<cr>', desc = 'New Chat vsplit' },
  --         { '<C-g><C-x>', '<cmd>GpChatNew split<cr>', desc = 'New Chat split' },
  --         { '<C-g>a', '<cmd>GpAppend<cr>', desc = 'Append (after)' },
  --         { '<C-g>b', '<cmd>GpPrepend<cr>', desc = 'Prepend (before)' },
  --         { '<C-g>c', '<cmd>GpChatNew<cr>', desc = 'New Chat' },
  --         { '<C-g>f', '<cmd>GpChatFinder<cr>', desc = 'Chat Finder' },
  --         { '<C-g>g', group = 'generate into new ..' },
  --         { '<C-g>ge', '<cmd>GpEnew<cr>', desc = 'GpEnew' },
  --         { '<C-g>gn', '<cmd>GpNew<cr>', desc = 'GpNew' },
  --         { '<C-g>gp', '<cmd>GpPopup<cr>', desc = 'Popup' },
  --         { '<C-g>gt', '<cmd>GpTabnew<cr>', desc = 'GpTabnew' },
  --         { '<C-g>gv', '<cmd>GpVnew<cr>', desc = 'GpVnew' },
  --         { '<C-g>n', '<cmd>GpNextAgent<cr>', desc = 'Next Agent' },
  --         { '<C-g>r', '<cmd>GpRewrite<cr>', desc = 'Inline Rewrite' },
  --         { '<C-g>s', '<cmd>GpStop<cr>', desc = 'GpStop' },
  --         { '<C-g>t', '<cmd>GpChatToggle<cr>', desc = 'Toggle Chat' },
  --         { '<C-g>w', group = 'Whisper' },
  --         { '<C-g>wa', '<cmd>GpWhisperAppend<cr>', desc = 'Whisper Append (after)' },
  --         { '<C-g>wb', '<cmd>GpWhisperPrepend<cr>', desc = 'Whisper Prepend (before)' },
  --         { '<C-g>we', '<cmd>GpWhisperEnew<cr>', desc = 'Whisper Enew' },
  --         { '<C-g>wn', '<cmd>GpWhisperNew<cr>', desc = 'Whisper New' },
  --         { '<C-g>wp', '<cmd>GpWhisperPopup<cr>', desc = 'Whisper Popup' },
  --         { '<C-g>wr', '<cmd>GpWhisperRewrite<cr>', desc = 'Whisper Inline Rewrite' },
  --         { '<C-g>wt', '<cmd>GpWhisperTabnew<cr>', desc = 'Whisper Tabnew' },
  --         { '<C-g>wv', '<cmd>GpWhisperVnew<cr>', desc = 'Whisper Vnew' },
  --         { '<C-g>ww', '<cmd>GpWhisper<cr>', desc = 'Whisper' },
  --         { '<C-g>x', '<cmd>GpContext<cr>', desc = 'Toggle GpContext' },
  --       },
  --     }
  --   end,
  -- },
}
