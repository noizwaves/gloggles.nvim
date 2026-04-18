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

  if state.preview_visible then
    if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
      vim.api.nvim_win_close(state.diff_win, true)
    end
    state.diff_win = nil
    vim.api.nvim_win_set_width(state.list_win, state.inner_w)
    state.preview_visible = false
    return
  end

  local list_w = math.floor(state.inner_w * opts.preview.list_width_ratio)
  local diff_w = state.inner_w - list_w - 1
  vim.api.nvim_win_set_width(state.list_win, list_w)

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
    width = diff_w,
    height = state.inner_h,
    col = state.inner_col + list_w + 1,
    row = state.inner_row,
    style = "minimal",
    border = { "", "", "", "", "", "", "", "│" },
    zindex = 50,
  })
  vim.wo[state.diff_win].wrap = false

  local c = state.commits[state.current_commit_idx]
  if c then
    M.update_diff_preview(diff_buf, c)
  end

  state.preview_visible = true
  vim.api.nvim_set_current_win(state.list_win)
end

return M
