# Installation

## Local files

```lua
local Library = loadstring(readfile("KojoLib.lua"))()
local Extended = loadstring(readfile("KojoExtended.lua"))()
Library:UseExtended(Extended)
```

## Remote files

```lua
local repo = getgenv().KojoRepo
local Library = loadstring(game:HttpGet(repo .. "KojoLib.lua"))()
local Extended = loadstring(game:HttpGet(repo .. "KojoExtended.lua"))()
Library:UseExtended(Extended)
```

`KojoRepo` must end with `/`.

## Important lifecycle rule

Loading `KojoLib.lua` only returns the `Library` table. No UI is created until you call a bootstrap method, usually `Library:CreateWindow(...)`.
