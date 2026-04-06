# Config

KojoLib has a built-in config layer that serializes registered controls by `Flag`.

## CreateConfig

```lua
local Config = Library:CreateConfig({
    Folder = "KojoHub",
    Name = "legit",
})
```

## Methods
- `Config:Set(flag, value)`
- `Config:Get(flag)`
- `Config:SetIgnoreFlags({ ... })`
- `Config:IgnoreFlag(flag)`
- `Config:Collect()`
- `Config:Apply(data)`
- `Config:Save(name?)`
- `Config:Load(name?)`
- `Config:Delete(name?)`
- `Config:ListConfigs()`
- `Config:SetAutoload(name?)`
- `Config:GetAutoload()`
- `Config:ClearAutoload()`
- `Config:LoadAutoload()`

## Example

```lua
local Config = Library:CreateConfig({ Folder = "KojoHub", Name = "example" })
Config:SetIgnoreFlags({ "Setting.Menu.Menu Bind" })
Config:Save()
Config:SetAutoload()
Config:LoadAutoload()
```

## Notes
- Controls with `Save = false` are skipped.
- Config loading applies values back through the control setters when available.
