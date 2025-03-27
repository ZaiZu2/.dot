---@type vim.lsp.Config
return {
    cmd = { 'basedpyright', '--stdio' },
    filetypes = { 'python' },
    root_markers = { '.git' },
    settings = {
        basedpyright = {
            disableOrganizeImports = true, -- Using Ruff
            disableTaggedHints = false,
            analysis = {
                diagnosticSeverityOverrides = {
                    -- https://github.com/microsoft/pyright/blob/main/docs/configuration.md#type-check-diagnostics-settings
                    reportUndefinedVariable = 'none',
                },
                typeCheckingMode = 'standard',
                autoImportCompletions = true,
                -- autoSearchPaths = true,
                diagnosticMode = 'openFilesOnly',
                useLibraryCodeForTypes = false,
                -- inlayHints = {
                --     variableTypes = true,
                --     callArgumentNames = true,
                --
                -- }
            },
        },
    },
}
