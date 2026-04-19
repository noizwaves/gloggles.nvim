local config = require("gloggles.config")

local M = {}

function M.update_diff_preview(buf, commit)
  vim.bo[buf].modifiable = true
  if not commit or #commit.diff_lines == 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "No diff available for this commit" })
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, commit.diff_lines)
  end
  vim.bo[buf].modifiable = false
end

function M.toggle(state)
  local opts = config.get()
  local viewer = require("gloggles.viewer")

  if state.preview_visible then
    if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
      vim.api.nvim_win_close(state.diff_win, true)
    end
    state.diff_win = nil
    state.preview_visible = false

    local layout = viewer.compute_layout(false)
    state.layout = layout
    if vim.api.nvim_win_is_valid(state.list_win) then
      vim.api.nvim_win_set_config(state.list_win, {
        relative = "editor",
        width = layout.list_w,
        height = layout.inner_h,
        col = layout.list_col,
        row = layout.list_row,
      })
    end
    return
  end

  local layout = viewer.compute_layout(true)
  state.layout = layout

  if vim.api.nvim_win_is_valid(state.list_win) then
    vim.api.nvim_win_set_config(state.list_win, {
      relative = "editor",
      width = layout.list_w,
      height = layout.inner_h,
      col = layout.list_col,
      row = layout.list_row,
    })
  end

  local diff_buf = state.diff_buf
  if not vim.api.nvim_buf_is_valid(diff_buf) then
    diff_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[diff_buf].buftype = "nofile"
    vim.bo[diff_buf].swapfile = false
    vim.bo[diff_buf].filetype = "diff"
    state.diff_buf = diff_buf
  end

  state.diff_win = vim.api.nvim_open_win(diff_buf, false, {
    relative = "editor",
    width = layout.preview_w,
    height = layout.inner_h,
    col = layout.preview_col,
    row = layout.preview_row,
    style = "minimal",
    border = "rounded",
    title = opts.ui.preview_title,
    title_pos = "center",
    zindex = 50,
  })
  vim.wo[state.diff_win].wrap = false
  vim.wo[state.diff_win].winhighlight =
    "Normal:GlogglesNormal,NormalFloat:GlogglesNormal,FloatBorder:GlogglesBorder,FloatTitle:GlogglesTitle"

  local c = state.commits[state.current_commit_idx]
  if c then
    M.update_diff_preview(diff_buf, c)
  end

  state.preview_visible = true
  vim.api.nvim_set_current_win(state.list_win)
end

return M
