return {
    -- So far snacks.image is much faster
    -- {
    --     "3rd/image.nvim",
    --     build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
    --     opts = {
    --         processor = "magick_cli",
    --         markdown = {
    --             enabled = true,
    --             clear_in_insert_mode = false,
    --             download_remote_images = true,
    --             only_render_image_at_cursor = true,
    --             only_render_image_at_cursor_mode = "popup", -- or "inline"
    --             floating_windows = false,                   -- if true, images will be rendered in floating markdown windows
    --             filetypes = { "markdown", "vimwiki" },      -- markdown extensions (ie. quarto) can go here
    --         },
    --     },
    -- },
    {
        'HakonHarnes/img-clip.nvim',
        event = 'VeryLazy',
        opts = {
            default = {
                dir_path = vim.fn.getenv('ZK_NOTEBOOK_DIR') .. "/images",
                extension = "avif",
                use_absolute_path = false,
                relative_to_current_file = false,
            },
        },
        keys = {
            { '<leader>p', '<cmd>PasteImage<cr>', desc = 'Paste image from system clipboard' },
        },
    },
}
