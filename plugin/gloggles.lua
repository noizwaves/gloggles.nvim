if vim.fn.has("nvim-0.10") ~= 1 then
  vim.notify("gloggles.nvim requires Neovim 0.10 or newer", vim.log.levels.ERROR)
  return
end

if vim.g.loaded_gloggles == 1 then
  return
end
vim.g.loaded_gloggles = 1

require("gloggles.highlights").setup()

vim.api.nvim_create_user_command("Gloggles", function(args)
  require("gloggles.viewer").open_for_range(args.line1, args.line2)
end, { range = true })

if vim.g.gloggles_no_default_keymap ~= 1 then
  local keymap = require("gloggles.config").get().keymap
  if type(keymap) == "string" and keymap ~= "" then
    vim.keymap.set("x", keymap, function()
      require("gloggles.viewer").open_for_visual_selection()
    end, { desc = "Gloggles: line history (git log -L)" })
  end
end
