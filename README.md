# git-show.nvim AKA WhoWroteWhat

Show the full commit that last touched the line under your cursor, without
leaving Neovim.

`git blame` tells you *which* commit changed a line; this plugin goes one step
further and opens the whole `git show` output for that commit (message, author,
date and complete diff) in a floating window, with `diff` syntax highlighting.

## Requirements

- Neovim 0.5+
- `git`

## Installation

### Paq

```lua
require "paq" {
    "Panky-codes/git-show.nvim",
}
```

### lazy.nvim

```lua
{ "Panky-codes/git-show.nvim" }
```

### vim-plug

```vim
Plug 'Panky-codes/git-show.nvim'
```

### Native packages

```sh
git clone https://github.com/Panky-codes/git-show.nvim \
    ~/.local/share/nvim/site/pack/plugins/start/git-show.nvim
```

No `setup()` call is needed; the plugin is loaded from `plugin/gitshow.lua`.
You can also call it from Lua with `require("gitshow").show()`.

## Usage

Put the cursor on any line of a file tracked by git and either:

- press `<M-C-G>` (Alt+Ctrl+G) in normal mode, or
- run `:call WhoWroteWhat()`

A floating window, half the width and height of the editor, opens with the
`git show` output of the commit that last modified that line. The buffer is
read-only and shows line numbers. Close it with `:q` (or `:close`).

### Custom mapping

The default mapping is defined with `nmap <M-C-G>`. To use a different key, add
your own mapping to your config:

```lua
vim.keymap.set("n", "<leader>gs", "<cmd>call WhoWroteWhat()<CR>", { silent = true })
```

## How it works

For the current buffer and cursor line, the plugin runs (directly, without a
shell, from the file's directory):

```sh
git --no-pager blame --root --porcelain --contents - -L <line>,+1 -- <file>
```

The buffer's current contents are fed on stdin (`--contents -`), so unsaved
edits don't shift line numbers. It reads the commit hash from the first line
of the porcelain output and runs:

```sh
git --no-pager show <hash>
```

The output is shown in a read-only scratch buffer (`filetype=diff`) that is
wiped when the window is closed.

`--root` makes sure root commits are not reported as boundary commits.

If something goes wrong, the error is shown with `vim.notify` instead of an
empty window: lines that are not committed yet, files outside a git
repository, and buffers that are not files.

## License

GPL-2.0. See [LICENSE](LICENSE).
