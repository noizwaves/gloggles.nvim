local M = {}

local defaults = {
  keymap = "<leader>gl",
  preview = {
    enabled_by_default = true,
    list_width_ratio = 0.3,
  },
  ui = {
    width_ratio = 1.0,
    height_ratio = 1.0,
    list_title = " Commits ",
    preview_title = " Preview ",
    help_title = " Help ",
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
