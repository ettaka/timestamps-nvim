# timestamps

A simple Neovim plugin for handling timestamps

## Timestamps

`YYYY-MM-DDTHH:MM` followed by a zone suffix. Every suffix is a fixed offset, whatever the date:

| Suffix | Offset | Meaning |
|---|---|---|
| `Z` | `+00:00` | UTC |
| `H` | `+02:00` | home standard time (Finland, winter) |
| `S` | `+03:00` | home summer time (Finland, summer) |
| `+hh:mm` / `-hh:mm` | as written | any other offset |

New timestamps get the suffix for the UTC offset at that moment: `H` in Finnish winter, `S` in summer.

## Setup

Optional; these are the defaults:

```lua
require("timestamps").setup({
  home_tz = "+02:00",        -- what H means
  home_summer_tz = "+03:00", -- what S means
  insert_mappings = true,    -- also map <leader>ts in insert and terminal mode
})
```

## Tests

```sh
make test                        # or: nvim --clean -l tests/run.lua
make test FILTER=parse_iso       # only tests whose "file: name" contains the filter
make test NVIM_BIN=/path/to/nvim
```

Tests live in `tests/*_spec.lua` and use the small runner in `tests/run.lua` (no dependencies). They run
headless with `TZ=Europe/Helsinki` (override with `PKB_TEST_TZ`). `t.xfail(...)` marks a known bug: the case must
fail, and the run fails with XPASS once the bug is fixed, so the marker is removed together with the fix.
