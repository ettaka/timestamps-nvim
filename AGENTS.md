# timestamps-nvim — agent guide

Parses and inserts ISO-8601 timestamps with a required zone suffix (`Z`, `H` = home TZ, or `±hh:mm`). It has no dependencies, and both pkb-nvim and calendar-nvim depend on it.

This plugin is one part of the PKB stack (`timestamps-nvim` ← `pkb-nvim` ← `calendar-nvim`, wired together by
`toolsrc/nvim-lua`). The cross-repo guide covers the note-tag format, the module map, the test harness, the git
workflow and the rules that keep earlier bugs fixed. It lives in toolsrc at `pkb-dev/AGENTS.md`, which is `~/pkb-dev/AGENTS.md` in the dev
workspace. **Read it before changing anything here.**

Quick reference:
- Test: `make test` (headless, `tests/*_spec.lua`, runner in `tests/run.lua`; `FILTER=...`, `PKB_TEST_VERBOSE=1`).
  Add or change a test for every behaviour you change. A known bug is marked `t.xfail(...)`: write the failing
  test first, fix the code, then turn the `xfail` into `test` (the runner reports XPASS until you do).
- Cross-repo smoke test: `~/pkb-dev/toolsrc/pkb-dev/test/run.sh`.
- Try it in the real editor: `PKB_DEV_DIR=~/pkb-dev nvim`.
- Git: `origin` is `/srv/git/timestamps-nvim.git`. Push topic branches there; the owner pushes to GitHub.
- `parse_iso` is the format contract for every `due::`, `done::` and `old::` tag in the user's notes. Keep it backward compatible.
- Do not define PKB commands or `require("pkb...")` here: timestamps-nvim must not depend on pkb-nvim.
- Zone suffixes `Z`, `H` (+02:00) and `S` (+03:00) are fixed offsets; `H`/`S` are configurable in `setup()`.
