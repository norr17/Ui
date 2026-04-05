local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.__index = SaveManager

local mouseInputNames = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

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

local function inputToName(value)
    if typeof(value) ~= "EnumItem" then
        return tostring(value or "None")
    end
    return mouseInputNames[value] or value.Name
end

local function colorToTable(color)
    return {
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5),
    }
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

function SaveManager:SetLibrary(library)
    self.Library = library
    return self
end

function SaveManager:IgnoreFlag(flag)
    self.IgnoreFlags[flag] = true
    return self
end

function SaveManager:SetIgnoreIndexes(list)
    for _, flag in ipairs(list or {}) do
        self.IgnoreFlags[flag] = true
    end
    return self
end

function SaveManager:IgnoreThemeSettings()
    self.IgnoreThemeData = true
    self:SetIgnoreIndexes({
        "ThemeManager_BuiltinList",
        "ThemeManager_CustomList",
        "ThemeManager_CustomName",
        "ThemeManager_Accent",
        "ThemeManager_Text",
        "ThemeManager_SubText",
    })
    return self
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
    return self
end

function SaveManager:SetSubFolder(folder)
    self.SubFolder = folder
    self:BuildFolderTree()
    return self
end

function SaveManager:CheckSubFolder(createFolder)
    if type(self.SubFolder) ~= "string" or self.SubFolder == "" then
        return false
    end
    local path = self.Folder .. "/settings/" .. self.SubFolder
    local exists = isfolder and isfolder(path) or false
    if createFolder and makefolder and not exists then
        pcall(makefolder, path)
    end
    return true
end

function SaveManager:GetPaths()
    local paths = {}
    local parts = tostring(self.Folder or ""):split("/")
    for index = 1, #parts do
        local path = table.concat(parts, "/", 1, index)
        if path ~= "" then
            paths[#paths + 1] = path
        end
    end
    paths[#paths + 1] = self.Folder .. "/settings"
    paths[#paths + 1] = self.Folder .. "/themes"
    if self:CheckSubFolder(false) then
        paths[#paths + 1] = self.Folder .. "/settings/" .. self.SubFolder
    end
    return paths
end

function SaveManager:BuildFolderTree()
    if not makefolder then
        return
    end
    for _, path in ipairs(self:GetPaths()) do
        if path ~= "" and (not isfolder or not isfolder(path)) then
            pcall(makefolder, path)
        end
    end
end

function SaveManager:CheckFolderTree()
    self:BuildFolderTree()
end

function SaveManager:_settingsRoot()
    local root = self.Folder .. "/settings"
    if self:CheckSubFolder(true) then
        root = root .. "/" .. self.SubFolder
    end
    return root
end

function SaveManager:_autoloadPath()
    return self:_settingsRoot() .. "/autoload.txt"
end

function SaveManager:_serialize(option)
    if option.Type == "keybind" then
        return {
            key = option.Value and inputToName(option.Value) or nil,
            mode = option.Mode,
            modifiers = deepCopy(option.Modifiers or {}),
        }
    end
    if option.Type == "colorpicker" then
        return {
            color = colorToTable(option.Value),
            transparency = option.Transparency or 0,
        }
    end
    return deepCopy(option.Value)
end

function SaveManager:_deserialize(option, value)
    if option.Type == "keybind" then
        return {
            value and value.key or nil,
            value and value.mode or option.Mode,
            value and value.modifiers or option.Modifiers,
        }
    end
    if option.Type == "colorpicker" then
        return value and value.color or nil, value and value.transparency or 0
    end
    return deepCopy(value)
end

function SaveManager:Save(name)
    if not writefile then
        return false, "writefile_unavailable"
    end
    if not name or tostring(name):gsub("%s+", "") == "" then
        return false, "invalid_name"
    end
    self:CheckFolderTree()
    local payload = {
        Theme = self.IgnoreThemeData and nil or self.Library.ThemeName,
        Flags = {},
    }
    for flag, option in pairs(self.Library.Options) do
        if option.Save ~= false and not self.IgnoreFlags[flag] then
            payload.Flags[flag] = self:_serialize(option)
        end
    end
    local path = self:_settingsRoot() .. "/" .. tostring(name) .. ".json"
    writefile(path, HttpService:JSONEncode(payload))
    return true, path
end

function SaveManager:Load(name)
    if not readfile or not isfile then
        return false, "readfile_unavailable"
    end
    if not name or tostring(name) == "" then
        return false, "invalid_name"
    end
    local path = self:_settingsRoot() .. "/" .. tostring(name) .. ".json"
    if not isfile(path) then
        return false, "config_not_found"
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok then
        return false, "decode_error"
    end
    if decoded.Theme and not self.IgnoreThemeData then
        self.Library:ApplyTheme(decoded.Theme)
    end
    for flag, rawValue in pairs(decoded.Flags or {}) do
        local option = self.Library:GetOption(flag)
        if option and option.SetValue then
            local value, extra = self:_deserialize(option, rawValue)
            if option.Type == "colorpicker" then
                option:SetValue(value, extra, true)
            else
                option:SetValue(value, true)
            end
            if option.TriggerChanged then
                option:TriggerChanged()
            end
        end
    end
    return true, path
end

function SaveManager:Delete(name)
    if not delfile then
        return false, "delfile_unavailable"
    end
    if not name or tostring(name) == "" then
        return false, "invalid_name"
    end
    local path = self:_settingsRoot() .. "/" .. tostring(name) .. ".json"
    if isfile and not isfile(path) then
        return false, "config_not_found"
    end
    local ok = pcall(delfile, path)
    return ok, ok and path or "delete_failed"
end

function SaveManager:List()
    self:CheckFolderTree()
    return listJsonNames(self:_settingsRoot())
end

function SaveManager:RefreshConfigList()
    return self:List()
end

function SaveManager:GetAutoloadConfig()
    local path = self:_autoloadPath()
    if not isfile or not isfile(path) or not readfile then
        return "none"
    end
    local ok, content = pcall(readfile, path)
    if not ok then
        return "none"
    end
    content = tostring(content or "")
    return content == "" and "none" or content
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoloadConfig()
    if name == "none" then
        return false, "autoload_not_set"
    end
    return self:Load(name)
end

function SaveManager:SaveAutoloadConfig(name)
    if not writefile then
        return false, "writefile_unavailable"
    end
    if not name or tostring(name) == "" then
        return false, "invalid_name"
    end
    self:CheckFolderTree()
    writefile(self:_autoloadPath(), tostring(name))
    return true, self:_autoloadPath()
end

function SaveManager:DeleteAutoLoadConfig()
    if not delfile then
        return false, "delfile_unavailable"
    end
    local path = self:_autoloadPath()
    if isfile and not isfile(path) then
        return false, "autoload_not_found"
    end
    local ok = pcall(delfile, path)
    return ok, ok and path or "delete_failed"
end

function SaveManager:BuildConfigSection(tab)
    local section = tab:AddRightGroupbox("Configs")
    section:AddInput("SaveManager_ConfigName", {
        Text = "Config name",
        Placeholder = "legit / rage / hvh",
    })
    section:AddButton({
        Text = "Create config",
        Func = function()
            local name = self.Library.Options.SaveManager_ConfigName and self.Library.Options.SaveManager_ConfigName.Value or ""
            local ok, result = self:Save(name)
            self.Library:Notify({
                Title = "SaveManager",
                Content = ok and ('Created config "' .. tostring(name) .. '"') or ("Create failed: " .. tostring(result)),
            })
            if self.Library.Options.SaveManager_ConfigList then
                self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            end
        end,
    })
    section:AddDivider()
    section:AddDropdown("SaveManager_ConfigList", {
        Text = "Config list",
        Values = self:RefreshConfigList(),
        AllowNull = true,
        Searchable = true,
    })
    section:AddButton({
        Text = "Load config",
        Func = function()
            local target = self.Library.Options.SaveManager_ConfigList and self.Library.Options.SaveManager_ConfigList.Value
            local ok, result = self:Load(target)
            self.Library:Notify({
                Title = "SaveManager",
                Content = ok and ('Loaded "' .. tostring(target) .. '"') or ("Load failed: " .. tostring(result)),
            })
        end,
    })
    section:AddButton({
        Text = "Overwrite config",
        Func = function()
            local target = self.Library.Options.SaveManager_ConfigList and self.Library.Options.SaveManager_ConfigList.Value
            local ok, result = self:Save(target)
            self.Library:Notify({
                Title = "SaveManager",
                Content = ok and ('Overwrote "' .. tostring(target) .. '"') or ("Overwrite failed: " .. tostring(result)),
            })
            if self.Library.Options.SaveManager_ConfigList then
                self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            end
        end,
    })
    section:AddButton({
        Text = "Delete config",
        Func = function()
            local target = self.Library.Options.SaveManager_ConfigList and self.Library.Options.SaveManager_ConfigList.Value
            local ok, result = self:Delete(target)
            self.Library:Notify({
                Title = "SaveManager",
                Content = ok and ('Deleted "' .. tostring(target) .. '"') or ("Delete failed: " .. tostring(result)),
            })
            if self.Library.Options.SaveManager_ConfigList then
                self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                self.Library.Options.SaveManager_ConfigList:SetValue(nil, true)
            end
        end,
    })
    section:AddButton({
        Text = "Refresh list",
        Func = function()
            if self.Library.Options.SaveManager_ConfigList then
                self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            end
        end,
    })
    section:AddDivider()
    section:AddButton({
        Text = "Set autoload",
        Func = function()
            local target = self.Library.Options.SaveManager_ConfigList and self.Library.Options.SaveManager_ConfigList.Value
            local ok, result = self:SaveAutoloadConfig(target)
            self.Library:Notify({
                Title = "SaveManager",
                Content = ok and ('Autoload set to "' .. tostring(target) .. '"') or ("Autoload failed: " .. tostring(result)),
            })
            if self.AutoloadLabel then
                self.AutoloadLabel:SetText("Autoload: " .. self:GetAutoloadConfig())
            end
        end,
    })
    section:AddButton({
        Text = "Reset autoload",
        Func = function()
            local ok, result = self:DeleteAutoLoadConfig()
            self.Library:Notify({
                Title = "SaveManager",
                Content = ok and "Autoload cleared" or ("Reset failed: " .. tostring(result)),
            })
            if self.AutoloadLabel then
                self.AutoloadLabel:SetText("Autoload: " .. self:GetAutoloadConfig())
            end
        end,
    })
    self.AutoloadLabel = section:AddLabel({
        Text = "Autoload: " .. self:GetAutoloadConfig(),
        DoesWrap = true,
        Flag = "SaveManager_AutoloadLabel",
    })
    self:SetIgnoreIndexes({ "SaveManager_ConfigName", "SaveManager_ConfigList", "SaveManager_AutoloadLabel" })
    return section
end

return setmetatable({
    Library = nil,
    Folder = "KojoHub",
    IgnoreFlags = {},
    IgnoreThemeData = false,
    SubFolder = nil,
}, SaveManager)
