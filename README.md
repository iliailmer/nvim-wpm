# nvim-wpm

Live typing speed (WPM) for your Neovim statusline.

## Requirements

Requires Neovim >= 0.10 (for `vim.uv`).

## Install

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "iliailmer/nvim-wpm",
  opts = {},
}
```

## Usage

```lua
require("nvim-wpm").setup({
  window_ms = 10000,              -- rolling window size, in milliseconds (default 10000)
  format = "%d wpm",              -- string.format template, or a function(n: number): string
  lualine_section = "lualine_x",  -- which lualine section to auto-inject into (default lualine_x)
})
```

### lualine

If [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) is installed,
nvim-wpm automatically adds itself to `sections.lualine_x` (configurable via
`lualine_section`) — no edits to your lualine config needed, regardless of
whether lualine or nvim-wpm's `setup()` runs first.

If lualine is loaded lazily by your plugin manager on a trigger that fires
*after* Neovim's `VimEnter` (e.g. a keybinding or command), auto-integration
won't detect it in time. In that case, or for any other statusline, wire `wpm()`
in manually:

```lua
require("lualine").setup({
  sections = {
    lualine_x = { function() return require("nvim-wpm").wpm() end },
  },
})
```

## How it works

Every `InsertCharPre` keystroke is timestamped. `wpm()` counts keystrokes in the
trailing `window_ms` window, divides by 5 (the standard "1 word = 5 characters"
convention), and scales to a per-minute rate. As keystrokes age out of the
window, the displayed rate decays toward 0 within `window_ms` of you stopping
typing.

## Testing

```bash
make test
```
