---
name: nvim-dev
description: Use when developing or debugging gloggles.nvim to launch a minimal Neovim instance that loads the plugin and verify changes via remote RPC
allowed-tools: Bash(.claude/skills/nvim-dev/bin/nvim-start:*), Bash(.claude/skills/nvim-dev/bin/nvim-verify:*), Bash(.claude/skills/nvim-dev/bin/nvim-stop:*), Bash(nvim --server *)
---

# Develop gloggles.nvim

Spawn a Neovim instance with a minimal config that loads only `gloggles.nvim` from this repo, then drive it over its `--listen` socket to verify behavior after edits.

## Workflow

```
nvim-start → dynamic checks → nvim-verify → nvim-stop
```

1. Start the server: `.claude/skills/nvim-dev/bin/nvim-start` (prints the socket path).
2. Run change-specific checks using `nvim --server <sock> --remote-expr 'luaeval("...")'`.
3. Run baseline health check: `.claude/skills/nvim-dev/bin/nvim-verify`.
4. **Always** stop the server: `.claude/skills/nvim-dev/bin/nvim-stop` (even if checks fail).

The socket path is stored in `/tmp/gloggles-nvim-dev.state`. The minimal init at `.claude/skills/nvim-dev/minimal_init.lua` prepends the repo to `runtimepath` and calls `require("gloggles").setup({})` — no user config, no other plugins.

**Important:** The spawned Neovim loads Lua files at startup. If you edit a file and need to verify the new version, stop and restart the server (`nvim-stop` then `nvim-start`) so the updated code is loaded. A partial `package.loaded[...] = nil` reload works for some modules but is not reliable for `plugin/gloggles.lua`.

## Dynamic Verification Patterns

Construct `luaeval` queries based on what you changed. Read the socket path from the `nvim-start` output.

**Important:** Always use the literal absolute socket path (e.g., `/tmp/gloggles-nvim-dev-12345.sock`) directly in `nvim --server` commands. Do NOT store it in a shell variable like `$SOCK` — variable expansion triggers `simple_expansion` permission warnings.

### Config changed (`lua/gloggles/config.lua`)

```bash
# Inspect the merged options table
nvim --server /tmp/gloggles-nvim-dev-XXXXX.sock --remote-expr 'luaeval("vim.inspect(require(\"gloggles.config\").options)")'
```

### Command or keymap changed (`plugin/gloggles.lua`)

```bash
# :Gloggles command is registered and range-aware
nvim --server /tmp/gloggles-nvim-dev-XXXXX.sock --remote-expr 'luaeval("vim.api.nvim_get_commands({})[\"Gloggles\"].range")'

# Default <leader>gl visual-mode keymap exists
nvim --server /tmp/gloggles-nvim-dev-XXXXX.sock --remote-expr 'luaeval("vim.fn.maparg(\"<leader>gl\", \"x\") ~= \"\"")'
```

### Highlights changed (`lua/gloggles/highlights.lua`)

```bash
nvim --server /tmp/gloggles-nvim-dev-XXXXX.sock --remote-expr 'luaeval("vim.fn.hlexists(\"GlogglesSubject\")")'
```

### Git parsing changed (`lua/gloggles/git.lua`)

Because the spawned nvim inherits its `cwd` from where `nvim-start` was invoked, run the starter from inside a git repo to exercise `repo_info` / `log_lines`:

```bash
nvim --server /tmp/gloggles-nvim-dev-XXXXX.sock --remote-expr 'luaeval("vim.inspect(require(\"gloggles.git\").repo_info())")'
```

### Viewer logic changed (`lua/gloggles/viewer.lua`)

Open a file and trigger the viewer end-to-end:

```bash
# Open a tracked file (in the cwd the server started from)
nvim --server /tmp/gloggles-nvim-dev-XXXXX.sock --remote-send ':edit README.md<CR>'

# Invoke :Gloggles over an explicit range
nvim --server /tmp/gloggles-nvim-dev-XXXXX.sock --remote-send ':1,10Gloggles<CR>'

# Inspect floating windows that appeared
nvim --server /tmp/gloggles-nvim-dev-XXXXX.sock --remote-expr 'luaeval("#vim.api.nvim_list_wins()")'
```

## When Multiple Files Changed

Verify each changed area, then run `nvim-verify` for the baseline check. Don't skip dynamic checks just because you'll run the baseline — the baseline only covers load-time health.

## Error Handling

- If `nvim-start` fails (exit 2): plugin has a fatal load error. Check the error output, fix, and retry.
- If a `luaeval` query fails: the feature you changed may have a runtime error. The error message from nvim will indicate the problem.
- **Always run `nvim-stop`** at the end, even after failures.
