# nvim-wpm design

## Summary

A Neovim plugin that tracks live typing speed (words per minute) and exposes
it as a formatted string for statusline plugins (e.g. lualine) to display.
v1 scope: rolling WPM calculation + statusline integration only. No
persistence/history in v1 (may be added later as a separate design).

## Algorithm

- WPM = `(characters_typed_in_window / 5) / (window_ms / 60000)`, the
  standard "1 word = 5 characters" convention.
- Only `InsertCharPre` events count as keystrokes. Backspace/delete are
  ignored in v1 (no extra autocmds).
- A rolling window (default 10s, configurable) is used: as old keystrokes
  age out of the window, WPM naturally decays toward 0 within `window_ms`
  of the user stopping typing. No special-cased idle logic is needed for
  this — it falls out of the window math.

## Modules

- `lua/nvim-wpm/tracker.lua` — pure logic, no Neovim API calls except an
  injectable clock (defaults to `vim.uv.now()`).
  - Stores keystroke timestamps in a plain Lua array used as a queue
    (append on write, drop from the front on prune). At realistic typing
    speeds and a 10s window this never grows large, so no need for a more
    complex ring buffer structure.
  - `record(timestamp?)` — records a keystroke.
  - `wpm(timestamp?)` — prunes timestamps older than `window_ms` from the
    front of the queue, then returns the numeric WPM.
  - Takes `window_ms` as construction/config input (no module-level global
    state beyond the queue itself, to keep it independently testable).

- `lua/nvim-wpm/init.lua` — public API and Neovim wiring.
  - `setup(opts)` — merges `opts` with defaults, registers the
    `InsertCharPre` autocmd (calls `tracker.record()`), and owns the timer
    lifecycle. Nothing runs until `setup()` is called explicitly — no
    `plugin/` autoload file.
  - `wpm()` — returns the formatted string for statusline consumption.

- No `plugin/` directory in v1: this plugin has no meaningful behavior
  before `setup()` is called, so there's nothing to autoload.

## Timer strategy

A perpetual background timer for the whole Neovim session is wasteful and
unnecessary. Instead:

- The timer starts lazily on the first keystroke after being idle.
- While running, it ticks every 1s and calls `vim.cmd('redrawstatus')` so
  the statusline reflects decay even without further keystrokes.
- It stops itself once `wpm()` naturally decays to 0 (the window is empty).
- It restarts on the next keystroke after being idle.

This keeps idle Neovim sessions free of background timer work while still
making the decay-to-0 behavior visible on screen.

## Public API

```lua
require('nvim-wpm').setup(opts)  -- starts tracking; opts optional
require('nvim-wpm').wpm()        -- returns formatted string, e.g. "42 wpm"
```

No lualine-specific component is exposed in v1 — `wpm()` is a plain string
function usable from lualine, a manual `statusline` string, or anywhere
else, with no dependency on lualine.

## Config

`setup(opts)`, all fields optional:

- `window_ms` (number, default `10000`) — rolling window size in
  milliseconds.
- `format` (string or function, default `"%d wpm"`) — either a format
  string passed to `string.format(format, wpm_number)`, or a
  `function(wpm_number): string` for full control over rendering.

No other config in v1 (e.g. no minimum-character threshold to suppress
low-confidence readings) — keep the surface minimal, add later if needed.

## Testing

`plenary.nvim` busted-style specs under `tests/nvim-wpm/`, targeting
`tracker.lua` only, since it's pure and takes an injectable clock. No need
to simulate real Neovim autocmds or timers for these tests.

Cases to cover:
- Empty window → `wpm() == 0`.
- Keystrokes within the window → correct WPM value.
- Keystrokes aging out of the window → WPM decays correctly.
- Custom `window_ms` changes the computed rate as expected.

## File layout

```
nvim-wpm/
  lua/nvim-wpm/
    init.lua
    tracker.lua
  tests/nvim-wpm/
    tracker_spec.lua
  README.md
```

## Out of scope (v1)

- Session/history persistence (flat log or SQLite) — deferred, may become
  its own design later.
- Backspace/deletion-aware keystroke counting.
- A dedicated lualine component table — `wpm()` alone covers integration.
- Configurable minimum-character threshold before displaying a value.
