local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager:SetLibrary(library)
    self.Library = library
    return self
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    return self
end

function SaveManager:SetSubFolder(subFolder)
    self.SubFolder = subFolder
    return self
end

function SaveManager:SetIgnoreIndexes(indexes)
    self.Ignore = {}
    for _, index in ipairs(indexes or {}) do
        self.Ignore[tostring(index)] = true
    end
    return self
end

function SaveManager:IgnoreThemeSettings()
    self.IgnoreTheme = true
    return self
end

function SaveManager:_resolveFolder()
    local folder = self.Folder or "KojoHub"
    if self.SubFolder and self.SubFolder ~= "" then
        folder = folder .. "/" .. self.SubFolder
    end
    return folder
end

function SaveManager:_collectIgnoreFlags()
    local ignoreFlags = {}
    for index, _ in pairs(self.Ignore or {}) do
        local control = self.Library and self.Library.Options and self.Library.Options[index]
        if control and control.Flag then
            ignoreFlags[control.Flag] = true
        end
    end
    if self.IgnoreTheme and self.Library and self.Library.Options then
        for _, control in pairs(self.Library.Options) do
            if type(control) == "table" and type(control.Flag) == "string" and control.Flag:match("^Theme%.") then
                ignoreFlags[control.Flag] = true
            end
        end
    end
    return ignoreFlags
end

function SaveManager:_config(name)
    local cfg = assert(self.Library, "SaveManager library not set"):CreateConfig({
        Folder = self:_resolveFolder(),
        Name = name or self.CurrentConfig or "default",
    })
    local flags = {}
    for flag, _ in pairs(self:_collectIgnoreFlags()) do
        table.insert(flags, flag)
    end
    cfg:SetIgnoreFlags(flags)
    return cfg
end

function SaveManager:Save(name)
    self.CurrentConfig = name or self.CurrentConfig or "default"
    return self:_config(self.CurrentConfig):Save(self.CurrentConfig)
end

function SaveManager:Load(name)
    self.CurrentConfig = name or self.CurrentConfig or "default"
    return self:_config(self.CurrentConfig):Load(self.CurrentConfig)
end

function SaveManager:Delete(name)
    self.CurrentConfig = name or self.CurrentConfig or "default"
    return self:_config(self.CurrentConfig):Delete(self.CurrentConfig)
end

function SaveManager:List()
    return self:_config(self.CurrentConfig or "default"):ListConfigs()
end

function SaveManager:SetAutoload(name)
    self.CurrentConfig = name or self.CurrentConfig or "default"
    return self:_config(self.CurrentConfig):SetAutoload(self.CurrentConfig)
end

function SaveManager:LoadAutoloadConfig()
    return self:_config(self.CurrentConfig or "default"):LoadAutoload()
end

function SaveManager:BuildConfigSection(target)
    assert(self.Library, "SaveManager library not set")

    local group
    if target.AddRightGroupbox then
        group = target:AddRightGroupbox("Config")
    else
        group = target
    end

    local nameBuffer = group:AddInput("ConfigName", {
        Text = "Config Name",
        Default = self.CurrentConfig or "default",
        Placeholder = "config name",
        Save = false,
        Callback = function(value)
            self.CurrentConfig = value ~= "" and value or "default"
        end,
    })

    local configsDropdown = group:AddDropdown("ConfigList", {
        Text = "Configs",
        Values = self:List(),
        Default = nil,
        Save = false,
        Callback = function(value)
            if value then
                self.CurrentConfig = value
                if nameBuffer and nameBuffer.SetValue then
                    nameBuffer:SetValue(value)
                end
            end
        end,
    })

    local function refreshConfigs()
        if configsDropdown and configsDropdown.SetOptions then
            configsDropdown:SetOptions(self:List())
        end
    end

    group:AddButton({
        Text = "Save Config",
        Func = function()
            local ok = self:Save()
            refreshConfigs()
            self.Library:Notify({
                Title = "Config",
                Description = ok and "Saved config." or "Failed to save config.",
                Type = ok and "Success" or "Error",
                Duration = 3,
            })
        end,
    })

    group:AddButton({
        Text = "Load Config",
        Func = function()
            local ok = self:Load()
            self.Library:Notify({
                Title = "Config",
                Description = ok and "Loaded config." or "Failed to load config.",
                Type = ok and "Success" or "Error",
                Duration = 3,
            })
        end,
    })

    group:AddButton({
        Text = "Delete Config",
        Func = function()
            local ok = self:Delete()
            refreshConfigs()
            self.Library:Notify({
                Title = "Config",
                Description = ok and "Deleted config." or "Failed to delete config.",
                Type = ok and "Success" or "Error",
                Duration = 3,
            })
        end,
    })

    group:AddToggle("ConfigAutoload", {
        Text = "Autoload current",
        Default = false,
        Save = false,
        Callback = function(value)
            if value then
                self:SetAutoload()
            end
        end,
    })

    group:AddButton({
        Text = "Refresh List",
        Func = refreshConfigs,
    })

    refreshConfigs()
    return group
end

return setmetatable({
    Folder = "KojoHub",
    SubFolder = nil,
    Ignore = {},
    IgnoreTheme = false,
    CurrentConfig = "default",
}, SaveManager)
