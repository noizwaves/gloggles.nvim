local config = require("gloggles.config")
local git = require("gloggles.git")
local preview = require("gloggles.preview")
local help = require("gloggles.help")

local M = {}

local SEL_NS = vim.api.nvim_create_namespace("gloggles_selection")

local INACTIVE_WINHL =
  "Normal:GlogglesNormal,NormalFloat:GlogglesNormal,FloatBorder:GlogglesBorder,FloatTitle:GlogglesTitle"
local ACTIVE_WINHL =
  "Normal:GlogglesNormal,NormalFloat:GlogglesNormal,FloatBorder:GlogglesBorderActive,FloatTitle:GlogglesTitleActive"

local function render_commit_list(buf, commits)
  local lines = {}
  local highlights = {}
  local line_to_commit = {}
  local commit_first_line = {}

  for i, c in ipairs(commits) do
    local line1 = c.date .. " " .. c.author
    local base = #lines

    table.insert(lines, line1)
    table.insert(highlights, { base, 0, #c.date, "GlogglesDate" })
    table.insert(highlights, { base, #c.date + 1, #line1, "GlogglesAuthor" })

    table.insert(lines, c.subject)
    table.insert(highlights, { base + 1, 0, #c.subject, "GlogglesSubject" })

    line_to_commit[base + 1] = i
    line_to_commit[base + 2] = i
    commit_first_line[i] = base + 1

    if i < #commits then
      local sep_line = #lines
      table.insert(lines, "")
      line_to_commit[sep_line + 1] = i
    end
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local ns = vim.api.nvim_create_namespace("gloggles")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, hl[4], hl[1], hl[2], hl[3])
  end

  return line_to_commit, commit_first_line
end

-- Layout is computed in terms of inner content sizes; each pane has a
-- rounded border rendered 1 cell outside its content rectangle.
function M.compute_layout(preview_visible)
  local opts = config.get()
  local editor_w = vim.o.columns
  -- reserve space for cmdline + statusline so edge-to-edge (ratio=1.0) fits
  local editor_h = vim.o.lines - vim.o.cmdheight - 1

  local total_w = math.floor(editor_w * opts.ui.width_ratio)
  local total_h = math.floor(editor_h * opts.ui.height_ratio)

  local base_col = math.floor((editor_w - total_w) / 2)
  local base_row = math.floor((editor_h - total_h) / 2)

  local inner_h = total_h - 2
  local list_row = base_row + 1
  local list_col = base_col + 1

  local layout = {
    base_col = base_col,
    base_row = base_row,
    total_w = total_w,
    total_h = total_h,
    inner_h = inner_h,
    list_row = list_row,
    list_col = list_col,
  }

  if preview_visible then
    -- 5 cols of chrome: list border (2) + gap (1) + preview border (2)
    local content_w = total_w - 5
    local list_w = math.max(10, math.floor(content_w * opts.preview.list_width_ratio))
    layout.list_w = list_w
    layout.preview_w = content_w - list_w
    -- preview content sits 3 cells right of list content's right edge
    -- (list right border + gap + preview left border)
    layout.preview_col = list_col + list_w + 3
    layout.preview_row = list_row
  else
    layout.list_w = total_w - 2
  end

  return layout
end

local function create_viewer(commits, git_root, rel_path, start_line, end_line)
  local opts = config.get()
  local layout = M.compute_layout(opts.preview.enabled_by_default)

  local list_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[list_buf].buftype = "nofile"
  vim.bo[list_buf].swapfile = false

  local list_win = vim.api.nvim_open_win(list_buf, true, {
    relative = "editor",
    width = layout.list_w,
    height = layout.inner_h,
    col = layout.list_col,
    row = layout.list_row,
    style = "minimal",
    border = "rounded",
    title = opts.ui.list_title,
    title_pos = "center",
    zindex = 50,
  })
  vim.wo[list_win].wrap = false
  vim.wo[list_win].cursorline = false
  vim.wo[list_win].winhighlight = ACTIVE_WINHL

  local diff_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[diff_buf].buftype = "nofile"
  vim.bo[diff_buf].swapfile = false
  vim.bo[diff_buf].filetype = "diff"

  local state = {
    list_buf = list_buf,
    list_win = list_win,
    diff_buf = diff_buf,
    diff_win = nil,
    commits = commits,
    git_root = git_root,
    rel_path = rel_path,
    start_line = start_line,
    end_line = end_line,
    current_commit_idx = 0,
    autocmd_id = nil,
    preview_visible = false,
    help_visible = false,
    layout = layout,
  }

  local line_to_commit, commit_first_line = render_commit_list(list_buf, commits)
  state.line_to_commit = line_to_commit
  state.commit_first_line = commit_first_line

  local function set_selection(idx)
    vim.api.nvim_buf_clear_namespace(list_buf, SEL_NS, 0, -1)
    local first = commit_first_line[idx]
    if not first then
      return
    end
    for _, ln in ipairs({ first, first + 1 }) do
      vim.api.nvim_buf_set_extmark(list_buf, SEL_NS, ln - 1, 0, {
        line_hl_group = "GlogglesSelection",
      })
    end
  end
  state.set_selection = set_selection

  if #commits > 0 then
    state.current_commit_idx = 1
    set_selection(1)
    preview.update_diff_preview(diff_buf, commits[1])
  end

  -- Hide the character cursor while the commit list is focused; the full-row
  -- selection highlight stands in for the cursor position.
  local saved_guicursor = vim.o.guicursor
  vim.opt.guicursor = "a:GlogglesHiddenCursor"
  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = list_buf,
    callback = function()
      vim.opt.guicursor = "a:GlogglesHiddenCursor"
    end,
  })
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = list_buf,
    callback = function()
      vim.o.guicursor = saved_guicursor
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = list_buf,
    once = true,
    callback = function()
      vim.o.guicursor = saved_guicursor
    end,
  })

  if opts.preview.enabled_by_default then
    preview.toggle(state)
  end

  state.autocmd_id = vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = list_buf,
    callback = function()
      local cursor_line = vim.api.nvim_win_get_cursor(list_win)[1]
      local idx = line_to_commit[cursor_line]
      if idx and idx ~= state.current_commit_idx then
        state.current_commit_idx = idx
        set_selection(idx)
        if state.preview_visible and state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
          preview.update_diff_preview(diff_buf, commits[idx])
          vim.api.nvim_win_set_cursor(state.diff_win, { 1, 0 })
        end
      end
    end,
  })

  -- Active-border highlight: swap winhighlight on focus change.
  local tracked_wins = function()
    local wins = { state.list_win }
    if state.diff_win then
      table.insert(wins, state.diff_win)
    end
    if state.help_win then
      table.insert(wins, state.help_win)
    end
    return wins
  end

  local win_enter_id = vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      local cur = vim.api.nvim_get_current_win()
      for _, w in ipairs(tracked_wins()) do
        if vim.api.nvim_win_is_valid(w) then
          vim.wo[w].winhighlight = (w == cur) and ACTIVE_WINHL or INACTIVE_WINHL
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = list_buf,
    once = true,
    callback = function()
      pcall(vim.api.nvim_del_autocmd, win_enter_id)
    end,
  })

  local pr_base_url = git.get_pr_base_url(git_root)

  local function jump_commit(direction)
    local target = state.current_commit_idx + direction
    if target >= 1 and target <= #commits then
      local line = commit_first_line[target]
      if line then
        vim.api.nvim_win_set_cursor(list_win, { line, 0 })
        state.current_commit_idx = target
        set_selection(target)
        if state.preview_visible and state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
          preview.update_diff_preview(diff_buf, commits[target])
          vim.api.nvim_win_set_cursor(state.diff_win, { 1, 0 })
        end
      end
    end
  end

  local kopts = { buffer = list_buf, nowait = true }
  vim.keymap.set("n", "<Esc>", function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative ~= "" then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end, kopts)
  vim.keymap.set("n", "j", function()
    jump_commit(1)
  end, kopts)
  vim.keymap.set("n", "k", function()
    jump_commit(-1)
  end, kopts)
  vim.keymap.set("n", "p", function()
    preview.toggle(state)
  end, kopts)
  vim.keymap.set("n", "h", function()
    help.toggle(state)
  end, kopts)

  vim.keymap.set("n", "<CR>", function()
    local c = commits[state.current_commit_idx]
    if not c then
      return
    end
    if c.pr_number and pr_base_url then
      vim.ui.open(pr_base_url .. c.pr_number)
      return
    end
    local url = git.get_commit_url(git_root, c.hash)
    if url then
      vim.ui.open(url)
    else
      vim.notify("No remote URL configured", vim.log.levels.WARN)
    end
  end, kopts)

  vim.keymap.set("n", "c", function()
    local cmd = string.format("git log -L %d,%d:%s", start_line, end_line, rel_path)
    vim.fn.setreg("+", cmd)
    vim.fn.setreg("*", cmd)
    vim.notify("Copied git log command to clipboard", vim.log.levels.INFO)
  end, kopts)

  vim.cmd("stopinsert")
  return state
end

function M.open(start_line, end_line)
  local git_root, rel_path = git.repo_info()
  if not rel_path then
    vim.notify("File is not tracked by git", vim.log.levels.WARN)
    return
  end

  local commits, err = git.log_lines(rel_path, start_line, end_line)
  if not commits then
    vim.notify("git log failed: " .. (err or ""), vim.log.levels.ERROR)
    return
  end
  if #commits == 0 then
    vim.notify("No commits found for these lines", vim.log.levels.INFO)
    return
  end

  create_viewer(commits, git_root, rel_path, start_line, end_line)
end

function M.open_for_visual_selection()
  local v_start = vim.fn.getpos("v")[2]
  local v_end = vim.fn.getpos(".")[2]
  local start_line = math.min(v_start, v_end)
  local end_line = math.max(v_start, v_end)

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

  M.open(start_line, end_line)
end

function M.open_for_range(line1, line2)
  M.open(line1, line2)
end

return M
