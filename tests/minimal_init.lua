vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.getcwd() .. "/.tests/site/pack/deps/start/plenary.nvim")
vim.cmd("runtime plugin/plenary.vim")
