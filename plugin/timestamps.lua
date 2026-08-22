local actions = require('timestamps.actions')
local parser = require('timestamps.parser')
vim.keymap.set({"n", "i", "t"}, "<leader>ts", function() actions.paste_timestamp_now(parser.local_tz_suffix()) end, { desc = "Insert timestamp" })
