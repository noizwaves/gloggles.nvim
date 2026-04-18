local M = {}

function M.setup(opts)
  require("gloggles.config").setup(opts)
end

return setmetatable(M, {
  __index = function(_, k)
    return require("gloggles.viewer")[k]
  end,
})
