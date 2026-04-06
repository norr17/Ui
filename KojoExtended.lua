--[[
    KojoExtended - optional additive widgets for KojoLib.

    This file is not merged into KojoLib by default.
    Load KojoLib first, then opt into this addon:

        local Library = loadstring(readfile("KojoLib.lua"))()
        local Extended = loadstring(readfile("KojoExtended.lua"))()
        Library:UseExtended(Extended)

    Only additive section widgets live here.
    Core-owned systems such as config, watermark, FPS counter, tooltip,
    anti-AFK, movement helpers, click teleport, ESP, and silent aim remain in KojoLib.
--]]

local Extended = {
    Name = "KojoExtended",
    Version = "1.0.0",
    SectionMethods = {},
    Utilities = {},
}

local function getTheme(section)
    local library = section and section._library
    if library and library.Theme then
        return library.Theme()
    end
    return {
        SectionBg = Color3.fromRGB(22, 22, 28),
        SectionBorder = Color3.fromRGB(38, 38, 48),
        DropdownItem = Color3.fromRGB(28, 26, 38),
        DropdownItemHover = Color3.fromRGB(42, 40, 56),
        Accent = Color3.fromRGB(148, 100, 220),
        AccentLight = Color3.fromRGB(175, 130, 245),
        TextPrimary = Color3.fromRGB(225, 222, 238),
        TextSecondary = Color3.fromRGB(155, 150, 175),
        TextDisabled = Color3.fromRGB(90, 88, 105),
        ButtonBg = Color3.fromRGB(38, 36, 50),
        ButtonBgHover = Color3.fromRGB(55, 52, 72),
        Separator = Color3.fromRGB(35, 33, 46),
        InputBg = Color3.fromRGB(30, 28, 40),
        InputBorder = Color3.fromRGB(52, 50, 68),
        InputBorderFocus = Color3.fromRGB(148, 100, 220),
        ScrollBar = Color3.fromRGB(75, 70, 95),
    }
end

local function create(class, props)
    local instance = Instance.new(class)
    for key, value in pairs(props or {}) do
        instance[key] = value
    end
    return instance
end

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function stroke(parent, color, thickness)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = color
    uiStroke.Thickness = thickness or 1
    uiStroke.Parent = parent
    return uiStroke
end

local function padding(parent, top, bottom, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top or 8)
    pad.PaddingBottom = UDim.new(0, bottom or 8)
    pad.PaddingLeft = UDim.new(0, left or 10)
    pad.PaddingRight = UDim.new(0, right or 10)
    pad.Parent = parent
    return pad
end

local function list(parent, gap, direction)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, gap or 6)
    layout.FillDirection = direction or Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = parent
    return layout
end

local function register(section, control, controlType, label, opts)
    opts = opts or {}
    control.Type = controlType
    control.Label = label
    control.Flag = section._library:_makeFlag(section._tabName, section._sectionName, label, opts.Flag)
    control.Save = opts.Save ~= false
    control._library = section._library
    if not control.GetValue and control.Value ~= nil then
        control.GetValue = function(self)
            return self.Value
        end
    end
    section._library:_registerControl(control)
    table.insert(section._items, control)
    return control
end

function Extended.SectionMethods:AddTable(label, opts)
    opts = opts or {}
    local headers = opts.Headers or opts.Columns or { "Column" }
    local rows = opts.Rows or {}
    local rowHeight = opts.RowHeight or 24
    local maxHeight = opts.MaxHeight or 128
    local theme = getTheme(self)

    local container = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20 + math.min(maxHeight, (#rows + 1) * rowHeight)),
        Parent = self._elemList,
    })
    padding(container, 0, 0, 0, 0)

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = theme.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local frame = create("ScrollingFrame", {
        BackgroundColor3 = theme.SectionBg,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, math.min(maxHeight, (#rows + 1) * rowHeight)),
        AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.ScrollBar,
        CanvasSize = UDim2.new(),
        Parent = container,
    })
    round(frame, 6)
    stroke(frame, theme.SectionBorder, 1)
    local layout = list(frame, 2)

    local function buildRow(values, isHeader, index)
        local row = create("Frame", {
            BackgroundColor3 = isHeader and theme.InputBg or (index % 2 == 0 and theme.SectionBg or theme.DropdownItem),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, rowHeight),
            Parent = frame,
        })
        local rowLayout = list(row, 0, Enum.FillDirection.Horizontal)
        local cellWidth = 1 / math.max(#headers, 1)
        for columnIndex, value in ipairs(values) do
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(cellWidth, 0, 1, 0),
                Text = "  " .. tostring(value),
                Font = isHeader and Enum.Font.GothamSemibold or Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = isHeader and theme.Accent or theme.TextSecondary,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = columnIndex,
                Parent = row,
            })
        end
        return row
    end

    buildRow(headers, true, 0)
    for index, rowValues in ipairs(rows) do
        buildRow(rowValues, false, index)
    end

    local control = {
        _frame = container,
        _scroll = frame,
        _layout = layout,
        Value = rows,
        SetRows = function(selfControl, newRows)
            rows = newRows or {}
            for _, child in ipairs(frame:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            buildRow(headers, true, 0)
            for index, rowValues in ipairs(rows) do
                buildRow(rowValues, false, index)
            end
            container.Size = UDim2.new(1, 0, 0, 20 + math.min(maxHeight, (#rows + 1) * rowHeight))
            selfControl.Value = rows
        end,
        GetValue = function()
            return rows
        end,
    }

    return register(self, control, "table", label, { Save = false })
end

function Extended.SectionMethods:AddSearchBox(label, opts)
    opts = opts or {}
    local placeholder = opts.Placeholder or "Search..."
    local callback = opts.Callback or function() end
    local theme = getTheme(self)

    local container = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self._elemList,
    })

    local frame = create("Frame", {
        BackgroundColor3 = theme.InputBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = container,
    })
    round(frame, 6)
    local focusStroke = stroke(frame, theme.InputBorder, 1)
    padding(frame, 0, 0, 10, 10)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 18, 1, 0),
        Text = "S",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = theme.TextDisabled,
        Parent = frame,
    })

    local box = create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 0),
        Size = UDim2.new(1, -18, 1, 0),
        PlaceholderText = placeholder,
        PlaceholderColor3 = theme.TextDisabled,
        Text = "",
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = theme.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = frame,
    })

    box.Focused:Connect(function()
        focusStroke.Color = theme.InputBorderFocus
    end)
    box.FocusLost:Connect(function()
        focusStroke.Color = theme.InputBorder
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        callback(box.Text)
    end)

    local control = {
        _frame = container,
        _textbox = box,
        Value = "",
        Set = function(selfControl, value)
            box.Text = tostring(value or "")
            selfControl.Value = box.Text
            callback(selfControl.Value)
        end,
        GetValue = function()
            return box.Text
        end,
        Clear = function(selfControl)
            selfControl:Set("")
        end,
    }

    return register(self, control, "searchbox", label, { Flag = opts.Flag, Save = false })
end

function Extended.SectionMethods:AddSubTabs(label, opts)
    opts = opts or {}
    local tabNames = opts.Tabs or opts.Options or { "Main" }
    local callback = opts.Callback or function() end
    local theme = getTheme(self)
    local active = tabNames[1]

    local container = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = self._elemList,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = theme.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local strip = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 20),
        Parent = container,
    })
    local stripLayout = list(strip, 4, Enum.FillDirection.Horizontal)
    local buttons = {}

    local function updateTabs(target)
        active = target
        for _, data in ipairs(buttons) do
            local selected = data.Name == target
            data.Button.BackgroundColor3 = selected and theme.Accent or theme.ButtonBg
            data.Button.TextColor3 = selected and theme.TextPrimary or theme.TextSecondary
        end
        callback(target)
    end

    for index, name in ipairs(tabNames) do
        local button = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = name == active and theme.Accent or theme.ButtonBg,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            Text = "  " .. tostring(name) .. "  ",
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = name == active and theme.TextPrimary or theme.TextSecondary,
            LayoutOrder = index,
            Parent = strip,
        })
        round(button, 5)
        button.MouseButton1Click:Connect(function()
            updateTabs(name)
        end)
        table.insert(buttons, { Name = name, Button = button })
    end

    local control = {
        _frame = container,
        Value = active,
        Set = function(selfControl, value)
            updateTabs(value)
            selfControl.Value = active
        end,
        GetValue = function()
            return active
        end,
    }

    return register(self, control, "subtabs", label, { Flag = opts.Flag, Save = opts.Save ~= false })
end

function Extended.SectionMethods:AddToggleLock(label, opts)
    opts = opts or {}
    local default = opts.Default or false
    local cooldown = opts.Cooldown or 0.5
    local callback = opts.Callback or function() end
    local theme = getTheme(self)
    local locked = false
    local value = default

    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self._elemList,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -64, 1, 0),
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = theme.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local indicator = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = value and theme.Accent or theme.ButtonBg,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 58, 0, 22),
        Text = value and "ON" or "OFF",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = value and theme.TextPrimary or theme.TextSecondary,
        Parent = row,
    })
    round(indicator, 5)

    local function setValue(nextValue, fire)
        if locked then
            return
        end
        locked = true
        value = nextValue and true or false
        indicator.BackgroundColor3 = value and theme.Accent or theme.ButtonBg
        indicator.TextColor3 = value and theme.TextPrimary or theme.TextSecondary
        indicator.Text = value and "ON" or "OFF"
        if fire ~= false then
            callback(value)
        end
        task.delay(cooldown, function()
            locked = false
        end)
    end

    indicator.MouseButton1Click:Connect(function()
        setValue(not value, true)
    end)

    local control = {
        _frame = row,
        Value = value,
        Set = function(selfControl, nextValue)
            setValue(nextValue, true)
            selfControl.Value = value
        end,
        GetValue = function()
            return value
        end,
    }

    return register(self, control, "togglelock", label, opts)
end

return Extended
