-- plugin/: timestamps-nvim must not define pkb-nvim's commands (known issue 10 in the PKB guide).
local H = require("tests.helpers")
local t = H.suite()

local function pkb_commands()
  return vim.tbl_filter(function(name) return name:match("^PKB") end, vim.tbl_keys(vim.api.nvim_get_commands({})))
end

t.test("plugin files define no PKB commands", function()
  for _, name in ipairs(pkb_commands()) do vim.api.nvim_del_user_command(name) end
  for _, f in ipairs(vim.fn.glob(H.root .. "/plugin/*.lua", false, true)) do vim.cmd.source(f) end
  H.eq(pkb_commands(), {})
end)

t.test("there is no plugin/pkb.lua shadowing pkb-nvim's", function()
  H.eq(vim.fn.filereadable(H.root .. "/plugin/pkb.lua"), 0)
end)

return t
