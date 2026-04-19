local M = {}

local defaults = {
  keymap = "<leader>gl",
  preview = {
    enabled_by_default = true,
    list_width_ratio = 0.3,
  },
  ui = {
    title = "Gloggles (git line history)",
    backdrop_margin = 4,
  },
}

M.options = vim.deepcopy(defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

function M.get()
  return M.options
end

return M
