local ThemeManager = {}
ThemeManager.__index = ThemeManager

local Presets = {
    Default = {
        Accent = Color3.fromRGB(148, 100, 220),
        AccentLight = Color3.fromRGB(175, 130, 245),
        AccentDark = Color3.fromRGB(110, 72, 175),
    },
    Rose = {
        Accent = Color3.fromRGB(230, 110, 160),
        AccentLight = Color3.fromRGB(245, 150, 190),
        AccentDark = Color3.fromRGB(180, 72, 120),
    },
    Emerald = {
        Accent = Color3.fromRGB(70, 190, 135),
        AccentLight = Color3.fromRGB(110, 225, 170),
        AccentDark = Color3.fromRGB(45, 130, 92),
    },
    Amber = {
        Accent = Color3.fromRGB(230, 170, 80),
        AccentLight = Color3.fromRGB(245, 205, 120),
        AccentDark = Color3.fromRGB(175, 120, 45),
    },
}

function ThemeManager:SetLibrary(library)
    self.Library = library
    return self
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
    return self
end

function ThemeManager:GetThemes()
    return Presets
end

function ThemeManager:ApplyTheme(name)
    local theme = Presets[name]
    if theme and self.Library then
        self.Library:SetTheme(theme)
        self.CurrentTheme = name
        return true
    end
    return false
end

function ThemeManager:BuildGroup(target)
    assert(self.Library, "ThemeManager library not set")

    local group
    if target.AddLeftGroupbox then
        group = target:AddLeftGroupbox("Themes")
    else
        group = target
    end

    local dropdown = group:AddDropdown("ThemePreset", {
        Text = "Preset",
        Values = { "Default", "Rose", "Emerald", "Amber" },
        Default = self.CurrentTheme or "Default",
        Save = false,
        Callback = function(value)
            self:ApplyTheme(value)
        end,
    })

    group:AddColorPicker("ThemeAccent", {
        Text = "Accent",
        Flag = "Theme.Accent",
        Default = self.Library:GetTheme().Accent,
        Save = false,
        Callback = function(color)
            self.Library:SetTheme({ Accent = color })
        end,
    })

    group:AddButton({
        Text = "Reset Theme",
        Func = function()
            dropdown:SetValue("Default")
            self:ApplyTheme("Default")
        end,
    })

    return group
end

function ThemeManager:ApplyToTab(tab)
    return self:BuildGroup(tab)
end

function ThemeManager:ApplyToGroupbox(group)
    return self:BuildGroup(group)
end

return setmetatable({
    Folder = "KojoHub",
    CurrentTheme = "Default",
}, ThemeManager)
