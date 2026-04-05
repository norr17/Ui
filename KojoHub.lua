
local clonerefSafe = cloneref or function(object)
    return object
end

local Players = clonerefSafe(game:GetService("Players"))
local TeamsService = clonerefSafe(game:GetService("Teams"))
local TweenService = clonerefSafe(game:GetService("TweenService"))
local UserInputService = clonerefSafe(game:GetService("UserInputService"))
local CoreGui = clonerefSafe(game:GetService("CoreGui"))
local HttpService = clonerefSafe(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")

local Library = {}
Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local KeyTab = {}
KeyTab.__index = KeyTab

local Groupbox = {}
Groupbox.__index = Groupbox

local DependencyBox = {}
DependencyBox.__index = DependencyBox

local Tabbox = {}
Tabbox.__index = Tabbox

local TabboxPage = {}
TabboxPage.__index = TabboxPage

local Element = {}
Element.__index = Element

local SaveManager = {}
SaveManager.__index = SaveManager

local ThemeManager = {}
ThemeManager.__index = ThemeManager

setmetatable(KeyTab, { __index = Tab })

local function create(className, props)
    local object = Instance.new(className)
    if props then
        for property, value in pairs(props) do
            if property ~= "Parent" then
                object[property] = value
            end
        end
        if props.Parent then
            object.Parent = props.Parent
        end
    end
    return object
end

local function makeCorner(parent, radius)
    return create("UICorner", {
        Parent = parent,
        CornerRadius = UDim.new(0, radius),
    })
end

local function makeStroke(parent, thickness)
    return create("UIStroke", {
        Parent = parent,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function makePadding(parent, left, right, top, bottom)
    return create("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
    })
end

local function resolveFont(enumName, fallback)
    local ok, value = pcall(function()
        return Enum.Font[enumName]
    end)
    if ok and value then
        return value
    end
    return fallback
end

local function getFont(weight)
    weight = string.lower(weight or "regular")
    if weight == "bold" then
        return resolveFont("BuilderSansBold", Enum.Font.GothamBold)
    end
    if weight == "medium" then
        return resolveFont("BuilderSansMedium", Enum.Font.GothamMedium)
    end
    return resolveFont("BuilderSans", Enum.Font.Gotham)
end

local function trySetFontFace(object, familyPath, weight)
    pcall(function()
        object.FontFace = Font.new(familyPath, weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)
end

local function applyTextStyle(object, size, weight)
    object.Font = getFont(weight)
    object.TextSize = size
    local fontWeight = weight == "bold" and Enum.FontWeight.Bold or weight == "medium" and Enum.FontWeight.Medium or Enum.FontWeight.Regular
    trySetFontFace(object, "rbxasset://fonts/families/BuilderSans.json", fontWeight)
    trySetFontFace(object, "rbxasset://fonts/families/Gotham.json", fontWeight)
end

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function roundTo(value, decimals, increment)
    if increment and increment > 0 then
        value = math.floor((value / increment) + 0.5) * increment
    end
    if not decimals or decimals <= 0 then
        return math.floor(value + 0.5)
    end
    local power = 10 ^ decimals
    return math.floor(value * power + 0.5) / power
end

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

local function signal()
    local self = { _callbacks = {} }
    function self:Connect(callback)
        local connection = { Connected = true }
        function connection:Disconnect()
            if not self.Connected then
                return
            end
            self.Connected = false
        end
        self._callbacks[#self._callbacks + 1] = { Connection = connection, Callback = callback }
        return connection
    end
    function self:Fire(...)
        for index = #self._callbacks, 1, -1 do
            local item = self._callbacks[index]
            if item.Connection.Connected then
                item.Callback(...)
            else
                table.remove(self._callbacks, index)
            end
        end
    end
    return self
end

local function safeDestroy(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function tween(object, properties)
    local ok, built = pcall(function()
        return TweenService:Create(object, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    end)
    if ok and built then
        built:Play()
        return
    end
    for property, value in pairs(properties) do
        pcall(function()
            object[property] = value
        end)
    end
end

local function sanitizeFlag(seed)
    local text = tostring(seed or "Option"):gsub("[^%w_]+", "")
    return text == "" and "Option" or text
end

local function keyCodeFromName(value)
    if typeof(value) == "EnumItem" then
        return value
    end
    if type(value) == "string" and Enum.KeyCode[value] then
        return Enum.KeyCode[value]
    end
    return nil
end

local mouseInputNames = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local function inputFromName(value)
    if typeof(value) == "EnumItem" then
        return value
    end
    if type(value) ~= "string" or value == "" then
        return nil
    end
    if Enum.KeyCode[value] then
        return Enum.KeyCode[value]
    end
    for enumItem, name in pairs(mouseInputNames) do
        if value == name then
            return enumItem
        end
    end
    return nil
end

local function inputToName(value)
    if typeof(value) ~= "EnumItem" then
        return tostring(value or "None")
    end
    return mouseInputNames[value] or value.Name
end

local function inputMatches(input, expected)
    if not expected or typeof(expected) ~= "EnumItem" then
        return false
    end
    if expected.EnumType == Enum.KeyCode then
        return input.KeyCode == expected
    end
    return input.UserInputType == expected
end

local function valueCount(value)
    if type(value) ~= "table" then
        return 0
    end
    local count = 0
    for _, enabled in pairs(value) do
        if enabled then
            count = count + 1
        end
    end
    return count
end

local function normalizeMultiSelection(value)
    if type(value) ~= "table" then
        return {}
    end
    local normalized = {}
    for key, enabled in pairs(value) do
        if type(key) == "number" then
            normalized[enabled] = true
        elseif enabled then
            normalized[key] = true
        end
    end
    return normalized
end

local function valueExists(list, target)
    for _, item in ipairs(list or {}) do
        if item == target then
            return true
        end
    end
    return false
end

local function buildLookup(list)
    local lookup = {}
    for _, item in ipairs(list or {}) do
        lookup[item] = true
    end
    return lookup
end

local function shallowKeysSorted(map)
    local keys = {}
    for key, enabled in pairs(map or {}) do
        if enabled then
            keys[#keys + 1] = tostring(key)
        end
    end
    table.sort(keys)
    return keys
end

local function applyActiveText(label, active)
    if not label then
        return
    end
    label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = active and 0.78 or 1
end

local function parseFlagConfig(flagOrConfig, maybeConfig)
    if maybeConfig ~= nil then
        local info = deepCopy(maybeConfig or {})
        info.Flag = info.Flag or flagOrConfig
        return info
    end

    if type(flagOrConfig) == "table" then
        return deepCopy(flagOrConfig)
    end

    local info = {}
    if type(flagOrConfig) == "string" then
        info.Flag = flagOrConfig
        info.Text = flagOrConfig
    end
    return info
end

local function parseButtonConfig(textOrConfig, maybeConfig)
    if type(textOrConfig) == "table" then
        return deepCopy(textOrConfig)
    end
    if type(maybeConfig) == "function" then
        return {
            Text = tostring(textOrConfig or "Button"),
            Func = maybeConfig,
        }
    end
    local info = deepCopy(maybeConfig or {})
    info.Text = info.Text or tostring(textOrConfig or "Button")
    return info
end

local function parseLabelConfig(textOrConfig, doesWrap, idx)
    if type(textOrConfig) == "table" then
        local info = deepCopy(textOrConfig)
        info.Flag = info.Flag or idx or textOrConfig.Idx
        return info
    end
    return {
        Flag = idx,
        Text = tostring(textOrConfig or ""),
        DoesWrap = doesWrap == true,
    }
end

local function getDisplayValue(option, value)
    if option.FormatDisplayValue then
        local ok, custom = pcall(option.FormatDisplayValue, option, value)
        if ok and custom ~= nil then
            return tostring(custom)
        end
    end
    return tostring(value)
end

local function getSpecialValues(option)
    if option.SpecialType == "Player" then
        local values = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if not (option.ExcludeLocalPlayer and player == LocalPlayer) then
                values[#values + 1] = player.Name
            end
        end
        table.sort(values, function(a, b)
            return string.lower(a) < string.lower(b)
        end)
        return values
    end
    if option.SpecialType == "Team" then
        local values = {}
        for _, team in ipairs(TeamsService:GetChildren()) do
            if team:IsA("Team") then
                values[#values + 1] = team.Name
            end
        end
        table.sort(values, function(a, b)
            return string.lower(a) < string.lower(b)
        end)
        return values
    end
    return nil
end

local function tableContains(list, expected)
    for _, item in ipairs(list) do
        if item == expected then
            return true
        end
    end
    return false
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

local function colorToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function getGuiParent()
    local parent = nil
    pcall(function()
        if gethui then
            parent = gethui()
        end
    end)
    if parent then
        return parent
    end
    return CoreGui or PlayerGui
end

local function bindTheme(self, object, property, token)
    self._themeBindings[#self._themeBindings + 1] = {
        Object = object,
        Property = property,
        Token = token,
    }
    object[property] = self.Theme[token]
end

local function setIconColor(parts, color)
    for _, part in ipairs(parts or {}) do
        if part and part.Parent then
            part.BackgroundColor3 = color
        end
    end
end

local function resolveAsset(asset)
    if type(asset) == "number" then
        return "rbxassetid://" .. tostring(asset)
    end

    if type(asset) == "string" and asset ~= "" then
        if asset:match("^rbxassetid://") or asset:match("^https?://") then
            return asset
        end

        if tonumber(asset) then
            return "rbxassetid://" .. tostring(asset)
        end
    end

    return nil
end

local function makeCirclePart(parent, size, position, color, rotation)
    local part = create("Frame", {
        Parent = parent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = position,
        Size = size,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Rotation = rotation or 0,
    })
    makeCorner(part, math.floor(math.min(size.X.Offset, size.Y.Offset) / 2))
    return part
end

local function buildHumanoidIcon(parent, color)
    local parts = {}
    parts[#parts + 1] = makeCirclePart(parent, UDim2.fromOffset(7, 7), UDim2.new(0.5, 0, 0.16, 0), color)
    parts[#parts + 1] = makeCirclePart(parent, UDim2.fromOffset(5, 10), UDim2.new(0.5, 0, 0.46, 0), color)
    parts[#parts + 1] = makeCirclePart(parent, UDim2.fromOffset(12, 3), UDim2.new(0.5, 0, 0.39, 0), color)
    parts[#parts + 1] = makeCirclePart(parent, UDim2.fromOffset(4, 10), UDim2.new(0.37, 0, 0.76, 0), color, 16)
    parts[#parts + 1] = makeCirclePart(parent, UDim2.fromOffset(4, 10), UDim2.new(0.63, 0, 0.76, 0), color, -16)
    return parts
end

local function buildFootballIcon(parent, color)
    local parts = {}
    parts[#parts + 1] = makeCirclePart(parent, UDim2.fromOffset(20, 13), UDim2.new(0.5, 0, 0.5, 0), color, -28)
    parts[#parts + 1] = makeCirclePart(parent, UDim2.fromOffset(8, 2), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(18, 20, 24), -28)
    parts[#parts + 1] = makeCirclePart(parent, UDim2.fromOffset(2, 7), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(18, 20, 24), 62)
    return parts
end

local function createIconVisual(parent, iconSpec, fallbackBuilder, color)
    local asset = resolveAsset(iconSpec)
    if asset then
        local image = create("ImageLabel", {
            Parent = parent,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = asset,
            ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = color,
        })

        return {
            Kind = "image",
            Object = image,
        }
    end

    return {
        Kind = "vector",
        Parts = fallbackBuilder(parent, color),
    }
end

local function setIconVisualColor(icon, color)
    if not icon then
        return
    end

    if icon.Kind == "image" and icon.Object then
        icon.Object.ImageColor3 = color
    elseif icon.Kind == "vector" then
        setIconColor(icon.Parts, color)
    end
end

local function applyTheme(self)
    for _, binding in ipairs(self._themeBindings) do
        if binding.Object and binding.Object.Parent then
            binding.Object[binding.Property] = self.Theme[binding.Token]
        end
    end
    for _, option in pairs(self.Options) do
        if option.UpdateTheme then
            option:UpdateTheme()
        end
    end
    for _, button in pairs(self.Buttons) do
        if button.UpdateTheme then
            button:UpdateTheme()
        end
    end
    for _, window in ipairs(self.Windows) do
        if window.UpdateTheme then
            window:UpdateTheme()
        end
    end
end

function Library.new()
    local self = setmetatable({}, Library)
    self.ThemeName = "Kojo"
    self.Themes = {
        Kojo = {
            Shell = Color3.fromRGB(4, 5, 7),
            Sidebar = Color3.fromRGB(6, 7, 9),
            Surface = Color3.fromRGB(10, 11, 15),
            Inset = Color3.fromRGB(7, 8, 11),
            Input = Color3.fromRGB(28, 31, 41),
            InputHover = Color3.fromRGB(36, 40, 52),
            Border = Color3.fromRGB(16, 18, 23),
            BorderStrong = Color3.fromRGB(24, 26, 32),
            Accent = Color3.fromRGB(202, 184, 214),
            AccentMuted = Color3.fromRGB(101, 112, 145),
            AccentStrong = Color3.fromRGB(243, 239, 247),
            ToggleOn = Color3.fromRGB(44, 38, 50),
            ToggleKnobOn = Color3.fromRGB(206, 184, 224),
            Text = Color3.fromRGB(240, 241, 244),
            SubText = Color3.fromRGB(109, 119, 150),
            MutedText = Color3.fromRGB(73, 80, 101),
            Shadow = Color3.fromRGB(0, 0, 0),
        },
        Slate = {
            Shell = Color3.fromRGB(13, 15, 19),
            Sidebar = Color3.fromRGB(12, 14, 18),
            Surface = Color3.fromRGB(15, 17, 23),
            Inset = Color3.fromRGB(11, 13, 17),
            Input = Color3.fromRGB(34, 40, 49),
            InputHover = Color3.fromRGB(44, 51, 61),
            Border = Color3.fromRGB(29, 34, 42),
            BorderStrong = Color3.fromRGB(41, 47, 59),
            Accent = Color3.fromRGB(153, 176, 207),
            AccentMuted = Color3.fromRGB(92, 111, 145),
            AccentStrong = Color3.fromRGB(239, 242, 247),
            ToggleOn = Color3.fromRGB(37, 43, 55),
            ToggleKnobOn = Color3.fromRGB(173, 189, 219),
            Text = Color3.fromRGB(231, 235, 243),
            SubText = Color3.fromRGB(119, 131, 160),
            MutedText = Color3.fromRGB(83, 91, 113),
            Shadow = Color3.fromRGB(0, 0, 0),
        },
        Rose = {
            Shell = Color3.fromRGB(14, 11, 15),
            Sidebar = Color3.fromRGB(13, 10, 15),
            Surface = Color3.fromRGB(17, 13, 18),
            Inset = Color3.fromRGB(12, 10, 14),
            Input = Color3.fromRGB(37, 29, 39),
            InputHover = Color3.fromRGB(47, 38, 50),
            Border = Color3.fromRGB(33, 27, 35),
            BorderStrong = Color3.fromRGB(45, 37, 47),
            Accent = Color3.fromRGB(201, 163, 190),
            AccentMuted = Color3.fromRGB(122, 95, 128),
            AccentStrong = Color3.fromRGB(243, 232, 239),
            ToggleOn = Color3.fromRGB(49, 34, 52),
            ToggleKnobOn = Color3.fromRGB(216, 180, 205),
            Text = Color3.fromRGB(236, 233, 237),
            SubText = Color3.fromRGB(146, 116, 146),
            MutedText = Color3.fromRGB(98, 82, 103),
            Shadow = Color3.fromRGB(0, 0, 0),
        },
    }
    self.Theme = deepCopy(self.Themes[self.ThemeName])
    self.Options = {}
    self.Toggles = {}
    self.Labels = {}
    self.Buttons = {}
    self.Windows = {}
    self._themeBindings = {}
    self._connections = {}
    self._flags = {}
    self._keybinds = {}
    self._unloadCallbacks = {}
    self.Unloaded = false
    self.NotifySide = "Right"
    self.DPIScale = 100
    self.ForceCheckbox = false
    self.ShowToggleFrameInKeybinds = true

    pcall(function()
        local env = getgenv and getgenv() or _G
        env.Options = self.Options
        env.Toggles = self.Toggles
        env.KojoLibrary = self
    end)

    return self
end

function Library:_track(connection)
    self._connections[#self._connections + 1] = connection
    return connection
end

function Library:_safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local arguments = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(arguments, 1, arguments.n))
        end)

        if not ok then
            warn("[KojoHub] callback error:", err)
        end
    end)
end

function Library:_nextFlag(seed)
    local base = sanitizeFlag(seed)
    local attempt = base
    local index = 1
    while self._flags[attempt] do
        index = index + 1
        attempt = base .. tostring(index)
    end
    self._flags[attempt] = true
    return attempt
end

function Library:ApplyTheme(theme)
    if type(theme) == "string" then
        if not self.Themes[theme] then
            return false, "theme_not_found"
        end
        self.ThemeName = theme
        self.Theme = deepCopy(self.Themes[theme])
    elseif type(theme) == "table" then
        self.ThemeName = "Custom"
        self.Theme = deepCopy(theme)
    else
        return false, "invalid_theme"
    end
    applyTheme(self)
    return true
end

function Library:RegisterTheme(name, theme)
    self.Themes[name] = deepCopy(theme)
    return self
end

function Library:GetOption(flag)
    return self.Options[flag]
end

function Library:_registerOption(option)
    option.Flag = option.Flag or self:_nextFlag(option.Text or option.Type)
    self.Options[option.Flag] = option
    return option
end

function Library:CreateSaveManager()
    return setmetatable({ Library = self, Folder = "KojoHub", IgnoreFlags = {}, IgnoreThemeData = false, SubFolder = nil }, SaveManager)
end

function Library:CreateThemeManager()
    return setmetatable({ Library = self, Folder = "KojoHub/themes" }, ThemeManager)
end
function Library:Notify(options)
    if type(options) == "string" then
        options = {
            Title = "Kojo Hub",
            Content = options,
        }
    else
        options = options or {}
    end
    local window = self.Windows[1]
    if not window or not window.NotificationHolder then
        return
    end

    local card = create("Frame", {
        Parent = window.NotificationHolder,
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.fromOffset(300, 0),
    })
    makeCorner(card, 12)
    local stroke = makeStroke(card, 1)
    stroke.Color = self.Theme.BorderStrong
    makePadding(card, 12, 12, 10, 12)
    bindTheme(self, card, "BackgroundColor3", "Surface")
    bindTheme(self, stroke, "Color", "BorderStrong")

    local title = create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Text = options.Title or "Kojo Hub",
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(title, 16, "bold")
    bindTheme(self, title, "TextColor3", "Text")

    local body = create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 20),
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Text = options.Content or options.Description or "",
        TextWrapped = true,
        TextColor3 = self.Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    applyTextStyle(body, 15, "regular")
    bindTheme(self, body, "TextColor3", "SubText")

    task.spawn(function()
        task.wait(options.Duration or options.Time or 4)
        safeDestroy(card)
    end)
end

function Library:Unload()
    if self.Unloaded then
        return
    end

    self.Unloaded = true

    for _, connection in ipairs(self._connections) do
        if connection and connection.Disconnect then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    for _, window in ipairs(self.Windows) do
        safeDestroy(window.ScreenGui)
    end
    self.Options = {}
    self.Toggles = {}
    self.Buttons = {}
    self.Labels = {}
    self.Windows = {}

    for _, callback in ipairs(self._unloadCallbacks) do
        self:_safeCallback(callback)
    end
end

function Library:OnUnload(callback)
    self._unloadCallbacks[#self._unloadCallbacks + 1] = callback
end

function Library:SetNotifySide(side)
    if side ~= "Left" and side ~= "Right" then
        return
    end
    self.NotifySide = side
    for _, window in ipairs(self.Windows) do
        if window.NotificationHolder then
            window.NotifySide = side
            window.NotificationHolder.AnchorPoint = side == "Left" and Vector2.new(0, 0) or Vector2.new(1, 0)
            window.NotificationHolder.Position = side == "Left" and UDim2.fromOffset(20, 20) or UDim2.new(1, -20, 0, 20)
            local layout = window.NotificationHolder:FindFirstChildOfClass("UIListLayout")
            if layout then
                layout.HorizontalAlignment = side == "Left" and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
            end
        end
    end
end

function Library:SetDPIScale(scale)
    self.DPIScale = tonumber(scale) or self.DPIScale
    local applied = self.DPIScale / 100
    for _, window in ipairs(self.Windows) do
        if window.RootScale then
            window.RootScale.Scale = applied
        end
    end
end

function Library:Toggle(value)
    local window = self.Windows[1]
    if not window then
        return
    end
    window:SetVisible(value == nil and not window.Visible or value)
end

function Library:AddDraggableLabel(text)
    local window = self.Windows[1]
    if not window then
        return nil
    end
    local label = create("TextLabel", {
        Parent = window.ScreenGui,
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(18, 18),
        Size = UDim2.fromOffset(160, 26),
        Text = tostring(text or "Kojo Hub"),
        TextColor3 = self.Theme.Text,
    })
    applyTextStyle(label, 15, "medium")
    makeCorner(label, 8)
    local stroke = makeStroke(label, 1)
    stroke.Color = self.Theme.BorderStrong
    bindTheme(self, label, "BackgroundColor3", "Surface")
    bindTheme(self, label, "TextColor3", "Text")
    bindTheme(self, stroke, "Color", "BorderStrong")
    local dragging, dragStart, startPosition = false, nil, nil
    self:_track(label.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        dragStart = input.Position
        startPosition = label.Position
    end))
    self:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            label.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))
    self:_track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    return {
        Label = label,
        SetText = function(_, value)
            label.Text = tostring(value or "")
        end,
        SetVisible = function(_, visible)
            label.Visible = visible and true or false
        end,
    }
end

function Library:CreateWindow(options)
    local window = setmetatable({
        Library = self,
        Title = (options and (options.Title or options.Name)) or "Kojo Hub",
        Footer = (options and options.Footer) or "",
        Icon = options and (options.Icon or options.Logo),
        Size = (options and options.Size) or UDim2.fromOffset(790, 580),
        ToggleKey = (options and (options.ToggleKey or options.ToggleKeybind)) or Enum.KeyCode.RightShift,
        SidebarWidth = (options and options.SidebarWidth) or 64,
        NotifySide = (options and options.NotifySide) or self.NotifySide or "Right",
        CornerRadius = (options and options.CornerRadius) or 18,
        MobileButtonsSide = (options and options.MobileButtonsSide) or "Right",
        ShowMobileButtons = options == nil or options.ShowMobileButtons ~= false,
        Tabs = {},
        ActiveTab = nil,
        Visible = true,
    }, Window)
    window:Build()
    self.Windows[#self.Windows + 1] = window
    return window
end

function Window:Build()
    local library = self.Library

    self.ScreenGui = create("ScreenGui", {
        Name = "KojoHub_" .. HttpService:GenerateGUID(false):sub(1, 8),
        Parent = getGuiParent(),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    self.Root = create("Frame", {
        Parent = self.ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = self.Size,
        BackgroundColor3 = library.Theme.Shell,
        BorderSizePixel = 0,
        Active = true,
    })
    self.RootCorner = makeCorner(self.Root, self.CornerRadius)
    local rootStroke = makeStroke(self.Root, 1)
    rootStroke.Color = library.Theme.BorderStrong
    bindTheme(library, self.Root, "BackgroundColor3", "Shell")
    bindTheme(library, rootStroke, "Color", "BorderStrong")

    self.Sidebar = create("Frame", {
        Parent = self.Root,
        Size = UDim2.new(0, self.SidebarWidth, 1, 0),
        BackgroundColor3 = library.Theme.Sidebar,
        BorderSizePixel = 0,
    })
    self.SidebarCorner = makeCorner(self.Sidebar, self.CornerRadius)
    bindTheme(library, self.Sidebar, "BackgroundColor3", "Sidebar")
    local sidebarFill = create("Frame", {
        Parent = self.Sidebar,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundColor3 = library.Theme.Sidebar,
        BorderSizePixel = 0,
    })
    bindTheme(library, sidebarFill, "BackgroundColor3", "Sidebar")

    self.SidebarDivider = create("Frame", {
        Parent = self.Root,
        Position = UDim2.new(0, self.SidebarWidth, 0, 12),
        Size = UDim2.new(0, 1, 1, -24),
        BackgroundColor3 = library.Theme.Border,
        BorderSizePixel = 0,
    })
    bindTheme(library, self.SidebarDivider, "BackgroundColor3", "Border")

    local logo = create("Frame", {
        Parent = self.Sidebar,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = library.Theme.Surface,
        BorderSizePixel = 0,
    })
    makeCorner(logo, 12)
    local logoStroke = makeStroke(logo, 1)
    logoStroke.Color = library.Theme.Border
    bindTheme(library, logo, "BackgroundColor3", "Surface")
    bindTheme(library, logoStroke, "Color", "Border")

    local footballHolder = create("Frame", {
        Parent = logo,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    })
    self.LogoIcon = createIconVisual(footballHolder, self.Icon, buildFootballIcon, library.Theme.Accent)
    setIconVisualColor(self.LogoIcon, library.Theme.Accent)

    local logoLine = create("Frame", {
        Parent = self.Sidebar,
        Position = UDim2.fromOffset(12, 60),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = library.Theme.Border,
        BorderSizePixel = 0,
    })
    bindTheme(library, logoLine, "BackgroundColor3", "Border")

    self.SidebarButtons = create("Frame", {
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 74),
        Size = UDim2.new(1, 0, 1, -82),
    })
    create("UIListLayout", {
        Parent = self.SidebarButtons,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    self.Content = create("Frame", {
        Parent = self.Root,
        Position = UDim2.new(0, self.SidebarWidth, 0, 0),
        Size = UDim2.new(1, -self.SidebarWidth, 1, 0),
        BackgroundTransparency = 1,
    })

    self.Header = create("Frame", {
        Parent = self.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
    })

    local headerLine = create("Frame", {
        Parent = self.Header,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = library.Theme.Border,
        BorderSizePixel = 0,
    })
    bindTheme(library, headerLine, "BackgroundColor3", "Border")

    self.Trail = create("Frame", {
        Parent = self.Header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 8),
        Size = UDim2.new(1, -32, 0, 28),
    })
    self.TrailLabel = create("TextLabel", {
        Parent = self.Trail,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        RichText = true,
        Text = "",
        TextColor3 = library.Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(self.TrailLabel, 18, "regular")
    bindTheme(library, self.TrailLabel, "TextColor3", "Text")

    self.Body = create("Frame", {
        Parent = self.Content,
        Position = UDim2.fromOffset(0, 50),
        Size = UDim2.new(1, 0, 1, -50),
        BackgroundTransparency = 1,
    })

    self.Inset = create("Frame", {
        Parent = self.Body,
        Position = UDim2.fromOffset(7, 7),
        Size = UDim2.new(1, -14, 1, -14),
        BackgroundColor3 = library.Theme.Inset,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    self.InsetCorner = makeCorner(self.Inset, math.max(14, self.CornerRadius - 1))
    local insetStroke = makeStroke(self.Inset, 1)
    insetStroke.Color = library.Theme.Border
    bindTheme(library, self.Inset, "BackgroundColor3", "Inset")
    bindTheme(library, insetStroke, "Color", "Border")

    self.PageHost = create("Frame", {
        Parent = self.Inset,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
    })

    if self.Footer ~= "" then
        self.FooterLabel = create("TextLabel", {
            Parent = self.Root,
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -18, 1, -10),
            Size = UDim2.fromOffset(300, 16),
            Text = self.Footer,
            TextColor3 = library.Theme.MutedText,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        applyTextStyle(self.FooterLabel, 13, "regular")
        bindTheme(library, self.FooterLabel, "TextColor3", "MutedText")
    end

    self.NotificationHolder = create("Frame", {
        Parent = self.ScreenGui,
        AnchorPoint = self.NotifySide == "Left" and Vector2.new(0, 0) or Vector2.new(1, 0),
        Position = self.NotifySide == "Left" and UDim2.fromOffset(20, 20) or UDim2.new(1, -20, 0, 20),
        Size = UDim2.fromOffset(320, 500),
        BackgroundTransparency = 1,
    })
    create("UIListLayout", {
        Parent = self.NotificationHolder,
        HorizontalAlignment = self.NotifySide == "Left" and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
    })

    self.RootScale = create("UIScale", {
        Parent = self.Root,
        Scale = self.Library.DPIScale / 100,
    })

    local dragging, dragStart, startPosition = false, nil, nil
    library:_track(self.Root.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        dragStart = input.Position
        startPosition = self.Root.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end))

    library:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.Root.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))

    library:_track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local toggleBinding = library.ToggleKeybind and library.ToggleKeybind.Value or self.ToggleKey
        if not gameProcessed and inputMatches(input, toggleBinding) then
            self:SetVisible(not self.Visible)
        end
    end))

    if UserInputService.TouchEnabled and self.ShowMobileButtons then
        local mobileButton = create("TextButton", {
            Parent = self.ScreenGui,
            AnchorPoint = self.MobileButtonsSide == "Left" and Vector2.new(0, 0.5) or Vector2.new(1, 0.5),
            Position = self.MobileButtonsSide == "Left" and UDim2.new(0, 14, 0.5, 0) or UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(42, 42),
            AutoButtonColor = false,
            BackgroundColor3 = library.Theme.Surface,
            BorderSizePixel = 0,
            Text = "M",
            TextColor3 = library.Theme.Text,
        })
        makeCorner(mobileButton, 12)
        local mobileStroke = makeStroke(mobileButton, 1)
        mobileStroke.Color = library.Theme.BorderStrong
        applyTextStyle(mobileButton, 20, "bold")
        bindTheme(library, mobileButton, "BackgroundColor3", "Surface")
        bindTheme(library, mobileButton, "TextColor3", "Text")
        bindTheme(library, mobileStroke, "Color", "BorderStrong")
        mobileButton.MouseButton1Click:Connect(function()
            self:SetVisible(not self.Visible)
        end)
        self.MobileToggleButton = mobileButton
    end

    self:_rebuildTrail()
end

function Window:SetVisible(state)
    self.Visible = state
    if self.Root then
        self.Root.Visible = state
    end
    if self.FooterLabel then
        self.FooterLabel.Visible = state
    end
    if self.NotificationHolder then
        self.NotificationHolder.Visible = state
    end
end

function Window:SetCornerRadius(radius)
    self.CornerRadius = math.max(0, tonumber(radius) or self.CornerRadius or 16)
    if self.RootCorner then
        self.RootCorner.CornerRadius = UDim.new(0, self.CornerRadius)
    end
    if self.SidebarCorner then
        self.SidebarCorner.CornerRadius = UDim.new(0, self.CornerRadius)
    end
    if self.InsetCorner then
        self.InsetCorner.CornerRadius = UDim.new(0, math.max(14, self.CornerRadius - 1))
    end
end

function Window:ChangeTitle(title)
    self.Title = tostring(title or self.Title)
    self:_rebuildTrail()
end

function Window:ChangeFooter(footer)
    self.Footer = tostring(footer or "")
    if self.FooterLabel then
        self.FooterLabel.Text = self.Footer
    end
end

function Window:UpdateTheme()
    setIconVisualColor(self.LogoIcon, self.Library.Theme.Accent)
    if self.MobileToggleButton then
        self.MobileToggleButton.BackgroundColor3 = self.Library.Theme.Surface
        self.MobileToggleButton.TextColor3 = self.Library.Theme.Text
    end
    for _, tab in ipairs(self.Tabs) do
        tab:UpdateVisual(tab == self.ActiveTab)
    end
    self:_rebuildTrail()
end

function Window:_buildSidebarButton(tab)
    local button = create("TextButton", {
        Parent = self.SidebarButtons,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(38, 42),
        Text = "",
    })
    local iconHolder = create("Frame", {
        Parent = button,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
    })
    tab.SidebarIcon = createIconVisual(iconHolder, tab.Icon, buildHumanoidIcon, self.Library.Theme.MutedText)
    tab.SidebarButton = button
    button.MouseButton1Click:Connect(function()
        self:SetTab(tab)
    end)
end

function Window:_rebuildTrail()
    if not self.TrailLabel then
        return
    end

    local theme = self.Library.Theme
    local accent = colorToHex(theme.Accent)
    local accentStrong = colorToHex(theme.AccentStrong)
    local text = colorToHex(theme.Text)
    local subText = colorToHex(theme.SubText)
    local parts = {
        string.format('<font color="%s">></font>', accent),
        string.format('<font color="%s">%s</font>', text, tostring(self.Title)),
    }

    for _, tab in ipairs(self.Tabs) do
        parts[#parts + 1] = string.format('<font color="%s">/</font>', accentStrong)
        local active = tab == self.ActiveTab
        local tabColor = active and text or subText
        parts[#parts + 1] = string.format('<font color="%s">%s</font>', tabColor, tostring(tab.Title))
    end

    self.TrailLabel.Text = table.concat(parts, " ")
end

function Window:AddTab(title, options)
    if type(title) == "table" then
        options = title
        title = options.Name or options.Title
    elseif type(options) ~= "table" then
        options = { Icon = options }
    end

    local tab = setmetatable({
        Library = self.Library,
        Window = self,
        Title = title or "Tab",
        Icon = options and options.Icon,
    }, Tab)
    tab:Build()
    self.Tabs[#self.Tabs + 1] = tab
    self:_buildSidebarButton(tab)
    self:_rebuildTrail()
    self:SetTab(self.ActiveTab or tab)
    return tab
end

function Window:AddKeyTab(title, options)
    if type(title) == "table" then
        options = title
        title = options.Name or options.Title
    elseif type(options) ~= "table" then
        options = { Icon = options }
    end
    local tab = setmetatable({
        Library = self.Library,
        Window = self,
        Title = title or "Key System",
        Icon = options and options.Icon,
        IsKeyTab = true,
    }, KeyTab)
    tab:Build()
    self.Tabs[#self.Tabs + 1] = tab
    self:_buildSidebarButton(tab)
    self:_rebuildTrail()
    self:SetTab(self.ActiveTab or tab)
    return tab
end

function Window:SetTab(tabOrName)
    local target = tabOrName
    if type(tabOrName) == "string" then
        for _, candidate in ipairs(self.Tabs) do
            if candidate.Title == tabOrName then
                target = candidate
                break
            end
        end
    end
    if not target then
        return
    end
    self.ActiveTab = target
    for _, tab in ipairs(self.Tabs) do
        local active = tab == target
        tab.Page.Visible = active
        tab:UpdateVisual(active)
    end
    if target._sync then
        task.defer(function()
            target._sync()
        end)
    end
    self:_rebuildTrail()
end

function Tab:Build()
    self.LeftItems = {}
    self.RightItems = {}

    self.Page = create("ScrollingFrame", {
        Parent = self.Window.PageHost,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
    })

    self.Canvas = create("Frame", {
        Parent = self.Page,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 0, 0),
    })

    self.LeftColumn = create("Frame", {
        Parent = self.Canvas,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    self.LeftLayout = create("UIListLayout", { Parent = self.LeftColumn, Padding = UDim.new(0, 12) })

    self.RightColumn = create("Frame", {
        Parent = self.Canvas,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    self.RightLayout = create("UIListLayout", { Parent = self.RightColumn, Padding = UDim.new(0, 12) })

    local syncQueued = false

    local function syncNow()
        syncQueued = false
        local width = self.Canvas.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local half = math.floor((width - 10) / 2)

        self.LeftColumn.Size = UDim2.fromOffset(half, self.LeftLayout.AbsoluteContentSize.Y)
        self.RightColumn.Position = UDim2.fromOffset(half + 10, 0)
        self.RightColumn.Size = UDim2.fromOffset(half, self.RightLayout.AbsoluteContentSize.Y)

        local function applyHeight(item, height)
            if item and item.Frame then
                item.Frame.Size = UDim2.new(1, 0, 0, math.max(48, math.floor(height + 0.5)))
            end
        end

        local function getNaturalHeight(item)
            if not item or not item.GetNaturalHeight then
                return item and item.Frame and item.Frame.AbsoluteSize.Y or 48
            end
            return item:GetNaturalHeight()
        end

        local pairCount = math.max(#self.LeftItems, #self.RightItems)
        for index = 1, pairCount do
            local leftItem = self.LeftItems[index]
            local rightItem = self.RightItems[index]

            if leftItem and rightItem then
                local targetHeight = math.max(getNaturalHeight(leftItem), getNaturalHeight(rightItem))
                applyHeight(leftItem, targetHeight)
                applyHeight(rightItem, targetHeight)
            else
                applyHeight(leftItem, getNaturalHeight(leftItem))
                applyHeight(rightItem, getNaturalHeight(rightItem))
            end
        end

        self.LeftColumn.Size = UDim2.fromOffset(half, self.LeftLayout.AbsoluteContentSize.Y)
        self.RightColumn.Size = UDim2.fromOffset(half, self.RightLayout.AbsoluteContentSize.Y)
        local height = math.max(self.LeftLayout.AbsoluteContentSize.Y, self.RightLayout.AbsoluteContentSize.Y)
        self.Canvas.Size = UDim2.new(1, -20, 0, height)
        self.Page.CanvasSize = UDim2.fromOffset(0, height + 20)
    end

    local function queueSync()
        if syncQueued then
            return
        end
        syncQueued = true
        task.defer(function()
            task.defer(syncNow)
        end)
    end

    self.Library:_track(self.Canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueSync))
    self.Library:_track(self.Page:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueSync))
    self.Library:_track(self.Page:GetPropertyChangedSignal("Visible"):Connect(function()
        if self.Page.Visible then
            queueSync()
        end
    end))
    self.Library:_track(self.LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(queueSync))
    self.Library:_track(self.RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(queueSync))
    self._sync = queueSync
    task.defer(queueSync)
end

function Tab:UpdateVisual(active)
    local theme = self.Library.Theme
    setIconVisualColor(self.SidebarIcon, active and theme.AccentStrong or theme.MutedText)
end
local function makeContainerFrame(library, parent, title)
    local frame = create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = library.Theme.Surface,
        BorderSizePixel = 0,
    })
    makeCorner(frame, 16)
    local stroke = makeStroke(frame, 1)
    stroke.Color = library.Theme.Border
    bindTheme(library, frame, "BackgroundColor3", "Surface")
    bindTheme(library, stroke, "Color", "Border")
    makePadding(frame, 11, 11, 10, 11)

    local header = create("Frame", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
    })
    local iconHolder = create("Frame", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(16, 16),
    })
    local headerIcon = buildHumanoidIcon(iconHolder, library.Theme.SubText)
    setIconColor(headerIcon, library.Theme.SubText)
    for _, part in ipairs(headerIcon) do
        bindTheme(library, part, "BackgroundColor3", "SubText")
    end

    local label = create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(24, -2),
        Size = UDim2.new(1, -24, 1, 0),
        Text = title,
        TextColor3 = library.Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(label, 19, "regular")
    bindTheme(library, label, "TextColor3", "Text")

    local content = create("Frame", {
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 27),
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    local layout = create("UIListLayout", { Parent = content, Padding = UDim.new(0, 7) })
    return frame, content, layout
end

function Tab:_makeContainer(kind, parent, title)
    local frame, content, layout = makeContainerFrame(self.Library, parent, title)
    local object = {
        Library = self.Library,
        Window = self.Window,
        Tab = self,
        Frame = frame,
        ContentFrame = content,
        Layout = layout,
    }
    local mt = kind == "tabbox" and Tabbox or Groupbox
    object = setmetatable(object, mt)
    object._reflow = function()
        if self._sync then
            task.defer(function()
                self._sync()
            end)
        end
    end
    function object:GetNaturalHeight()
        local bottomPadding = 10
        local contentHeight = self.Layout and self.Layout.AbsoluteContentSize.Y or self.ContentFrame.AbsoluteSize.Y
        return math.max(48, self.ContentFrame.Position.Y.Offset + contentHeight + bottomPadding)
    end

    self.Library:_track(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        object:_reflow()
    end))
    self.Library:_track(content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        object:_reflow()
    end))

    if parent == self.LeftColumn then
        self.LeftItems[#self.LeftItems + 1] = object
    else
        self.RightItems[#self.RightItems + 1] = object
    end

    return object
end

function Tab:AddLeftGroupbox(title)
    return self:_makeContainer("groupbox", self.LeftColumn, title)
end

function Tab:AddRightGroupbox(title)
    return self:_makeContainer("groupbox", self.RightColumn, title)
end

function Tab:AddLeftTabbox(title)
    return self:_makeContainer("tabbox", self.LeftColumn, title or "Tabbox")
end

function Tab:AddRightTabbox(title)
    return self:_makeContainer("tabbox", self.RightColumn, title or "Tabbox")
end

function Tab:AddGroupbox(info, icon)
    if type(info) == "table" then
        return (info.Side == 2 and self:AddRightGroupbox(info.Name or "Groupbox", info.IconName or icon) or self:AddLeftGroupbox(info.Name or "Groupbox", info.IconName or icon))
    end
    return self:AddLeftGroupbox(info, icon)
end

function Tab:AddTabbox(info)
    if type(info) == "table" then
        return info.Side == 2 and self:AddRightTabbox(info.Name) or self:AddLeftTabbox(info.Name)
    end
    return self:AddLeftTabbox(info)
end

local function evaluateDependencies(host)
    local visible = true
    for _, dependency in ipairs(host.Dependencies or {}) do
        local option = dependency.Option
        if type(option) == "string" then
            option = host.Library:GetOption(option)
        end
        local current = option and option.GetValue and option:GetValue() or nil
        local passes = dependency.Predicate and dependency.Predicate(current) or (type(current) == "table" and tableContains(current, dependency.ExpectedValue) or current == dependency.ExpectedValue)
        if not passes then
            visible = false
            break
        end
    end
    host.Frame.Visible = visible
    if host._reflow then
        host:_reflow()
    end
end

local function attachElementCommon(option)
    option.Changed = signal()
    option.Visible = option.Visible ~= false
    option.Disabled = option.Disabled == true
    option.ParentContainer = option.ParentContainer
    function option:GetValue()
        return self.Value
    end
    function option:OnChanged(callback)
        return self.Changed:Connect(callback)
    end
    function option:TriggerChanged()
        self.Changed:Fire(self.Value)
        self.Library:_safeCallback(self.Callback, self.Value)
    end
    function option:AddDependency(other, expectedValue, predicate)
        self.Dependencies = self.Dependencies or {}
        self.Dependencies[#self.Dependencies + 1] = { Option = other, ExpectedValue = expectedValue, Predicate = predicate }
        local target = type(other) == "string" and self.Library:GetOption(other) or other
        if target and target.OnChanged then
            target:OnChanged(function()
                evaluateDependencies(self)
            end)
        end
        evaluateDependencies(self)
        return self
    end
    function option:SetVisible(visible)
        self.Visible = visible and true or false
        if self.Frame then
            self.Frame.Visible = self.Visible
        end
        if self._reflow then
            self:_reflow()
        end
    end
    function option:SetDisabled(disabled)
        self.Disabled = disabled and true or false
        if self.UpdateTheme then
            self:UpdateTheme()
        end
    end
    function option:SetText(text)
        self.Text = text
        if self.Label then
            self.Label.Text = text
        elseif self.TextLabel then
            self.TextLabel.Text = text
        end
        if self._reflow then
            self:_reflow()
        end
    end
    function option:AddColorPicker(index, info)
        assert(self.ParentContainer and self.ParentContainer.AddColorPicker, "Color picker addons require a parent container")
        info = info or {}
        if info.Text == nil then
            info.Text = info.Title or self.Text
        end
        return self.ParentContainer:AddColorPicker(index, info)
    end
    function option:AddKeyPicker(index, info)
        assert(self.ParentContainer and self.ParentContainer.AddKeybind, "Key picker addons require a parent container")
        info = info or {}
        if info.Text == nil then
            info.Text = info.Title or self.Text
        end
        if info.SyncTarget == nil then
            info.SyncTarget = self
        end
        if info.SyncToggleState == nil and (self.Type == "toggle" or self.Type == "checkbox") then
            info.SyncToggleState = true
        end
        return self.ParentContainer:AddKeybind(index, info)
    end
    return option
end

function Groupbox:AddDependencyBox()
    local holder = create("Frame", {
        Parent = self.ContentFrame,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    local content = create("Frame", {
        Parent = holder,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    local layout = create("UIListLayout", { Parent = content, Padding = UDim.new(0, 8) })
    return setmetatable({
        Library = self.Library,
        Window = self.Window,
        Tab = self.Tab,
        Frame = holder,
        ContentFrame = content,
        Layout = layout,
        Dependencies = {},
        _reflow = self._reflow,
    }, DependencyBox)
end

function Groupbox:AddDependencyGroupbox()
    return self:AddDependencyBox()
end

function DependencyBox:AddDependency(other, expectedValue, predicate)
    self.Dependencies[#self.Dependencies + 1] = { Option = other, ExpectedValue = expectedValue, Predicate = predicate }
    local target = type(other) == "string" and self.Library:GetOption(other) or other
    if target and target.OnChanged then
        target:OnChanged(function()
            evaluateDependencies(self)
        end)
    end
    evaluateDependencies(self)
    return self
end

local function addSimpleLabel(container, textOrConfig, doesWrap, idx)
    local config = parseLabelConfig(textOrConfig, doesWrap, idx)
    local frame = create("Frame", {
        Parent = container.ContentFrame,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    local label = create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Text = config.Text or "",
        TextWrapped = config.DoesWrap == true,
        TextColor3 = container.Library.Theme[config.ColorToken or "SubText"],
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = config.DoesWrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
    })
    applyTextStyle(label, config.Size or 18, config.Weight or "regular")
    bindTheme(container.Library, label, "TextColor3", config.ColorToken or "SubText")
    local wrapper = {
        Library = container.Library,
        ParentContainer = container,
        Frame = frame,
        Label = label,
        Text = config.Text or "",
        Visible = config.Visible ~= false,
        Disabled = false,
        Type = "label",
    }

    if config.Flag then
        container.Library.Labels[config.Flag] = wrapper
    end
    frame.Visible = wrapper.Visible

    function wrapper:SetVisible(visible)
        self.Visible = visible and true or false
        self.Frame.Visible = self.Visible
        if container._reflow then
            container:_reflow()
        end
    end

    function wrapper:SetText(newText)
        self.Text = newText
        self.Label.Text = newText
        if container._reflow then
            container:_reflow()
        end
    end

    function wrapper:AddColorPicker(index, info)
        info = info or {}
        if info.Text == nil then
            info.Text = info.Title or self.Text
        end
        return container:AddColorPicker(index, info)
    end

    function wrapper:AddKeyPicker(index, info)
        info = info or {}
        if info.Text == nil then
            info.Text = self.Text
        end
        return container:AddKeybind(index, info)
    end

    return wrapper
end

Groupbox.AddLabel = addSimpleLabel
DependencyBox.AddLabel = addSimpleLabel
TabboxPage.AddLabel = addSimpleLabel

local function addDivider(container, text)
    local frame = create("Frame", {
        Parent = container.ContentFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
    })
    local line = create("Frame", {
        Parent = frame,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = container.Library.Theme.Border,
        BorderSizePixel = 0,
    })
    bindTheme(container.Library, line, "BackgroundColor3", "Border")
    if text and text ~= "" then
        local label = create("TextLabel", {
            Parent = frame,
            BackgroundColor3 = container.Library.Theme.Surface,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 16),
            Text = text,
            TextColor3 = container.Library.Theme.MutedText,
        })
        applyTextStyle(label, 14, "medium")
        bindTheme(container.Library, label, "BackgroundColor3", "Surface")
        bindTheme(container.Library, label, "TextColor3", "MutedText")
    end
    return { Frame = frame }
end

Groupbox.AddDivider = addDivider
DependencyBox.AddDivider = addDivider
TabboxPage.AddDivider = addDivider

local function addButton(container, textOrConfig, maybeConfig)
    local config = parseButtonConfig(textOrConfig, maybeConfig)
    local button = create("TextButton", {
        Parent = container.ContentFrame,
        AutoButtonColor = false,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Text = config.Text or "Button",
        TextColor3 = config.Risky and Color3.fromRGB(255, 155, 155) or container.Library.Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    applyTextStyle(button, 18, "medium")
    makeCorner(button, 9)
    local stroke = makeStroke(button, 1)
    stroke.Color = container.Library.Theme.Border
    bindTheme(container.Library, button, "BackgroundColor3", "Input")
    bindTheme(container.Library, stroke, "Color", "Border")

    local object = attachElementCommon(setmetatable({
        Library = container.Library,
        ParentContainer = container,
        Type = "button",
        Text = config.Text or "Button",
        Flag = config.Flag,
        Callback = config.Func or config.Callback,
        DoubleClick = config.DoubleClick == true,
        Risky = config.Risky == true,
        Disabled = config.Disabled == true,
        Visible = config.Visible ~= false,
        Frame = button,
        Label = button,
        Stroke = stroke,
        _lastClick = 0,
        _reflow = container._reflow,
    }, Element))

    function object:UpdateTheme()
        local theme = self.Library.Theme
        self.Frame.AutoButtonColor = false
        self.Frame.Active = not self.Disabled
        self.Frame.Selectable = not self.Disabled
        self.Frame.BackgroundColor3 = self.Disabled and theme.Surface or theme.Input
        self.Stroke.Color = self.Disabled and theme.Border or theme.BorderStrong
        if self.Risky then
            self.Label.TextColor3 = self.Disabled and Color3.fromRGB(120, 84, 84) or Color3.fromRGB(255, 155, 155)
        else
            self.Label.TextColor3 = self.Disabled and theme.MutedText or theme.Text
        end
        applyActiveText(self.Label, not self.Disabled)
    end

    function object:SetText(text)
        self.Text = tostring(text or "")
        self.Label.Text = self.Text
    end

    local function runClick()
        if object.Disabled then
            return
        end
        if object.DoubleClick then
            local now = tick()
            if now - object._lastClick > 0.35 then
                object._lastClick = now
                return
            end
        end
        object._lastClick = tick()
        object.Library:_safeCallback(object.Callback)
    end

    button.MouseEnter:Connect(function()
        if not object.Disabled then
            button.BackgroundColor3 = container.Library.Theme.InputHover
        end
    end)
    button.MouseLeave:Connect(function()
        object:UpdateTheme()
    end)
    button.MouseButton1Click:Connect(runClick)

    function object:AddButton(info, func)
        return container:AddButton(info, func)
    end

    object.Flag = object.Flag or container.Library:_nextFlag(object.Text)
    container.Library.Buttons[object.Flag] = object
    object.Frame.Visible = object.Visible
    object:UpdateTheme()
    return object
end

Groupbox.AddButton = addButton
DependencyBox.AddButton = addButton
TabboxPage.AddButton = addButton

local function createRow(container, height)
    return create("Frame", {
        Parent = container.ContentFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height),
    })
end

local addCheckbox

local function addToggle(container, flagOrConfig, maybeConfig)
    if container.Library.ForceCheckbox then
        return addCheckbox(container, flagOrConfig, maybeConfig)
    end
    local config = parseFlagConfig(flagOrConfig, maybeConfig)
    local text = config.Text or config.Flag or "Toggle"
    local row = createRow(container, 34)
    local label = create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -58, 1, 0),
        Text = text,
        TextColor3 = container.Library.Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(label, 18, "regular")
    local button = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(42, 22),
        AutoButtonColor = false,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Text = "",
    })
    makeCorner(button, 11)
    local knob = create("Frame", {
        Parent = button,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = container.Library.Theme.AccentMuted,
        BorderSizePixel = 0,
    })
    makeCorner(knob, 7)

    local option = attachElementCommon(setmetatable({
        Library = container.Library,
        ParentContainer = container,
        Type = "toggle",
        Text = text,
        Flag = config.Flag,
        Save = config.Save ~= false,
        Callback = config.Callback or config.Changed,
        Frame = row,
        Label = label,
        Button = button,
        Knob = knob,
        Value = config.Default == true,
        Risky = config.Risky == true,
        Visible = config.Visible ~= false,
        Disabled = config.Disabled == true,
        _reflow = container._reflow,
    }, Element))
    container.Library:_registerOption(option)
    container.Library.Toggles[option.Flag] = option

    function option:UpdateTheme()
        local theme = self.Library.Theme
        local textColor = self.Value and theme.Text or theme.SubText
        if self.Risky and self.Value then
            textColor = Color3.fromRGB(255, 155, 155)
        elseif self.Disabled then
            textColor = theme.MutedText
        end
        self.Label.TextColor3 = textColor
        self.Button.BackgroundColor3 = self.Disabled and theme.Surface or (self.Value and (theme.ToggleOn or theme.BorderStrong) or theme.Input)
        self.Knob.BackgroundColor3 = self.Disabled and theme.MutedText or (self.Value and (theme.ToggleKnobOn or theme.Accent) or theme.AccentMuted)
        applyActiveText(self.Label, self.Value and not self.Disabled)
    end
    function option:SetValue(value, silent)
        self.Value = value and true or false
        tween(self.Knob, { Position = self.Value and UDim2.new(0, 24, 0.5, 0) or UDim2.new(0, 4, 0.5, 0) })
        self:UpdateTheme()
        if not silent then
            self:TriggerChanged()
        end
    end
    button.MouseButton1Click:Connect(function()
        if option.Disabled then
            return
        end
        option:SetValue(not option.Value)
    end)
    option.Frame.Visible = option.Visible
    option:SetValue(option.Value, true)
    return option
end

Groupbox.AddToggle = addToggle
DependencyBox.AddToggle = addToggle
TabboxPage.AddToggle = addToggle

addCheckbox = function(container, flagOrConfig, maybeConfig)
    local config = parseFlagConfig(flagOrConfig, maybeConfig)
    local text = config.Text or config.Flag or "Checkbox"
    local row = createRow(container, 34)
    local label = create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 1, 0),
        Text = text,
        TextColor3 = container.Library.Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(label, 18, "regular")
    local button = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        AutoButtonColor = false,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Text = "",
    })
    makeCorner(button, 5)
    local fill = create("Frame", {
        Parent = button,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = container.Library.Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
    })
    makeCorner(fill, 3)

    local option = attachElementCommon(setmetatable({
        Library = container.Library,
        ParentContainer = container,
        Type = "checkbox",
        Text = text,
        Flag = config.Flag,
        Save = config.Save ~= false,
        Callback = config.Callback or config.Changed,
        Frame = row,
        Label = label,
        Fill = fill,
        Value = config.Default == true,
        Risky = config.Risky == true,
        Visible = config.Visible ~= false,
        Disabled = config.Disabled == true,
        _reflow = container._reflow,
    }, Element))
    container.Library:_registerOption(option)
    container.Library.Toggles[option.Flag] = option

    function option:UpdateTheme()
        local theme = self.Library.Theme
        local textColor = self.Value and theme.Text or theme.SubText
        if self.Risky and self.Value then
            textColor = Color3.fromRGB(255, 155, 155)
        elseif self.Disabled then
            textColor = theme.MutedText
        end
        self.Label.TextColor3 = textColor
        self.Fill.BackgroundColor3 = self.Disabled and theme.MutedText or theme.Accent
        applyActiveText(self.Label, self.Value and not self.Disabled)
    end
    function option:SetValue(value, silent)
        self.Value = value and true or false
        self.Fill.Visible = self.Value
        self:UpdateTheme()
        if not silent then
            self:TriggerChanged()
        end
    end
    button.MouseButton1Click:Connect(function()
        if option.Disabled then
            return
        end
        option:SetValue(not option.Value)
    end)
    option.Frame.Visible = option.Visible
    option:SetValue(option.Value, true)
    return option
end

Groupbox.AddCheckbox = addCheckbox
DependencyBox.AddCheckbox = addCheckbox
TabboxPage.AddCheckbox = addCheckbox
local function addInput(container, flagOrConfig, maybeConfig)
    local config = parseFlagConfig(flagOrConfig, maybeConfig)
    local text = config.Text or config.Flag or "Input"
    local frame = create("Frame", {
        Parent = container.ContentFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 62),
    })
    local label = create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Text = text,
        TextColor3 = container.Library.Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(label, 18, "regular")
    local box = create("TextBox", {
        Parent = frame,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 26),
        Size = UDim2.new(1, 0, 0, 36),
        PlaceholderText = config.Placeholder or "",
        Text = tostring(config.Default or ""),
        TextColor3 = container.Library.Theme.Text,
        PlaceholderColor3 = container.Library.Theme.MutedText,
        ClearTextOnFocus = config.ClearTextOnFocus == true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(box, 16, "medium")
    makeCorner(box, 8)
    makePadding(box, 12, 12, 0, 0)

    local option = attachElementCommon(setmetatable({
        Library = container.Library,
        ParentContainer = container,
        Type = "input",
        Text = text,
        Flag = config.Flag,
        Save = config.Save ~= false,
        Callback = config.Callback or config.Changed,
        Numeric = config.Numeric == true,
        MaxLength = config.MaxLength,
        Finished = config.Finished == true,
        AllowEmpty = config.AllowEmpty ~= false,
        EmptyReset = config.EmptyReset or tostring(config.Default or ""),
        Visible = config.Visible ~= false,
        Disabled = config.Disabled == true,
        Frame = frame,
        Label = label,
        Box = box,
        Value = tostring(config.Default or ""),
        _reflow = container._reflow,
    }, Element))
    container.Library:_registerOption(option)

    function option:UpdateTheme()
        self.Label.TextColor3 = self.Disabled and self.Library.Theme.MutedText or self.Library.Theme.SubText
        self.Box.BackgroundColor3 = self.Disabled and self.Library.Theme.Surface or self.Library.Theme.Input
        self.Box.TextColor3 = self.Disabled and self.Library.Theme.MutedText or self.Library.Theme.Text
        self.Box.PlaceholderColor3 = self.Library.Theme.MutedText
        applyActiveText(self.Label, not self.Disabled and self.Box:IsFocused())
    end
    function option:SetValue(value, silent)
        local textValue = tostring(value or "")
        if self.Numeric then
            textValue = textValue:gsub("[^%d%.%-]", "")
        end
        if self.MaxLength then
            textValue = textValue:sub(1, self.MaxLength)
        end
        if textValue == "" and not self.AllowEmpty then
            textValue = self.EmptyReset
        end
        self.Value = textValue
        self.Box.Text = textValue
        if not silent then
            self:TriggerChanged()
        end
    end
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if option.Disabled or option.Finished then
            return
        end
        option:SetValue(box.Text)
    end)
    box.Focused:Connect(function()
        option:UpdateTheme()
    end)
    box.FocusLost:Connect(function(enterPressed)
        option:UpdateTheme()
        if option.Disabled then
            option.Box.Text = option.Value
            return
        end
        if option.Finished then
            if enterPressed or box.Text ~= option.Value then
                option:SetValue(box.Text)
            end
        elseif box.Text ~= option.Value then
            option:SetValue(box.Text)
        end
    end)
    option.Frame.Visible = option.Visible
    option:SetValue(option.Value, true)
    return option
end

Groupbox.AddInput = addInput
DependencyBox.AddInput = addInput
TabboxPage.AddInput = addInput

local function addSlider(container, flagOrConfig, maybeConfig)
    local config = parseFlagConfig(flagOrConfig, maybeConfig)
    local text = config.Text or config.Flag or "Slider"
    local minimum = config.Min or 0
    local maximum = config.Max or 100
    local decimals = config.Decimals ~= nil and config.Decimals or (config.Rounding or 0)
    local compact = config.Compact == true

    local frame = create("Frame", {
        Parent = container.ContentFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, compact and 36 or 72),
    })
    local label = create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Visible = not compact,
        Size = UDim2.new(1, -72, 0, 24),
        Text = text,
        TextColor3 = container.Library.Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(label, 18, "medium")
    local valueBox = create("TextBox", {
        Parent = frame,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, compact and -1 or -1),
        Size = UDim2.fromOffset(60, 28),
        Text = "",
        TextColor3 = container.Library.Theme.SubText,
        PlaceholderText = "",
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    applyTextStyle(valueBox, 16, "regular")
    makeCorner(valueBox, 6)
    local bar = create("TextButton", {
        Parent = frame,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, compact and 24 or 48),
        Size = UDim2.new(1, 0, 0, 6),
        AutoButtonColor = false,
        Text = "",
    })
    makeCorner(bar, 6)
    local fill = create("Frame", {
        Parent = bar,
        BackgroundColor3 = container.Library.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
    })
    makeCorner(fill, 6)
    local thumb = create("Frame", {
        Parent = bar,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(20, 14),
        BackgroundColor3 = container.Library.Theme.AccentStrong,
        BorderSizePixel = 0,
    })
    makeCorner(thumb, 7)

    local option = attachElementCommon(setmetatable({
        Library = container.Library,
        ParentContainer = container,
        Type = "slider",
        Text = text,
        Flag = config.Flag,
        Save = config.Save ~= false,
        Callback = config.Callback or config.Changed,
        Frame = frame,
        Label = label,
        ValueBox = valueBox,
        Bar = bar,
        Fill = fill,
        Thumb = thumb,
        Min = minimum,
        Max = maximum,
        Decimals = decimals,
        Increment = config.Increment,
        Prefix = config.Prefix or "",
        Suffix = config.Suffix or "",
        Compact = compact,
        HideMax = config.HideMax == true,
        FormatDisplayValue = config.FormatDisplayValue,
        Visible = config.Visible ~= false,
        Disabled = config.Disabled == true,
        Value = roundTo(config.Default or minimum, decimals, config.Increment),
        _reflow = container._reflow,
    }, Element))
    container.Library:_registerOption(option)

    function option:UpdateTheme()
        self.Label.TextColor3 = self.Disabled and self.Library.Theme.MutedText or self.Library.Theme.Text
        self.ValueBox.TextColor3 = self.Disabled and self.Library.Theme.MutedText or self.Library.Theme.SubText
        self.ValueBox.BackgroundColor3 = self.Disabled and self.Library.Theme.Surface or self.Library.Theme.Input
        self.ValueBox.TextEditable = not self.Disabled
        self.Bar.BackgroundColor3 = self.Disabled and self.Library.Theme.Surface or self.Library.Theme.Input
        self.Fill.BackgroundColor3 = self.Disabled and self.Library.Theme.MutedText or self.Library.Theme.Accent
        self.Thumb.BackgroundColor3 = self.Disabled and self.Library.Theme.MutedText or self.Library.Theme.AccentStrong
        applyActiveText(self.Label, not self.Disabled)
    end
    function option:_formatValue(value)
        local display = getDisplayValue(self, value)
        if display ~= tostring(value) then
            return display
        end
        local rounded = roundTo(value, self.Decimals, self.Increment)
        if self.HideMax or self.Compact then
            return self.Prefix .. tostring(rounded) .. self.Suffix
        end
        return self.Prefix .. tostring(rounded) .. self.Suffix
    end
    function option:SetValue(value, silent)
        local numericValue = tonumber(value) or self.Min
        local clamped = roundTo(clamp(numericValue, self.Min, self.Max), self.Decimals, self.Increment)
        self.Value = clamped
        local percent = (clamped - self.Min) / math.max(self.Max - self.Min, 0.00001)
        self.Fill.Size = UDim2.fromScale(percent, 1)
        self.Thumb.Position = UDim2.new(percent, 0, 0.5, 0)
        if not self._editingValue then
            self.ValueBox.Text = self:_formatValue(clamped)
        end
        if not silent then
            self:TriggerChanged()
        end
    end
    function option:SetMax(value)
        self.Max = tonumber(value) or self.Max
        self:SetValue(self.Value, true)
    end
    function option:SetMin(value)
        self.Min = tonumber(value) or self.Min
        self:SetValue(self.Value, true)
    end
    function option:SetPrefix(value)
        self.Prefix = tostring(value or "")
        self:SetValue(self.Value, true)
    end
    function option:SetSuffix(value)
        self.Suffix = tostring(value or "")
        self:SetValue(self.Value, true)
    end

    local dragging = false
    local function updateFromInput(input)
        if option.Disabled then
            return
        end
        local relative = (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
        option:SetValue(option.Min + (option.Max - option.Min) * clamp(relative, 0, 1))
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        updateFromInput(input)
    end)
    valueBox.Focused:Connect(function()
        option._editingValue = true
        valueBox.Text = tostring(roundTo(option.Value, option.Decimals, option.Increment))
        option:UpdateTheme()
    end)
    valueBox.FocusLost:Connect(function()
        option._editingValue = false
        local raw = tostring(valueBox.Text or ""):gsub("[^%d%.%-]", "")
        local numberValue = tonumber(raw)
        if numberValue ~= nil then
            option:SetValue(numberValue)
        else
            option:SetValue(option.Value, true)
        end
        option:UpdateTheme()
    end)
    container.Library:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end))
    container.Library:_track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    option.Frame.Visible = option.Visible
    option:SetValue(option.Value, true)
    return option
end

Groupbox.AddSlider = addSlider
DependencyBox.AddSlider = addSlider
TabboxPage.AddSlider = addSlider

local function addDropdown(container, flagOrConfig, maybeConfig)
    local config = parseFlagConfig(flagOrConfig, maybeConfig)
    local text = config.Text or config.Flag or "Dropdown"
    local frame = create("Frame", {
        Parent = container.ContentFrame,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
    })
    local row = create("Frame", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
    })
    local label = create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -160, 1, 0),
        Text = text,
        TextColor3 = container.Library.Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(label, 18, "medium")
    local button = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(140, 30),
        AutoButtonColor = false,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Text = "",
    })
    makeCorner(button, 7)
    local selected = create("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Text = "",
        TextColor3 = container.Library.Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    applyTextStyle(selected, 16, "regular")
    local listHolder = create("Frame", {
        Parent = frame,
        BackgroundColor3 = container.Library.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
    })
    makeCorner(listHolder, 9)
    local listPadding = makePadding(listHolder, 6, 6, 6, 6)
    local searchBox = create("TextBox", {
        Parent = listHolder,
        Visible = config.Searchable == true,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26),
        PlaceholderText = "Search...",
        PlaceholderColor3 = container.Library.Theme.MutedText,
        Text = "",
        TextColor3 = container.Library.Theme.Text,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(searchBox, 16, "regular")
    makeCorner(searchBox, 7)
    makePadding(searchBox, 8, 8, 0, 0)
    local list = create("ScrollingFrame", {
        Parent = listHolder,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, config.Searchable == true and 30 or 0),
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = container.Library.Theme.BorderStrong,
        Size = UDim2.new(1, 0, 0, 0),
    })
    local listLayout = create("UIListLayout", { Parent = list, Padding = UDim.new(0, 2) })

    local option = attachElementCommon(setmetatable({
        Library = container.Library,
        ParentContainer = container,
        Type = "dropdown",
        Text = text,
        Flag = config.Flag,
        Save = config.Save ~= false,
        Callback = config.Callback or config.Changed,
        Frame = frame,
        Label = label,
        Button = button,
        Selected = selected,
        ListHolder = listHolder,
        SearchBox = searchBox,
        List = list,
        Values = deepCopy(config.Values or {}),
        DisabledValues = deepCopy(config.DisabledValues or {}),
        DisabledLookup = buildLookup(config.DisabledValues),
        Multi = config.Multi == true,
        AllowNull = config.AllowNull == true,
        Searchable = config.Searchable == true,
        SearchQuery = "",
        SpecialType = config.SpecialType,
        ExcludeLocalPlayer = config.ExcludeLocalPlayer == true,
        MaxVisibleDropdownItems = config.MaxVisibleDropdownItems or 8,
        FormatDisplayValue = config.FormatDisplayValue,
        Visible = config.Visible ~= false,
        Disabled = config.Disabled == true,
        Open = false,
        Value = config.Multi and normalizeMultiSelection(config.Default or {}) or config.Default,
        _reflow = container._reflow,
    }, Element))
    container.Library:_registerOption(option)

    local function getFilteredValues()
        local source = option.SpecialType and (getSpecialValues(option) or {}) or option.Values
        local filtered = {}
        local search = string.lower(option.SearchQuery or "")
        for _, value in ipairs(source) do
            local textValue = tostring(getDisplayValue(option, value))
            if search == "" or string.find(string.lower(textValue), search, 1, true) then
                filtered[#filtered + 1] = value
            end
        end
        return filtered
    end

    function option:UpdateTheme()
        local theme = self.Library.Theme
        self.Label.TextColor3 = self.Disabled and theme.MutedText or theme.Text
        self.Button.BackgroundColor3 = self.Disabled and theme.Surface or theme.Input
        self.Selected.TextColor3 = self.Disabled and theme.MutedText or theme.SubText
        self.ListHolder.BackgroundColor3 = theme.Surface
        self.List.ScrollBarImageColor3 = theme.BorderStrong
        self.SearchBox.BackgroundColor3 = self.Disabled and theme.Surface or theme.Input
        self.SearchBox.TextColor3 = self.Disabled and theme.MutedText or theme.Text
        self.SearchBox.PlaceholderColor3 = theme.MutedText
        applyActiveText(self.Label, not self.Disabled)
        if self.Open then
            self:BuildDropdownList()
        end
    end

    function option:GetActiveValues()
        if not self.Multi then
            return self.Value
        end
        local values = {}
        for key, enabled in pairs(self.Value or {}) do
            if enabled then
                values[#values + 1] = key
            end
        end
        return values
    end

    function option:_displaySelected()
        if self.Multi then
            local count = valueCount(self.Value)
            if count == 0 then
                self.Selected.Text = "None"
                return
            end
            local active = shallowKeysSorted(self.Value)
            self.Selected.Text = count == 1 and active[1] or (tostring(count) .. " selected")
        else
            local current = self.Value
            self.Selected.Text = current == nil and "None" or tostring(getDisplayValue(self, current))
        end
    end

    function option:RecalculateListSize(count)
        local visibleCount = count or #getFilteredValues()
        local rowCount = math.min(visibleCount, self.MaxVisibleDropdownItems)
        local searchHeight = self.Searchable and 34 or 0
        local paddingHeight = 12
        self.List.Size = UDim2.new(1, 0, 0, rowCount * 30)
        self.List.CanvasSize = UDim2.new(0, 0, 0, math.max(0, visibleCount * 30))
        self.ListHolder.Size = UDim2.new(1, 0, 0, self.Open and (rowCount * 30 + searchHeight + paddingHeight) or 0)
    end

    function option:BuildDropdownList()
        for _, child in ipairs(self.List:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end

        local values = getFilteredValues()
        local includeNull = self.AllowNull and not self.Multi

        local function buildEntry(value)
            local disabledValue = value ~= nil and self.DisabledLookup[value] == true
            local active = self.Multi and self.Value[value] == true or self.Value == value
            local entry = create("TextButton", {
                Parent = self.List,
                AutoButtonColor = false,
                BackgroundColor3 = active and self.Library.Theme.BorderStrong or self.Library.Theme.Input,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 30),
                Text = value == nil and "None" or tostring(getDisplayValue(self, value)),
                TextColor3 = disabledValue and self.Library.Theme.MutedText or (active and self.Library.Theme.Text or self.Library.Theme.SubText),
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
    applyTextStyle(entry, 18, active and "medium" or "regular")
            makeCorner(entry, 7)
            applyActiveText(entry, active)
            entry.MouseEnter:Connect(function()
                if not self.Disabled and not disabledValue then
                    entry.BackgroundColor3 = active and self.Library.Theme.BorderStrong or self.Library.Theme.InputHover
                end
            end)
            entry.MouseLeave:Connect(function()
                entry.BackgroundColor3 = active and self.Library.Theme.BorderStrong or self.Library.Theme.Input
            end)
            entry.MouseButton1Click:Connect(function()
                if self.Disabled or disabledValue then
                    return
                end
                if self.Multi then
                    local nextValue = deepCopy(self.Value or {})
                    nextValue[value] = not nextValue[value] or nil
                    if nextValue[value] == false then
                        nextValue[value] = nil
                    end
                    self:SetValue(nextValue)
                else
                    self:SetValue(value)
                    self.Open = false
                    self.ListHolder.Visible = false
                    self:RecalculateListSize(0)
                    if self._reflow then
                        self:_reflow()
                    end
                end
            end)
        end

        if includeNull then
            buildEntry(nil)
        end

        for _, rawValue in ipairs(values) do
            buildEntry(rawValue)
        end

        self:RecalculateListSize(#values + (includeNull and 1 or 0))
    end

    function option:SetValue(value, silent)
        if self.Multi then
            local nextValue = normalizeMultiSelection(value)
            local sanitized = {}
            for item in pairs(nextValue) do
                if valueExists(self.Values, item) or self.SpecialType then
                    sanitized[item] = true
                end
            end
            self.Value = sanitized
        else
            if value ~= nil and not self.SpecialType and not valueExists(self.Values, value) then
                value = self.AllowNull and nil or self.Values[1]
            end
            self.Value = value
        end
        self:_displaySelected()
        self:BuildDropdownList()
        if not silent then
            self:TriggerChanged()
        end
    end

    function option:SetValues(values)
        self.Values = deepCopy(values or {})
        if not self.Multi and not self.SpecialType then
            if self.Value ~= nil and not valueExists(self.Values, self.Value) then
                self.Value = self.AllowNull and nil or self.Values[1]
            elseif self.Value == nil and not self.AllowNull then
                self.Value = self.Values[1]
            end
        end
        self:BuildDropdownList()
        self:_displaySelected()
    end

    function option:AddValues(values)
        if type(values) ~= "table" then
            values = { values }
        end
        for _, value in ipairs(values) do
            self.Values[#self.Values + 1] = value
        end
        self:SetValues(self.Values)
    end

    function option:SetDisabledValues(values)
        self.DisabledValues = deepCopy(values or {})
        self.DisabledLookup = buildLookup(self.DisabledValues)
        self:BuildDropdownList()
    end

    function option:AddDisabledValues(values)
        if type(values) ~= "table" then
            values = { values }
        end
        for _, value in ipairs(values) do
            self.DisabledValues[#self.DisabledValues + 1] = value
        end
        self:SetDisabledValues(self.DisabledValues)
    end

    function option:RefreshSpecialValues()
        if self.SpecialType then
            self.Values = getSpecialValues(self) or {}
            self:BuildDropdownList()
            self:_displaySelected()
        end
    end

    button.MouseButton1Click:Connect(function()
        if option.Disabled then
            return
        end
        option.Open = not option.Open
        option.ListHolder.Visible = option.Open
        option:BuildDropdownList()
        if option._reflow then option:_reflow() end
    end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        option.SearchQuery = searchBox.Text
        option:BuildDropdownList()
        if option._reflow then
            option:_reflow()
        end
    end)

    if option.SpecialType == "Player" then
        container.Library:_track(Players.PlayerAdded:Connect(function()
            option:RefreshSpecialValues()
        end))
        container.Library:_track(Players.PlayerRemoving:Connect(function()
            option:RefreshSpecialValues()
        end))
        option.Values = getSpecialValues(option) or {}
    elseif option.SpecialType == "Team" then
        container.Library:_track(TeamsService.ChildAdded:Connect(function()
            option:RefreshSpecialValues()
        end))
        container.Library:_track(TeamsService.ChildRemoved:Connect(function()
            option:RefreshSpecialValues()
        end))
        option.Values = getSpecialValues(option) or {}
    end

    if option.Value == nil and not option.Multi and not option.AllowNull then
        option.Value = option.Values[1]
    end

    option.Frame.Visible = option.Visible
    option:SetValue(option.Value or (option.Multi and {} or nil), true)
    return option
end

Groupbox.AddDropdown = addDropdown
DependencyBox.AddDropdown = addDropdown
TabboxPage.AddDropdown = addDropdown
local function addKeybind(container, flagOrConfig, maybeConfig)
    local config = parseFlagConfig(flagOrConfig, maybeConfig)
    local text = config.Text or config.Flag or "Keybind"
    local row = createRow(container, 36)
    local label = create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -164, 1, 0),
        Text = text,
        TextColor3 = container.Library.Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(label, 18, "medium")

    local modeButton = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(68, 28),
        AutoButtonColor = false,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Text = "",
    })
    makeCorner(modeButton, 7)
    local modeLabel = create("TextLabel", {
        Parent = modeButton,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "Toggle",
        TextColor3 = container.Library.Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    applyTextStyle(modeLabel, 16, "medium")

    local button = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -74, 0.5, 0),
        Size = UDim2.fromOffset(84, 28),
        AutoButtonColor = false,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Text = "",
    })
    makeCorner(button, 7)
    local valueLabel = create("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "None",
        TextColor3 = container.Library.Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    applyTextStyle(valueLabel, 18, "regular")

    local option = attachElementCommon(setmetatable({
        Library = container.Library,
        ParentContainer = container,
        Type = "keybind",
        Text = text,
        Flag = config.Flag,
        Save = config.Save ~= false,
        Callback = config.Callback,
        ChangedCallback = config.ChangedCallback or config.Changed,
        SyncToggleState = config.SyncToggleState == true,
        SyncTarget = config.SyncTarget,
        WaitForCallback = config.WaitForCallback == true,
        Modes = deepCopy(config.Modes or { "Always", "Toggle", "Hold", "Press" }),
        Mode = config.Mode or "Toggle",
        Modifiers = deepCopy(config.Modifiers or config.DefaultModifiers or {}),
        NoUI = config.NoUI == true,
        Visible = config.Visible ~= false,
        Disabled = config.Disabled == true,
        Frame = row,
        Label = label,
        Button = button,
        ModeButton = modeButton,
        ValueLabel = valueLabel,
        ModeLabel = modeLabel,
        Capturing = false,
        Clicked = signal(),
        State = config.Mode == "Always",
        Value = inputFromName(type(config.Default) == "table" and config.Default[1] or config.Default),
        _reflow = container._reflow,
    }, Element))
    container.Library:_registerOption(option)
    container.Library._keybinds[#container.Library._keybinds + 1] = option
    option.Changed = signal()

    function option:UpdateTheme()
        local theme = self.Library.Theme
        self.Label.TextColor3 = self.Disabled and theme.MutedText or theme.Text
        self.ValueLabel.TextColor3 = self.Disabled and theme.MutedText or theme.SubText
        self.ModeLabel.TextColor3 = self.Disabled and theme.MutedText or theme.SubText
        self.Button.BackgroundColor3 = self.Disabled and theme.Surface or theme.Input
        self.ModeButton.BackgroundColor3 = self.Disabled and theme.Surface or theme.Input
        applyActiveText(self.Label, self:GetState() and not self.Disabled)
    end

    function option:OnChanged(callback)
        return self.Changed:Connect(callback)
    end

    function option:OnClick(callback)
        return self.Clicked:Connect(callback)
    end

    function option:GetState()
        if self.Mode == "Always" then
            return true
        end
        return self.State == true
    end

    function option:_display()
        self.ValueLabel.Text = inputToName(self.Value)
        self.ModeLabel.Text = self.Mode
        self:UpdateTheme()
    end

    function option:TriggerChanged()
        self.Changed:Fire(self.Value, self.Modifiers)
        self.Library:_safeCallback(self.ChangedCallback, self.Value, self.Modifiers)
    end

    function option:_emitClick()
        self.Clicked:Fire()
        if self.Mode == "Toggle" then
            self.Library:_safeCallback(self.Callback, self:GetState())
        elseif self.Mode == "Hold" then
            self.Library:_safeCallback(self.Callback, self:GetState())
        elseif self.Mode == "Always" then
            self.Library:_safeCallback(self.Callback, true)
        else
            self.Library:_safeCallback(self.Callback, true)
        end
    end

    function option:DoClick()
        self:_emitClick()
    end

    function option:SetValue(value, silent)
        local newValue = value
        local newMode = nil
        local newModifiers = nil
        if type(value) == "table" then
            newValue = value[1]
            newMode = value[2]
            newModifiers = value[3]
        end
        self.Value = inputFromName(newValue)
        if newMode and valueExists(self.Modes, newMode) then
            self.Mode = newMode
        end
        if type(newModifiers) == "table" then
            self.Modifiers = deepCopy(newModifiers)
        end
        self.State = self.Mode == "Always"
        self:_display()
        if not silent then
            self:TriggerChanged()
        end
    end

    function option:SetMode(mode, silent)
        if valueExists(self.Modes, mode) then
            self.Mode = mode
            self.State = mode == "Always"
            self:_display()
            if not silent then
                self:TriggerChanged()
            end
        end
    end

    function option:CycleMode()
        if #self.Modes == 0 then
            return
        end
        local currentIndex = table.find(self.Modes, self.Mode) or 1
        local nextIndex = currentIndex + 1
        if nextIndex > #self.Modes then
            nextIndex = 1
        end
        self:SetMode(self.Modes[nextIndex])
    end

    button.MouseButton1Click:Connect(function()
        if option.Disabled then
            return
        end
        option.Capturing = true
        option.ValueLabel.Text = "..."
    end)
    button.InputBegan:Connect(function(input)
        if option.Disabled then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            option:CycleMode()
        end
    end)
    modeButton.MouseButton1Click:Connect(function()
        if option.Disabled or #option.Modes == 0 then
            return
        end
        option:CycleMode()
    end)
    modeButton.InputBegan:Connect(function(input)
        if option.Disabled then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            option:CycleMode()
        end
    end)
    container.Library:_track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if option.Capturing then
            option.Capturing = false
            if input.KeyCode == Enum.KeyCode.Escape then
                option:SetValue(nil)
            else
                option:SetValue(input.UserInputType.Name:match("^MouseButton") and input.UserInputType or input.KeyCode)
            end
            return
        end
        if option.Disabled or not inputMatches(input, option.Value) then
            return
        end
        if option.Mode == "Hold" then
            option.State = true
            option:_display()
            option:_emitClick()
        elseif option.Mode == "Toggle" then
            option.State = not option.State
            if option.SyncToggleState and option.SyncTarget and option.SyncTarget.SetValue then
                option.SyncTarget:SetValue(option.State)
            end
            option:_display()
            option:_emitClick()
        elseif option.Mode == "Always" then
            option.State = true
            option:_display()
            option:_emitClick()
        else
            if option.WaitForCallback then
                local busy = option._busy
                if busy then
                    return
                end
                option._busy = true
                task.spawn(function()
                    option:_emitClick()
                    option._busy = false
                end)
            else
                option:_emitClick()
            end
        end
    end))
    container.Library:_track(UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed or option.Disabled then
            return
        end
        if option.Mode == "Hold" and inputMatches(input, option.Value) then
            option.State = false
            option:_display()
            option:_emitClick()
        end
    end))

    if option.SyncToggleState and option.SyncTarget and option.SyncTarget.OnChanged then
        option.SyncTarget:OnChanged(function(state)
            option.State = state and true or false
            option:_display()
        end)
    end

    option.Frame.Visible = option.Visible
    option:SetValue({ option.Value, option.Mode, option.Modifiers }, true)
    return option
end

Groupbox.AddKeybind = addKeybind
DependencyBox.AddKeybind = addKeybind
TabboxPage.AddKeybind = addKeybind
Groupbox.AddKeyPicker = addKeybind
DependencyBox.AddKeyPicker = addKeybind
TabboxPage.AddKeyPicker = addKeybind

local function addColorPicker(container, flagOrConfig, maybeConfig)
    local config = parseFlagConfig(flagOrConfig, maybeConfig)
    local text = config.Text or config.Title or config.Flag or "Color Picker"
    local frame = create("Frame", {
        Parent = container.ContentFrame,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
    })
    local row = create("Frame", { Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36) })
    local label = create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -76, 1, 0),
        Text = text,
        TextColor3 = container.Library.Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(label, 18, "medium")
    local button = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(74, 28),
        AutoButtonColor = false,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Text = "",
    })
    makeCorner(button, 7)
    local swatch = create("Frame", {
        Parent = button,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(6, 12),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = tableToColor(config.Default or { 255, 255, 255 }),
        BorderSizePixel = 0,
    })
    makeCorner(swatch, 5)
    local hexLabel = create("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -28, 1, 0),
        Text = "",
        TextColor3 = container.Library.Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyTextStyle(hexLabel, 17, "regular")
    local editor = create("Frame", {
        Parent = frame,
        BackgroundColor3 = container.Library.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
    })
    makeCorner(editor, 8)

    local option = attachElementCommon(setmetatable({
        Library = container.Library,
        ParentContainer = container,
        Type = "colorpicker",
        Text = text,
        Flag = config.Flag,
        Save = config.Save ~= false,
        Callback = config.Callback or config.Changed,
        Frame = frame,
        Label = label,
        Swatch = swatch,
        HexLabel = hexLabel,
        Editor = editor,
        Open = false,
        Transparency = tonumber(config.Transparency) or 0,
        AllowTransparency = config.Transparency ~= nil,
        Visible = config.Visible ~= false,
        Disabled = config.Disabled == true,
        Value = tableToColor(config.Default or { 255, 255, 255 }),
        _reflow = container._reflow,
    }, Element))
    container.Library:_registerOption(option)

    local channels = { "R", "G", "B" }
    local rows = {}
    local function setChannel(name, number)
        local r = math.floor(option.Value.R * 255 + 0.5)
        local g = math.floor(option.Value.G * 255 + 0.5)
        local b = math.floor(option.Value.B * 255 + 0.5)
        if name == "R" then r = number elseif name == "G" then g = number else b = number end
        option:SetValue(Color3.fromRGB(r, g, b))
    end

    for _, name in ipairs(channels) do
        local slider = create("Frame", { Parent = editor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34) })
        local channelLabel = create("TextLabel", {
            Parent = slider,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(18, 14),
            Text = name,
            TextColor3 = container.Library.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        applyTextStyle(channelLabel, 12, "medium")
        local bar = create("TextButton", {
            Parent = slider,
            BackgroundColor3 = container.Library.Theme.Input,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(24, 4),
            Size = UDim2.new(1, -72, 0, 6),
            AutoButtonColor = false,
            Text = "",
        })
        makeCorner(bar, 6)
        local fill = create("Frame", { Parent = bar, BackgroundColor3 = container.Library.Theme.Accent, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) })
        makeCorner(fill, 6)
        local thumb = create("Frame", {
            Parent = bar,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 10),
            BackgroundColor3 = container.Library.Theme.AccentStrong,
            BorderSizePixel = 0,
        })
        makeCorner(thumb, 5)
        local value = create("TextLabel", {
            Parent = slider,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(42, 14),
            Text = "",
            TextColor3 = container.Library.Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        applyTextStyle(value, 12, "regular")
        rows[name] = { Bar = bar, Fill = fill, Thumb = thumb, Value = value }
        local dragging = false
        local function updateFromInput(input)
            local relative = (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
            setChannel(name, math.floor(clamp(relative, 0, 1) * 255 + 0.5))
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            dragging = true
            updateFromInput(input)
        end)
        container.Library:_track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end))
        container.Library:_track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    function option:UpdateTheme()
        self.Label.TextColor3 = self.Disabled and self.Library.Theme.MutedText or self.Library.Theme.Text
        self.HexLabel.TextColor3 = self.Disabled and self.Library.Theme.MutedText or self.Library.Theme.SubText
        self.Editor.BackgroundColor3 = self.Library.Theme.Surface
        applyActiveText(self.Label, self.Open and not self.Disabled)
    end
    function option:SetValue(value, transparency, silent)
        self.Value = typeof(value) == "Color3" and value or tableToColor(value)
        if transparency ~= nil then
            self.Transparency = clamp(tonumber(transparency) or 0, 0, 1)
        end
        self.Swatch.BackgroundColor3 = self.Value
        self.Swatch.BackgroundTransparency = self.Transparency
        self.HexLabel.Text = colorToHex(self.Value)
        local map = { R = math.floor(self.Value.R * 255 + 0.5), G = math.floor(self.Value.G * 255 + 0.5), B = math.floor(self.Value.B * 255 + 0.5) }
        for name, rowData in pairs(rows) do
            local percent = map[name] / 255
            rowData.Fill.Size = UDim2.fromScale(percent, 1)
            rowData.Thumb.Position = UDim2.new(percent, 0, 0.5, 0)
            rowData.Value.Text = tostring(map[name])
        end
        if not silent then
            self:TriggerChanged()
        end
    end
    function option:SetValueRGB(color, transparency, silent)
        self:SetValue(color, transparency, silent == true)
    end
    button.MouseButton1Click:Connect(function()
        if option.Disabled then
            return
        end
        option.Open = not option.Open
        option.Editor.Visible = option.Open
        option.Editor.Size = UDim2.new(1, 0, 0, option.Open and 112 or 0)
        if option._reflow then option:_reflow() end
    end)
    option.Frame.Visible = option.Visible
    option:SetValue(option.Value, option.Transparency, true)
    return option
end

Groupbox.AddColorPicker = addColorPicker
DependencyBox.AddColorPicker = addColorPicker
TabboxPage.AddColorPicker = addColorPicker

local function addMedia(container, className, text, options)
    options = options or {}
    local frame = create("Frame", {
        Parent = container.ContentFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, (options.Height or 120) + ((text and text ~= "") and 22 or 0)),
    })
    local offset = 0
    if text and text ~= "" then
        local label = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Text = text,
            TextColor3 = container.Library.Theme.Text,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        applyTextStyle(label, 13, "medium")
        offset = 22
    end
    local media = create(className, {
        Parent = frame,
        BackgroundColor3 = container.Library.Theme.Input,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, offset),
        Size = UDim2.new(1, 0, 0, options.Height or 120),
    })
    makeCorner(media, 10)
    return { Frame = frame, Instance = media }
end

function Groupbox:AddViewport(text, options)
    local object = addMedia(self, "ViewportFrame", text, options)
    return { Frame = object.Frame, Viewport = object.Instance }
end
function DependencyBox:AddViewport(text, options) return Groupbox.AddViewport(self, text, options) end
function TabboxPage:AddViewport(text, options) return Groupbox.AddViewport(self, text, options) end

function Groupbox:AddImage(text, options)
    local object = addMedia(self, "ImageLabel", text, options)
    object.Instance.Image = options and options.Image or ""
    object.Instance.ScaleType = options and options.ScaleType or Enum.ScaleType.Fit
    return { Frame = object.Frame, Image = object.Instance }
end
function DependencyBox:AddImage(text, options) return Groupbox.AddImage(self, text, options) end
function TabboxPage:AddImage(text, options) return Groupbox.AddImage(self, text, options) end

function Groupbox:AddVideo(text, options)
    local object = addMedia(self, "VideoFrame", text, options)
    object.Instance.Video = options and options.Video or ""
    object.Instance.Looped = not options or options.Looped ~= false
    object.Instance.Playing = options and options.Playing == true or false
    object.Instance.Volume = options and options.Volume or 0
    return { Frame = object.Frame, Video = object.Instance }
end
function DependencyBox:AddVideo(text, options) return Groupbox.AddVideo(self, text, options) end
function TabboxPage:AddVideo(text, options) return Groupbox.AddVideo(self, text, options) end

function Groupbox:AddUIPassthrough(options)
    options = options or {}
    local frame = create("Frame", {
        Parent = self.ContentFrame,
        BackgroundTransparency = options.Transparent == false and 0 or 1,
        BackgroundColor3 = self.Library.Theme.Input,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, options.Height or 100),
    })
    if options.Transparent ~= true then
        makeCorner(frame, 10)
    end
    return { Frame = frame, Container = frame }
end
function DependencyBox:AddUIPassthrough(options) return Groupbox.AddUIPassthrough(self, options) end
function TabboxPage:AddUIPassthrough(options) return Groupbox.AddUIPassthrough(self, options) end

function Tabbox:_setup()
    self.Header = create("Frame", {
        Parent = self.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 30),
    })
    self.Buttons = create("Frame", { Parent = self.Header, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
    create("UIListLayout", { Parent = self.Buttons, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) })
    local line = create("Frame", {
        Parent = self.Frame,
        BackgroundColor3 = self.Library.Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 62),
        Size = UDim2.new(1, 0, 0, 1),
    })
    bindTheme(self.Library, line, "BackgroundColor3", "Border")
    self.ContentFrame.Position = UDim2.fromOffset(0, 72)
    self.Tabs = {}
    self.ActiveTab = nil
end

function Tabbox:AddTab(title)
    if not self.Buttons then
        self:_setup()
    end
    local button = create("TextButton", {
        Parent = self.Buttons,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 24),
        Text = title,
        TextColor3 = self.Library.Theme.SubText,
    })
    applyTextStyle(button, 15, "medium")
    local page = setmetatable({
        Library = self.Library,
        Window = self.Window,
        Tab = self.Tab,
        ParentTabbox = self,
        Title = title,
        Button = button,
        Frame = create("Frame", {
            Parent = self.ContentFrame,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
        }),
        _reflow = self._reflow,
    }, TabboxPage)
    page.ContentFrame = page.Frame
    page.Layout = create("UIListLayout", { Parent = page.Frame, Padding = UDim.new(0, 8) })
    self.Tabs[#self.Tabs + 1] = page
    button.MouseButton1Click:Connect(function()
        self.ActiveTab = page
        for _, candidate in ipairs(self.Tabs) do
            local active = candidate == page
            candidate.Frame.Visible = active
            candidate.Button.TextColor3 = active and self.Library.Theme.Text or self.Library.Theme.SubText
        end
        if self._reflow then self:_reflow() end
    end)
    if not self.ActiveTab then
        button:Activate()
        self.ActiveTab = page
        page.Frame.Visible = true
        page.Button.TextColor3 = self.Library.Theme.Text
    end
    return page
end

function KeyTab:AddKeyBox(expectedOrCallback, maybeCallback)
    if not self._keyBoxGroup then
        self._keyBoxGroup = self:AddLeftGroupbox("Key Access")
    end
    local callback = maybeCallback
    local expected = nil
    if type(expectedOrCallback) == "function" then
        callback = expectedOrCallback
    else
        expected = tostring(expectedOrCallback or "")
    end
    local inputFlag = self.Library:_nextFlag("KeyBoxInput")
    local buttonText = expected and "Unlock" or "Submit"
    self._keyBoxGroup:AddInput(inputFlag, {
        Text = "Key",
        Placeholder = "Enter key",
        Finished = false,
    })
    self._keyBoxGroup:AddButton({
        Text = buttonText,
        Func = function()
            local value = self.Library.Options[inputFlag] and self.Library.Options[inputFlag].Value or ""
            if type(callback) == "function" then
                if expected then
                    callback(value == expected, value)
                else
                    callback(value)
                end
            end
        end,
    })
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

local module = Library.new()
module.WindowClass = Window
module.TabClass = Tab
module.KeyTabClass = KeyTab
module.GroupboxClass = Groupbox
module.DependencyBoxClass = DependencyBox
module.TabboxClass = Tabbox
module.TabboxPageClass = TabboxPage
module.ElementClass = Element
module.SaveManagerClass = SaveManager
module.ThemeManagerClass = ThemeManager

return module
