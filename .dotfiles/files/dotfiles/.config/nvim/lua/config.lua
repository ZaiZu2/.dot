return {
    daps = {
        python = {
            name = 'debugpy',
            config = {
                -- https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
                {
                    name = 'Debug own code',
                    program = '${file}',
                    type = 'python',
                    request = 'launch',
                    justMyCode = true,
                    showReturnValue = true,
                },
                {
                    name = 'Debug with external code',
                    program = '${file}',
                    type = 'python',
                    request = 'launch',
                    justMyCode = false,
                    showReturnValue = true,
                },
                {
                    name = 'Debug all configs',
                    program = '${file}',
                    type = 'python',
                    request = 'launch',
                    justMyCode = false,
                    showReturnValue = true,
                    django = true,
                    gevent = true,
                    pyramid = true,
                    jinja = true,
                },
            },
        },
    },
    linters = {
        ft = {
            shell = { 'shellcheck' },
            bash = { 'shellcheck' },
            zsh = { 'shellcheck' },
            dockerfile = { 'hadolint' },
            markdown = { 'markdownlint-cli2' },
            yaml = { 'yamllint' },
            jinja = { 'djlint' },
            python = { 'basedpyright' },
        },
        -- https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#custom-linters
        custom = {
            basedpyright = function()
                local project_dir = vim.fs.root(0, {
                    'pyrightconfig.json',
                    'pyproject.toml',
                    'setup.cfg',
                    'setup.py',
                    '.git',
                }) or vim.fn.getcwd(0)

                return {
                    cmd = 'basedpyright',
                    stdin = false,
                    append_fname = true,
                    args = { '--outputjson', '--project', project_dir },
                    stream = 'both',
                    ignore_exitcode = true,
                    env = nil,
                    parser = function(output, bufnr, linter_cwd)
                        local success, output_obj = pcall(vim.json.decode, output)
                        if not success then
                            vim.print('Unexpected JSON response from Basedpyright linter', vim.log.levels.ERROR)
                            vim.print(output)
                            return
                        end

                        local nvim_severity = vim.diagnostic.severity
                        local severity_map = {
                            warning = nvim_severity.WARN,
                            error = nvim_severity.ERROR,
                            info = nvim_severity.INFO,
                        }

                        local diagnostics = {}
                        for _, pyright_diag in ipairs(output_obj.generalDiagnostics) do
                            local nvim_diag = {
                                bufnr = bufnr,
                                lnum = pyright_diag.range.start.line,
                                end_lnum = pyright_diag.range['end'].line,
                                col = pyright_diag.range.start.character,
                                end_col = pyright_diag.range['end'].character,
                                severity = severity_map[pyright_diag.severity],
                                message = pyright_diag.message,
                                source = 'basedpyright',
                                code = pyright_diag.rule,
                            }
                            table.insert(diagnostics, nvim_diag)
                        end
                        return diagnostics
                    end,
                }
            end,
        },
    },
    formatters = {
        ft = {
            lua = { 'stylua' },
            python = { 'ruff_format' },
            markdown = { 'markdownlint-cli2' },
            bash = { 'shmft' },
            zsh = { 'shmft' },
            sh = { 'shmft' },
            jinja = { 'djlint' },
            javascript = { 'prettier' },
            typescript = { 'prettier' },
            html = { 'prettier' },
            css = { 'prettier' },
            yaml = { 'prettier' },
            yml = { 'prettier' },
        },
        config = {
            stylua = {
                arg = '--config-path', -- CLI arg for injecting fmt config
                conf_files = { 'stylua.toml', '.stylua.toml' }, -- All files which might be used for local fmt config
                filename = 'stylua.toml', -- Name of the default global fmt config file
            },
            ruff_format = {
                arg = '--config',
                conf_files = { 'ruff.toml', 'pyproject.toml' },
                filename = 'ruff.toml',
            },
            ['markdownlint-cli2'] = {
                arg = '--config',
                conf_files = {
                    '.markdownlint-cli2.jsonc',
                    '.markdownlint-cli2.yaml',
                    '.markdownlint-cli2.cjs',
                    '.markdownlint-cli2.mjs',
                    '.markdownlint.jsonc',
                    '.markdownlint.json',
                    '.markdownlint.yaml',
                    '.markdownlint.yml',
                    '.markdownlint.cjs',
                    '.markdownlint.mjs',
                    'package.json',
                },
                filename = '.markdownlint.yaml',
            },
            prettierd = {
                arg = '--config',
                conf_files = {
                    -- 2. .prettierrc file (JSON or YAML)
                    '.prettierrc',
                    -- 3. Specific JSON/YAML files
                    '.prettierrc.json',
                    '.prettierrc.yml',
                    '.prettierrc.yaml',
                    '.prettierrc.json5',
                    -- 4. JavaScript/TypeScript files (export default or module.exports)
                    '.prettierrc.js',
                    'prettier.config.js',
                    '.prettierrc.ts',
                    'prettier.config.ts',
                    -- 5. ES Module files (export default)
                    '.prettierrc.mjs',
                    'prettier.config.mjs',
                    '.prettierrc.mts',
                    'prettier.config.mts',
                    -- 6. CommonJS files (module.exports)
                    '.prettierrc.cjs',
                    'prettier.config.cjs',
                    '.prettierrc.cts',
                    'prettier.config.cts',
                    -- 7. TOML file
                    '.prettierrc.toml',
                },
                filename = '.prettierrc',
            },
            prettier = {
                arg = '--config',
                conf_files = {
                    -- 2. .prettierrc file (JSON or YAML)
                    '.prettierrc',
                    -- 3. Specific JSON/YAML files
                    '.prettierrc.json',
                    '.prettierrc.yml',
                    '.prettierrc.yaml',
                    '.prettierrc.json5',
                    -- 4. JavaScript/TypeScript files (export default or module.exports)
                    '.prettierrc.js',
                    'prettier.config.js',
                    '.prettierrc.ts',
                    'prettier.config.ts',
                    -- 5. ES Module files (export default)
                    '.prettierrc.mjs',
                    'prettier.config.mjs',
                    '.prettierrc.mts',
                    'prettier.config.mts',
                    -- 6. CommonJS files (module.exports)
                    '.prettierrc.cjs',
                    'prettier.config.cjs',
                    '.prettierrc.cts',
                    'prettier.config.cts',
                    -- 7. TOML file
                    '.prettierrc.toml',
                },
                filename = '.prettierrc',
            },
        },
    },
}
