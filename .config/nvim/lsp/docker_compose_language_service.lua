---@type vim.lsp.Config
return {
    cmd = { 'docker_compose_language_service' },
    filetypes = { 'docker-compose' },
    root_markers = { '.git' },
    settings = {},
}
