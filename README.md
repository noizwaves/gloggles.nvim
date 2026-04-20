# gloggles.nvim

A viewer for `git log -L` (line history) in Neovim. Select lines, press a key, and browse every commit that touched them — with an inline diff preview and one-keystroke jumps to the pull request or commit on GitHub.

![Preview](https://i.imgur.com/HTbQfWi.gif)

## Requirements

- Neovim 0.10+
- `git`
- A GitHub `origin` remote (optional — only needed for PR/commit browser links)

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "noizwaves/gloggles.nvim",
  opts = {},
}
```

## Usage

Select lines in visual mode and press `<leader>gl`, or run `:Gloggles` with a range:

```
:'<,'>Gloggles
```

### Inside the viewer

| Key     | Action                           |
| ------- | -------------------------------- |
| `j`/`k` | Next / previous commit           |
| `p`     | Toggle the diff preview pane     |
| `<CR>`  | Open the PR on GitHub (falls back to the commit if there is no PR) |
| `c`     | Copy the underlying `git log -L` command to the system clipboard |
| `h`     | Toggle the key reference overlay |
| `<Esc>` | Close the viewer                 |

## Help

Run `:help gloggles` inside Neovim to open the bundled help page, which mirrors this README and is kept in `doc/gloggles.txt`.

Inside the viewer, press `h` to toggle an overlay that lists the available keys without leaving the window.

## Configuration

`setup` is optional — defaults are applied automatically. See [`lua/gloggles/config.lua`](lua/gloggles/config.lua) for the full default table. To override:

```lua
require("gloggles").setup({
  keymap = "<leader>gl",        -- set to false to disable the default keymap
  preview = {
    enabled_by_default = true,
    list_width_ratio = 0.3,     -- commit list takes 30% of the viewer width
  },
  ui = {
    title = "Gloggles (git line history)",
    backdrop_margin = 4,
  },
})
```

To disable the default keymap before the plugin loads:

```lua
vim.g.gloggles_no_default_keymap = 1
```

## Highlights

All highlight groups are defined with `default = true` so your colorscheme takes precedence:

- `GlogglesDate` — commit date (links to `Special`)
- `GlogglesAuthor` — commit author (links to `Identifier`)
- `GlogglesSubject` — commit subject (links to `Comment`)
- `GlogglesPR` — pull request number (links to `Type`)
- `GlogglesHelp` — help overlay text (links to `Comment`)
- `GlogglesHelpKey` — help overlay keys (links to `Special`)

## Development

Dev tooling (`stylua`, `lefthook`) is pinned in `.mise.toml`. With [mise](https://mise.jdx.dev/) installed, run `mise install` to get both.

After cloning, wire up the pre-commit hook so Lua changes are formatted automatically:

```
lefthook install
```

The hook is configured in `.lefthook.yml` and runs `stylua` on staged `*.lua` files, re-staging the formatted output.

## License

MIT
