.PHONY: test

DEPS_DIR := .tests/site/pack/deps/start
PLENARY := $(DEPS_DIR)/plenary.nvim

test: $(PLENARY)
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/nvim-wpm { minimal_init = 'tests/minimal_init.lua' }"

$(PLENARY):
	mkdir -p $(DEPS_DIR)
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY)
