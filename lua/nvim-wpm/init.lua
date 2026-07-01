local M = {}

local tracker = require("nvim-wpm.tracker")

local defaults = {
  window_ms = 10000,
  format = "%d wpm",
}

local state = {
  opts = nil,
  tracker = nil,
  timer = nil,
}

local function format_wpm(n)
  local fmt = state.opts.format
  if type(fmt) == "function" then
    return fmt(n)
  end
  return string.format(fmt, n)
end

local function stop_timer()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

local function start_timer()
  if state.timer then
    return
  end
  state.timer = vim.uv.new_timer()
  state.timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      if state.tracker:wpm() == 0 then
        stop_timer()
      end
      vim.cmd("redrawstatus")
    end)
  )
end

function M.setup(opts)
  state.opts = vim.tbl_deep_extend("force", defaults, opts or {})
  state.tracker = tracker.new({ window_ms = state.opts.window_ms })

  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = vim.api.nvim_create_augroup("nvim_wpm", { clear = true }),
    callback = function()
      state.tracker:record()
      start_timer()
    end,
  })
end

function M.wpm()
  if not state.tracker then
    return ""
  end
  return format_wpm(state.tracker:wpm())
end

return M
