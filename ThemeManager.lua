local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.__index = ThemeManager

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = deepCopy(item)
    end
    return copy
end

local function colorToTable(color)
    return {
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5),
    }
end

local function tableToColor(value)
    if type(value) ~= "table" then
        return Color3.new(1, 1, 1)
    end
    return Color3.fromRGB(value[1] or 255, value[2] or 255, value[3] or 255)
end

local function listJsonNames(folder)
    if not listfiles then
        return {}
    end
    local ok, files = pcall(listfiles, folder)
    if not ok or type(files) ~= "table" then
        return {}
    end
    local names = {}
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)%.json$")
        if name then
            names[#names + 1] = name
        end
    end
    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    return names
end

function ThemeManager:SetLibrary(library)
    self.Library = library
    return self
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
    return self
end

function ThemeManager:GetPaths()
    local paths = {}
    local parts = tostring(self.Folder or ""):split("/")
    for index = 1, #parts do
        local path = table.concat(parts, "/", 1, index)
        if path ~= "" then
            paths[#paths + 1] = path
        end
    end
    return paths
end

function ThemeManager:BuildFolderTree()
    if not makefolder then
        return
    end
    for _, path in ipairs(self:GetPaths()) do
        if path ~= "" and (not isfolder or not isfolder(path)) then
            pcall(makefolder, path)
        end
    end
end

function ThemeManager:CheckFolderTree()
    self:BuildFolderTree()
end

function ThemeManager:Register(name, theme)
    self.Library:RegisterTheme(name, theme)
    return self
end

function ThemeManager:Apply(name)
    return self.Library:ApplyTheme(name)
end

function ThemeManager:ApplyTheme(name)
    return self:Apply(name)
end

function ThemeManager:List()
    local names = {}
    for name in pairs(self.Library.Themes) do
        names[#names + 1] = name
    end
    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    return names
end

function ThemeManager:Save(name)
    if not writefile then
        return false, "writefile_unavailable"
    end
    if not name or tostring(name):gsub("%s+", "") == "" then
        return false, "invalid_name"
    end
    self:CheckFolderTree()
    local path = self.Folder .. "/" .. tostring(name) .. ".json"
    local payload = {}
    for token, color in pairs(self.Library.Theme) do
        payload[token] = colorToTable(color)
    end
    writefile(path, HttpService:JSONEncode(payload))
    self.Library:RegisterTheme(name, self.Library.Theme)
    return true, path
end

function ThemeManager:Load(name)
    if not readfile or not isfile then
        return false, "readfile_unavailable"
    end
    local path = self.Folder .. "/" .. tostring(name) .. ".json"
    if not isfile(path) then
        return false, "theme_not_found"
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok then
        return false, "decode_error"
    end
    local theme = {}
    for token, value in pairs(decoded) do
        theme[token] = tableToColor(value)
    end
    self.Library:RegisterTheme(name, theme)
    return self.Library:ApplyTheme(name)
end

function ThemeManager:Delete(name)
    if not delfile then
        return false, "delfile_unavailable"
    end
    local path = self.Folder .. "/" .. tostring(name) .. ".json"
    if isfile and not isfile(path) then
        return false, "theme_not_found"
    end
    local ok = pcall(delfile, path)
    return ok, ok and path or "delete_failed"
end

function ThemeManager:ReloadCustomThemes()
    self:CheckFolderTree()
    return listJsonNames(self.Folder)
end

function ThemeManager:_buildThemeControls(groupbox)
    local function syncThemePickers()
        if self.Library.Options.ThemeManager_Accent then
            self.Library.Options.ThemeManager_Accent:SetValueRGB(self.Library.Theme.Accent, nil, true)
        end
        if self.Library.Options.ThemeManager_Text then
            self.Library.Options.ThemeManager_Text:SetValueRGB(self.Library.Theme.Text, nil, true)
        end
        if self.Library.Options.ThemeManager_SubText then
            self.Library.Options.ThemeManager_SubText:SetValueRGB(self.Library.Theme.SubText, nil, true)
        end
        if self.Library.Options.ThemeManager_BuiltinList and self.Library.Themes[self.Library.ThemeName] then
            self.Library.Options.ThemeManager_BuiltinList:SetValue(self.Library.ThemeName, true)
        end
    end

    groupbox:AddLabel("Accent"):AddColorPicker("ThemeManager_Accent", {
        Default = self.Library.Theme.Accent,
        Callback = function(value)
            local theme = deepCopy(self.Library.Theme)
            theme.Accent = value
            self.Library:ApplyTheme(theme)
            syncThemePickers()
        end,
    })
    groupbox:AddLabel("Text"):AddColorPicker("ThemeManager_Text", {
        Default = self.Library.Theme.Text,
        Callback = function(value)
            local theme = deepCopy(self.Library.Theme)
            theme.Text = value
            self.Library:ApplyTheme(theme)
            syncThemePickers()
        end,
    })
    groupbox:AddLabel("Sub text"):AddColorPicker("ThemeManager_SubText", {
        Default = self.Library.Theme.SubText,
        Callback = function(value)
            local theme = deepCopy(self.Library.Theme)
            theme.SubText = value
            self.Library:ApplyTheme(theme)
            syncThemePickers()
        end,
    })
    groupbox:AddDivider()
    groupbox:AddDropdown("ThemeManager_BuiltinList", {
        Text = "Built-in themes",
        Values = self:List(),
        Default = self.Library.ThemeName,
        Searchable = true,
        Callback = function(value)
            if value then
                self:Apply(value)
                syncThemePickers()
            end
        end,
    })
    groupbox:AddInput("ThemeManager_CustomName", {
        Text = "Theme name",
        Placeholder = "Custom",
    })
    groupbox:AddButton({
        Text = "Save theme",
        Func = function()
            local name = self.Library.Options.ThemeManager_CustomName and self.Library.Options.ThemeManager_CustomName.Value or ""
            local ok, result = self:Save(name)
            self.Library:Notify({
                Title = "ThemeManager",
                Content = ok and ('Saved theme "' .. tostring(name) .. '"') or ("Save failed: " .. tostring(result)),
            })
            if self.Library.Options.ThemeManager_CustomList then
                self.Library.Options.ThemeManager_CustomList:SetValues(self:ReloadCustomThemes())
            end
        end,
    })
    groupbox:AddDropdown("ThemeManager_CustomList", {
        Text = "Custom themes",
        Values = self:ReloadCustomThemes(),
        AllowNull = true,
        Searchable = true,
    })
    groupbox:AddButton({
        Text = "Load custom",
        Func = function()
            local selected = self.Library.Options.ThemeManager_CustomList and self.Library.Options.ThemeManager_CustomList.Value
            local ok, result = self:Load(selected)
            self.Library:Notify({
                Title = "ThemeManager",
                Content = ok and ('Loaded theme "' .. tostring(selected) .. '"') or ("Load failed: " .. tostring(result)),
            })
            if ok then
                syncThemePickers()
            end
        end,
    })
    groupbox:AddButton({
        Text = "Delete custom",
        Func = function()
            local selected = self.Library.Options.ThemeManager_CustomList and self.Library.Options.ThemeManager_CustomList.Value
            local ok, result = self:Delete(selected)
            self.Library:Notify({
                Title = "ThemeManager",
                Content = ok and ('Deleted theme "' .. tostring(selected) .. '"') or ("Delete failed: " .. tostring(result)),
            })
            if self.Library.Options.ThemeManager_CustomList then
                self.Library.Options.ThemeManager_CustomList:SetValues(self:ReloadCustomThemes())
                self.Library.Options.ThemeManager_CustomList:SetValue(nil, true)
            end
        end,
    })
    syncThemePickers()
    return groupbox
end

function ThemeManager:ApplyToTab(tab)
    local groupbox = tab:AddLeftGroupbox("Themes")
    return self:_buildThemeControls(groupbox)
end

function ThemeManager:ApplyToGroupbox(groupbox)
    return self:_buildThemeControls(groupbox)
end

return setmetatable({
    Library = nil,
    Folder = "KojoHub/themes",
}, ThemeManager)
