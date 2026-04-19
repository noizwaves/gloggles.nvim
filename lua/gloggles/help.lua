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
    vim.api.nvim_set_current_win(state.list_win)
    return
  end

  local lines = {}
  local highlights = {}
  for _, entry in ipairs(help_entries) do
    local line = "  " .. entry[1] .. "  " .. entry[2]
    table.insert(lines, line)
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

  local help_win = vim.api.nvim_open_win(help_buf, false, {
    relative = "editor",
    width = state.inner_w,
    height = #lines,
    col = state.inner_col,
    row = state.inner_row,
    style = "minimal",
    border = { "", "", "", "", "─", "─", "─", "" },
    zindex = 60,
  })

  state.help_buf = help_buf
  state.help_win = help_win
  state.help_visible = true

  vim.api.nvim_set_current_win(state.list_win)
end

return M
