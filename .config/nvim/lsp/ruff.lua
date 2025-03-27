---@type vim.lsp.Config
return {
    cmd = { 'ruff' },
    filetypes = { 'python' },
    root_markers = { '.git' },
    settings = {
        args = { 'server' },
    },
}
