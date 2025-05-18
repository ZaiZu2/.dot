---@type vim.lsp.Config
return {
    cmd = { 'basedpyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = { '.git', 'pyproject.toml' },
    settings = {
        basedpyright = {
            analysis = {
                autoImportCompletions = true,
                autoSearchPaths = true,
                diagnosticMode = 'openFilesOnly', -- or "workspace"
                diagnosticSeverityOverrides = {
                    -- https://github.com/microsoft/pyright/blob/main/docs/configuration.md#type-check-diagnostics-settings
                    -- reportUndefinedVariable = 'none',
                },
                exclude = {},
                extraPaths = {},
                ignore = {},
                include = {},
                inlayHints = {
                    callArgumentNames = true,
                    functionReturnTypes = true,
                    genericTypes = false,
                    variableTypes = true,
                },
                logLevel = 'Information', -- "Error" | "Warning" | "Information" | "Trace"
                -- stubPath = 'typings',
                typeCheckingMode = 'off', -- or "off", "basic", "strict"
                typeshedPaths = {},
                useLibraryCodeForTypes = false,
                useTypingExtensions = false,
            },
            disableLanguageServices = false,
            disableOrganizeImports = false,
            disablePullDiagnostics = false,
            disableTaggedHints = false,
            importStrategy = 'fromEnvironment', -- or "node", "python"
        },
        python = {
            pythonPath = 'python',
            venvPath = '',
        },
    },
}
