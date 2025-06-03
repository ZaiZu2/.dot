---@type vim.lsp.Config
return {
    cmd = { 'typescript-language-server', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
    root_markers = { '.git' },
    settings = {},
    init_options = { hostInfo = 'neovim' },
}
