local comment_syntax = {
    c = {
        single = { '//' },
        multi = { '/*', '*/' },
    },
    python = {
        single = { '#' },
        multi = nil,
    },
    javascript = {
        single = { '//' },
        multi = { '/*', '*/' },
    },
    go = {
        single = { '//' },
        multi = { '/*', '*/' },
    },
    java = {
        single = { '//' },
        multi = { '/*', '*/' },
    },
    cpp = {
        single = { '//' },
        multi = { '/*', '*/' },
    },
    ruby = {
        single = { '#' },
        multi = nil,
    },
    html = {
        single = nil,
        multi = { '<!--', '-->' },
    },
    css = {
        single = nil,
        multi = { '/*', '*/' },
    },
    sh = {
        single = { '#' },
        multi = nil,
    },
}

return comment_syntax
