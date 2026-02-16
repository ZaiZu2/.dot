return {
    lsps = {
        lua_ls = {
            settings = {
                Lua = { runtime = { version = 'LuaJIT' } },
            },
        },
        ruff = {
            settings = { args = { 'server' } },
        },
        pyrefly = {
            settings = {
                python = { pyrefly = { displayTypeErrors = 'force-off' } },
            },
        },
        ts_ls = {
            init_options = { hostInfo = 'neovim' },
        },
        html = {
            init_options = {
                configurationSection = { 'html', 'css', 'javascript' },
                embeddedLanguages = { css = true, javascript = true },
                provideFormatter = true,
            },
        },
        yamlls = {
            settings = {
                redhat = {
                    telemetry = { enabled = false },
                    yaml = { format = { printWidth = 100 } },
                },
            },
        },
        bashls = {},
        taplo = {},
        dockerls = {},
        docker_compose_language_service = {},
        marksman = {},
        -- jinja_lsp = {},
    },
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
                    cwd = vim.fn.getcwd,
                    redirectOutput = true,
                },
                {
                    name = 'Debug with external code',
                    program = '${file}',
                    type = 'python',
                    request = 'launch',
                    justMyCode = false,
                    showReturnValue = true,
                    cwd = vim.fn.getcwd,
                    redirectOutput = true,
                },
                {
                    name = 'Debug all',
                    program = '${file}',
                    type = 'python',
                    request = 'launch',
                    justMyCode = false,
                    showReturnValue = true,
                    cwd = vim.fn.getcwd,
                    redirectOutput = true,
                    django = true,
                    gevent = true,
                    pyramid = true,
                    jinja = true,
                },
                {
                    name = 'Attach all',
                    program = '${file}',
                    type = 'python',
                    request = 'attach',
                    connect = {
                        host = 'localhost', -- or '127.0.0.1'
                        port = 5678, -- default debugpy port
                    },
                    console = 'externalTerminal',
                    justMyCode = false,
                    showReturnValue = true,
                    cwd = vim.fn.getcwd,
                    redirectOutput = true,
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
                    stream = 'stdout',
                    ignore_exitcode = true,
                    env = nil,
                    parser = function(output, bufnr, linter_cwd)
                        local success, output_obj = pcall(vim.json.decode, output)
                        if not success then
                            return {}
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
            -- pyrefly = function()
            --     return {
            --         cmd = 'pyrefly',
            --         stdin = false,
            --         append_fname = true,
            --         args = { 'check', '--output-format', 'json', '--color', 'never' },
            --         stream = 'stdout',
            --         ignore_exitcode = true,
            --         env = nil,
            --         parser = function(output, bufnr, linter_cwd)
            --             -- Strip trailing non-JSON lines (e.g. "INFO 1 error")
            --             local json_str = output:match '^(%b{})'
            --             if not json_str then
            --                 return {}
            --             end
            --             local success, output_obj = pcall(vim.json.decode, json_str)
            --             if not success or not output_obj.errors then
            --                 return {}
            --             end
            --
            --             local nvim_severity = vim.diagnostic.severity
            --             local severity_map = {
            --                 warning = nvim_severity.WARN,
            --                 error = nvim_severity.ERROR,
            --                 info = nvim_severity.INFO,
            --             }
            --
            --             local diagnostics = {}
            --             for _, err in ipairs(output_obj.errors) do
            --                 table.insert(diagnostics, {
            --                     bufnr = bufnr,
            --                     lnum = err.line - 1,
            --                     end_lnum = err.stop_line - 1,
            --                     col = err.column - 1,
            --                     end_col = err.stop_column - 1,
            --                     severity = severity_map[err.severity] or nvim_severity.ERROR,
            --                     message = err.description,
            --                     source = 'pyrefly',
            --                     code = err.name,
            --                 })
            --             end
            --             return diagnostics
            --         end,
            --     }
            -- end,
        },
    },
    formatters = {
        ft = {
            lua = { 'stylua' },
            python = { 'ruff' },
            bash = { 'shfmt' },
            zsh = { 'shfmt' },
            sh = { 'shfmt' },
            jinja = { 'djlint' },
            javascript = { 'prettier' },
            typescript = { 'prettier' },
            json = { 'prettier' },
            html = { 'prettier' },
            css = { 'prettier' },
            yaml = { 'prettier' },
            yml = { 'prettier' },
            markdown = { 'prettier' },
            toml = { 'taplo' },
        },
        config = {
            stylua = {
                args = { '--config-path' }, -- CLI arg for injecting fmt config
                conf_files = { 'stylua.toml', '.stylua.toml' }, -- All files which might be used for local fmt config
                filename = 'stylua.toml', -- Name of the default global fmt config file
            },
            ruff = {
                args = { '--config' },
                conf_files = { 'ruff.toml', 'pyproject.toml' },
                filename = 'ruff.toml',
            },
            ['markdownlint-cli2'] = {
                args = { '--config' },
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
                args = { '--config' },
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
                args = { '--config' },
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
            taplo = {
                args = { '--config' },
                conf_files = { '.taplo.toml', 'taplo.toml' },
                filename = '.taplo.toml',
            },
        },
    },
}
