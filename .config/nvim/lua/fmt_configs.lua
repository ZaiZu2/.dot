return {
    ft_configs = {
        lua = { 'stylua' },
        python = { 'ruff_format' },
        markdown = { 'markdownlint-cli2' },
        javascript = { 'prettier', 'prettierd' },
        html = { 'prettierd', 'prettierd' },
        typescript = { 'prettier' },
        bash = { 'shmft' },
        zsh = { 'shmft' },
        sh = { 'shmft' },
    },
    fmtr_configs = {
        stylua = {
            arg = '--config-path', -- CLI arg for injecting fmt config
            conf_files = { 'stylua.toml' }, -- All files which might be used for local fmt config
            filename = 'stylua.toml', -- Name of the default global fmt config file
        },
        ruff_format = {
            arg = '--config',
            conf_files = { 'ruff.toml', 'pyproject.toml' },
            filename = 'ruff.toml',
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
}
