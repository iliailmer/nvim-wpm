local M = {}

local tracker = require("nvim-wpm.tracker")

local defaults = {
  window_ms = 10000,
  format = "%d wpm",
  lualine_section = "lualine_x",
}

local state = {
  opts = nil,
  tracker = nil,
  timer = nil,
  lualine_wrapped = false,
  lualine_component = nil,
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

local function setup_lualine_integration()
  if state.lualine_wrapped then
    return
  end
  local ok, lualine = pcall(require, "lualine")
  if not ok then
    return
  end
  state.lualine_wrapped = true
  state.lualine_component = state.lualine_component
    or function()
      return M.wpm()
    end

  local original_setup = lualine.setup

  local function inject()
    local config = lualine.get_config()
    local section_name = state.opts.lualine_section
    local section = config.sections[section_name] or {}
    for _, component in ipairs(section) do
      if component == state.lualine_component then
        return
      end
    end
    local new_section = vim.deepcopy(section)
    table.insert(new_section, state.lualine_component)
    original_setup({ sections = { [section_name] = new_section } })
  end

  lualine.setup = function(user_opts)
    original_setup(user_opts)
    inject()
  end

  inject()
end

function M.setup(opts)
  state.opts = vim.tbl_deep_extend("force", defaults, opts or {})
  state.tracker = tracker.new({ window_ms = state.opts.window_ms })

  local group = vim.api.nvim_create_augroup("nvim_wpm", { clear = true })

  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = group,
    callback = function()
      state.tracker:record()
      start_timer()
    end,
  })

  if vim.v.vim_did_enter == 1 then
    setup_lualine_integration()
  else
    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      once = true,
      callback = setup_lualine_integration,
    })
  end
end

function M.wpm()
  if not state.tracker then
    return ""
  end
  return format_wpm(state.tracker:wpm())
end

return M
