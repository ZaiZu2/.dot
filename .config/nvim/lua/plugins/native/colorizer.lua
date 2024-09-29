return {
  {
    'norcalli/nvim-colorizer.lua',
    config = function() -- BUG: Colorizer fails to attach to opened buffers by default
      local colorizer = require 'colorizer'
      colorizer.setup()
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
        callback = function(args)
          colorizer.attach_to_buffer(args.buf)
        end,
      })
    end,
  },
}
