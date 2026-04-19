local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, "GlogglesDate", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "GlogglesAuthor", { link = "Identifier", default = true })
  vim.api.nvim_set_hl(0, "GlogglesSubject", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "GlogglesPR", { link = "Type", default = true })
  vim.api.nvim_set_hl(0, "GlogglesHelp", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "GlogglesHelpKey", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "GlogglesNormal", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "GlogglesSelection", { link = "CursorLine", default = true })
  vim.api.nvim_set_hl(0, "GlogglesHiddenCursor", { reverse = true, blend = 100, default = true })
  vim.api.nvim_set_hl(0, "GlogglesBorder", { link = "FloatBorder", default = true })
  vim.api.nvim_set_hl(0, "GlogglesBorderActive", { link = "Constant", default = true })
  vim.api.nvim_set_hl(0, "GlogglesTitle", { link = "FloatTitle", default = true })
  vim.api.nvim_set_hl(0, "GlogglesTitleActive", { link = "Constant", default = true })
end

return M
