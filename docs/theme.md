# Theme

KojoLib currently exposes theme overrides directly through the library. It does not ship a separate ThemeManager file.

## Read the theme

```lua
local theme = Library:GetTheme()
print(theme.Accent)
```

## Override theme values

```lua
Library:SetTheme({
    Accent = Color3.fromRGB(230, 110, 160),
    TextPrimary = Color3.fromRGB(240, 240, 245),
})
```

## Notes
- `SetTheme` only applies keys that already exist in the internal theme table.
- It is best used for palette customization, not for changing layout geometry.
