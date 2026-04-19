# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`gloggles.nvim` is a Neovim plugin (Lua, Neovim 0.10+) that wraps `git log -L` to show the commit history of a selected line range in a floating viewer, with a diff preview and GitHub PR/commit links.

## Commands

- Format: `stylua lua/ plugin/` (config in `stylua.toml` — 2-space indent, 120-col, double quotes).
- There is no test suite or build step. Manual testing is done by loading the plugin in Neovim and running `:Gloggles` on a visual range.

## Architecture

Entry points:
- `plugin/gloggles.lua` — runs on plugin load: sets highlights, registers the `:Gloggles` user command (range-aware), and binds the default `<leader>gl` visual-mode keymap unless `vim.g.gloggles_no_default_keymap` is set.
- `lua/gloggles/init.lua` — exposes `setup()` and lazily proxies other calls to `viewer`.

Module responsibilities (all under `lua/gloggles/`):
- `config.lua` — default options table and `setup()` merge.
- `git.lua` — shells out to `git log -L` with a custom `COMMIT_SEP`/`Hash:`/`Date:`/`Author:`/`Subject:` format, parses the stream into commit records (subject → `pr_number` via `Merge pull request #N` or trailing `(#N)`), and builds GitHub URLs from the `origin` remote.
- `viewer.lua` — builds the floating UI: a backdrop window, a commit-list buffer, and a lazily-created diff preview window. Owns state (current commit index, preview/help visibility), buffer-local keymaps (`j`/`k`/`p`/`h`/`<CR>`/`o`/`<Esc>`), and the `CursorMoved` autocmd that syncs the preview.
- `preview.lua` — toggles the diff window and re-renders the diff buffer from the selected commit's `diff_lines`.
- `help.lua` — floating key-reference overlay.
- `highlights.lua` — `default = true` highlight links (`GlogglesDate`, `GlogglesAuthor`, `GlogglesSubject`, `GlogglesPR`, `GlogglesHelp`, `GlogglesHelpKey`).

Key flow: visual selection → `viewer.open_for_visual_selection` → `git.repo_info` + `git.log_lines` → `create_viewer` renders the list, wires keymaps, and (optionally) opens the preview. The commit list is a `nofile` buffer; line-to-commit mapping is maintained in `line_to_commit` / `commit_first_line` tables so `j`/`k` and cursor moves stay in sync with the preview.

## Docs

User-facing docs live in `README.md` and `doc/gloggles.txt` (the `:help gloggles` page). When you change anything user-visible — default keys, config options in `lua/gloggles/config.lua`, commands, or highlight groups — update all three in the same change: `README.md`, `doc/gloggles.txt`, and this `CLAUDE.md`. The help file and README should stay mirrored in content; `CLAUDE.md` only needs updating when the architecture notes above drift.
