local config = require("gloggles.config")

local M = {}

local help_entries = {
  { "j/k", "navigate commits" },
  { "p", "toggle diff preview" },
  { "Enter", "open PR / commit in browser" },
  { "c", "copy git log command to clipboard" },
  { "h", "toggle this help" },
  { "Esc", "close" },
}

function M.toggle(state)
  local opts = config.get()

  if state.help_visible then
    if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
      vim.api.nvim_win_close(state.help_win, true)
    end
    if state.help_buf and vim.api.nvim_buf_is_valid(state.help_buf) then
      vim.api.nvim_buf_delete(state.help_buf, { force = true })
    end
    state.help_win = nil
    state.help_buf = nil
    state.help_visible = false
    if vim.api.nvim_win_is_valid(state.list_win) then
      vim.api.nvim_set_current_win(state.list_win)
    end
    return
  end

  local lines = {}
  local highlights = {}
  local max_w = 0
  for _, entry in ipairs(help_entries) do
    local line = "  " .. entry[1] .. "  " .. entry[2] .. "  "
    table.insert(lines, line)
    if #line > max_w then
      max_w = #line
    end
    local key_end = 2 + #entry[1]
    table.insert(highlights, { #lines - 1, 2, key_end, "GlogglesHelpKey" })
    table.insert(highlights, { #lines - 1, key_end + 2, #line, "GlogglesHelp" })
  end

  local help_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[help_buf].buftype = "nofile"
  vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, lines)
  vim.bo[help_buf].modifiable = false

  local ns = vim.api.nvim_create_namespace("gloggles_help")
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(help_buf, ns, hl[4], hl[1], hl[2], hl[3])
  end

  local editor_w = vim.o.columns
  local editor_h = vim.o.lines
  local width = math.max(max_w, #opts.ui.help_title + 4)
  local height = #lines
  local col = math.floor((editor_w - width) / 2) - 1
  local row = math.floor((editor_h - height) / 2) - 1

  local help_win = vim.api.nvim_open_win(help_buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = opts.ui.help_title,
    title_pos = "center",
    zindex = 60,
  })
  vim.wo[help_win].winhighlight =
    "Normal:GlogglesNormal,NormalFloat:GlogglesNormal,FloatBorder:GlogglesBorder,FloatTitle:GlogglesTitle"

  state.help_buf = help_buf
  state.help_win = help_win
  state.help_visible = true

  if vim.api.nvim_win_is_valid(state.list_win) then
    vim.api.nvim_set_current_win(state.list_win)
  end
end

return M
