# Installation

## GitHub layout

Recommended repo root:
- `KojoLib.lua`
- `KojoExtended.lua`
- `SaveManager.lua`
- `ThemeManager.lua`
- `Example.lua`
- `README.md`
- `API.md`
- `docs/`

## Raw URLs

Use raw GitHub URLs, not `github.com/.../blob/...` URLs.

Correct pattern:

```lua
local repo = "https://raw.githubusercontent.com/norr17/Ui/main/"
```

## Consumer script model

`Example.lua` is the file you paste into the executor. It is not the library itself.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/norr17/Ui/main/Example.lua"))()
```

## Manual loading

```lua
local repo = "https://raw.githubusercontent.com/norr17/Ui/main/"

local Library = loadstring(game:HttpGet(repo .. "KojoLib.lua"))()
local Extended = loadstring(game:HttpGet(repo .. "KojoExtended.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

Library:UseExtended(Extended)
```

## Important lifecycle rule

Loading `KojoLib.lua` only returns the `Library` table. No UI is created until you call `Library:CreateWindow(...)`.
