local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, "GlogglesDate", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "GlogglesAuthor", { link = "Identifier", default = true })
  vim.api.nvim_set_hl(0, "GlogglesSubject", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "GlogglesPR", { link = "Type", default = true })
  vim.api.nvim_set_hl(0, "GlogglesHelp", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "GlogglesHelpKey", { link = "Special", default = true })
end

return M
