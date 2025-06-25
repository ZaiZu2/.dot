return {
    {
        'folke/snacks.nvim',
        opts = {
            image = { enabled = true },
            scroll = {
                animate = {
                    duration = { step = 5, total = 100 },
                    easing = 'linear',
                },
            },
            picker = { enabled = true },
        },
    },
}
