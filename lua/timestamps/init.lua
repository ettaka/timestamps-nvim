local M = {}

local parser = require("timestamps.parser")

M.config = {
  insert_mappings = true, -- also map <leader>ts in insert and terminal mode
}

--- Define the plugin's keymaps from M.config. Called by plugin/timestamps.lua and by setup(), so the
--- result is the same whichever runs first.
function M.apply_keymaps()
  local actions = require("timestamps.actions")
  vim.keymap.set("n", "<leader>ts", actions.paste_timestamp_now, { desc = "Insert timestamp" })
  for _, mode in ipairs({ "i", "t" }) do
    if M.config.insert_mappings then
      vim.keymap.set(mode, "<leader>ts", actions.paste_timestamp_now, { desc = "Insert timestamp" })
    else
      pcall(vim.keymap.del, mode, "<leader>ts")
    end
  end
end

--- setup({ home_tz = "+02:00", home_summer_tz = "+03:00", insert_mappings = true })
function M.setup(opts)
  opts = opts or {}
  parser.setup(opts)
  if opts.insert_mappings ~= nil then
    M.config.insert_mappings = opts.insert_mappings
  end
  if M.plugin_loaded then
    M.apply_keymaps()
  end
end

return M
