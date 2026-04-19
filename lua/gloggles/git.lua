local M = {}

function M.extract_pr_number(subject)
  local pr = subject:match("Merge pull request #(%d+)")
  if pr then
    return pr
  end
  pr = subject:match("#(%d+)%)")
  return pr
end

local function parse_remote(git_root)
  local remote = vim.fn.systemlist("git -C " .. vim.fn.shellescape(git_root) .. " remote get-url origin")[1]
  if not remote or remote == "" then
    return nil
  end
  local owner, repo = remote:match("github%.com[:/]([^/]+)/(.+)")
  if not owner then
    return nil
  end
  repo = repo:gsub("%.git$", ""):gsub("/$", "")
  return owner, repo
end

function M.get_pr_base_url(git_root)
  local owner, repo = parse_remote(git_root)
  if not owner then
    return nil
  end
  return string.format("https://github.com/%s/%s/pull/", owner, repo)
end

function M.get_commit_url(git_root, hash)
  local owner, repo = parse_remote(git_root)
  if not owner then
    return nil
  end
  return string.format("https://github.com/%s/%s/commit/%s", owner, repo, hash)
end

function M.parse_log_output(raw_lines)
  local commits = {}
  local current = nil

  for _, line in ipairs(raw_lines) do
    if line == "COMMIT_SEP" then
      if current then
        table.insert(commits, current)
      end
      current = { hash = "", date = "", author = "", subject = "", pr_number = nil, diff_lines = {} }
    elseif current then
      local hash = line:match("^Hash: (.+)")
      local date = line:match("^Date: (.+)")
      local author = line:match("^Author: (.+)")
      local subject = line:match("^Subject: (.+)")

      if hash then
        current.hash = hash
      elseif date then
        current.date = date
      elseif author then
        current.author = author
      elseif subject then
        current.subject = subject
        current.pr_number = M.extract_pr_number(subject)
      else
        table.insert(current.diff_lines, line)
      end
    end
  end

  if current then
    table.insert(commits, current)
  end

  for _, c in ipairs(commits) do
    while #c.diff_lines > 0 and c.diff_lines[1] == "" do
      table.remove(c.diff_lines, 1)
    end
  end

  return commits
end

function M.log_lines(rel_path, start_line, end_line)
  local cmd = string.format(
    'git --no-pager log --format="COMMIT_SEP%%nHash: %%H%%nDate: %%as%%nAuthor: %%an%%nSubject: %%s" --no-color -L %d,%d:%s',
    start_line,
    end_line,
    rel_path
  )
  local raw = vim.fn.systemlist(cmd, nil)
  if vim.v.shell_error ~= 0 then
    return nil, table.concat(raw, "\n")
  end
  return M.parse_log_output(raw), nil
end

function M.repo_info()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  local rel_path = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(vim.fn.expand("%:p")))[1]
  if not rel_path or rel_path == "" then
    return nil, nil
  end
  return git_root, rel_path
end

return M
