local this = debug.getinfo(1, "S").source:sub(2)
local repo_root = vim.fn.fnamemodify(this, ":p:h:h:h:h")

vim.opt.runtimepath:prepend(repo_root)
vim.opt.packpath = vim.o.runtimepath

vim.cmd("runtime! plugin/gloggles.lua")

require("gloggles").setup({})
