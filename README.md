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
  window_ms = 10000,  -- rolling window size, in milliseconds (default 10000)
  format = "%d wpm",  -- string.format template, or a function(n: number): string
})
```

Then call `require("nvim-wpm").wpm()` from any statusline. For
[lualine](https://github.com/nvim-lualine/lualine.nvim):

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
