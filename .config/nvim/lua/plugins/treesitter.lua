return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects', 'nvim-treesitter/nvim-treesitter-context' },
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'vim', 'vimdoc', 'python', 'javascript', 'typescript', 'tsx' },
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    config = function(_, opts)
      -- Prefer git instead of curl in order to improve connectivity in some environments
      require('nvim-treesitter.install').prefer_git = true
      ---@diagnostic disable-next-line: missing-fields

      -- :help nvim-treesitter
      local config = vim.tbl_extend('force', opts, {
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['am'] = { query = '@function.outer', desc = '[m]ethod' },
              ['im'] = { query = '@function.inner', desc = '[m]ethod' },
              ['ac'] = { query = '@class.outer', desc = '[c]lass' },
              ['ic'] = { query = '@class.inner', desc = '[c]lass' },
              ['ah'] = { query = '@block.outer', desc = '[h]unk (block)' },
              ['ih'] = { query = '@block.inner', desc = '[h]unk (block)' },
              ['if'] = { query = '@call.inner', desc = '[f]unction call' },
              ['af'] = { query = '@call.outer', desc = '[f]unction call' },
              ['iP'] = { query = '@parameter.inner', desc = '[P]arameter' },
              ['aP'] = { query = '@parameter.outer', desc = '[P]arameter' },
              ['ia'] = { query = '@attribute.inner', desc = '[a]ttribute' },
              ['aa'] = { query = '@attribute.outer', desc = '[a]ttribute' },
            },
          },
        },
      })
      require('nvim-treesitter.configs').setup(config)

      require('treesitter-context').setup {
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
        separator = nil,
        zindex = 20,
        on_attach = nil,
      }
    end,
  },
}
