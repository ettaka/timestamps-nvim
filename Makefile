# Not NVIM: inside a Neovim :terminal $NVIM is the parent server socket.
NVIM_BIN ?= nvim

# make test [FILTER=substring]   run the headless test suite (see tests/run.lua)
test:
	$(NVIM_BIN) --clean -l tests/run.lua $(FILTER)

.PHONY: test
