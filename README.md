# gloggles.nvim

A viewer for `git log -L` (line history) in Neovim. Select lines, press a key, and browse every commit that touched them — with an inline diff preview and one-keystroke jumps to the pull request or commit on GitHub.

## Requirements

- Neovim 0.10+
- `git`
- A GitHub `origin` remote (optional — only needed for PR/commit browser links)

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "noizwaves/gloggles.nvim",
  keys = {
    { "<leader>gl", mode = "x", desc = "Gloggles: line history" },
  },
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
| `<CR>`  | Open the PR on GitHub            |
| `o`     | Open the commit on GitHub        |
| `h`     | Toggle the key reference overlay |
| `<Esc>` | Close the viewer                 |

## Configuration

`setup` is optional — defaults are applied automatically. To override:

```lua
require("gloggles").setup({
  keymap = "<leader>gl",        -- set to false to disable the default keymap
  preview = {
    enabled_by_default = true,
    list_width_ratio = 0.3,     -- commit list takes 30% of the viewer width
  },
  ui = {
    title = " git log -L (line history) ",
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

## License

MIT
