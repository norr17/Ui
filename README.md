# KojoLib

KojoLib is a Roblox client-side UI library. It uses Kojo's own design and component behavior. The documentation structure here is inspired by Obsidian-style docs, but the library itself is not Obsidian.

## Lifecycle

Loading `KojoLib.lua` only returns the `Library` object. It does not create UI by itself.

```lua
local Library = loadstring(readfile("KojoLib.lua"))()
-- nothing appears yet
```

UI appears only after a bootstrap call such as `Library:CreateWindow(...)`, `Library:CreateLoading(...)`, `Library:CreateWatermark(...)`, or `Library:Notify(...)`.

## Quick Start

```lua
local Library = loadstring(readfile("KojoLib.lua"))()
local Extended = loadstring(readfile("KojoExtended.lua"))()
Library:UseExtended(Extended)

local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Width = 780,
    Height = 520,
    Icon = "rbxassetid://4483362458",
})

local Tab = Window:AddTab("Main")
local Section = Tab:AddSection("Features", "Left")
Section:AddToggle("Enabled", {
    Default = false,
    Flag = "Main.Features.Enabled",
})
```

## Docs

- `API.md` - compact API index.
- `Example.lua` - executable showcase.
- `docs/index.md` - docs entry.
- `docs/installation.md` - setup and bootstrap.
- `docs/getting-started.md` - first window/tab/section.
- `docs/window.md` - window lifecycle and tab creation.
- `docs/sections.md` - section model and common control options.
- `docs/config.md` - save/load/autoload.
- `docs/theme.md` - theme overrides.
- `docs/utilities.md` - watermark, FPS, anti-AFK, movement helpers.
- `docs/extended.md` - additive widgets from `KojoExtended.lua`.
- `docs/elements/*.md` - per-element usage.

## Files

- `KojoLib.lua` - core library and canonical source of truth.
- `KojoExtended.lua` - optional additive widgets only.
- `Example.lua` - full showcase.
- `Example.txt` - short note that points to `Example.lua`.

## Design note

KojoLib keeps Kojo's own UI design. These docs only borrow the structure of a mature docs site so setup and features are easier to discover.
