---@type vim.lsp.Config
return {
    cmd = { 'docker-langserver' },
    filetypes = { 'Dockerfile' },
    root_markers = { '.git' },
    settings = {},
}
