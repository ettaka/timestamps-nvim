local M = {}

local parser = require("timestamps.parser")

function M.setup(opts)
  opts = opts or {}
  parser.setup(opts)
end

return M
