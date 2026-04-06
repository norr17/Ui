# KojoExtended

`KojoExtended.lua` is optional. It is not merged into core automatically.

## Setup

```lua
local Library = loadstring(readfile("KojoLib.lua"))()
local Extended = loadstring(readfile("KojoExtended.lua"))()
Library:UseExtended(Extended)
```

## What lives in KojoExtended

Only additive section widgets:
- `AddTable`
- `AddSearchBox`
- `AddSubTabs`
- `AddToggleLock`

Core-owned systems stay in `KojoLib.lua`:
- config
- watermark
- FPS counter
- anti-AFK
- movement helpers
- click teleport
- tooltip system
- theme overrides

## Why it is separate

This keeps `KojoLib.lua` as the real core and avoids duplicate systems fighting each other.
