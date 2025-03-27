---@type vim.lsp.Config
return {
    cmd = { 'bash-language-server' },
    filetypes = { 'bash', 'sh', 'zsh' },
    root_markers = { '.git' },
    settings = {},
}
