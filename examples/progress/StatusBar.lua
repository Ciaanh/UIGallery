local _, ns = ...

ns.AddComponent({
    id = "statusbar",
    family = "progress",
    title = "Status bar",
    summary = "A bar filled between a min and a max value: health, experience, cast bars. The StatusBar "
        .. "widget resizes its bar texture itself; 12.x adds smooth interpolation and bars driven by a "
        .. "duration object.",
    clients = "Retail, Forever, Classic (interpolation, timer durations: Retail and Forever)",
    keywords = "progress bar health xp experience cast timer interpolation",
    whenToUse = {
        "Any linear amount: resources, experience, reputation, progress of a task.",
        "Timers: SetTimerDuration drives the bar from a duration object with no OnUpdate.",
        "For a circular look, the same widget renders radially: see Radial progress.",
    },
    api = {
        { "SetMinMaxValues(min, max [, interpolation])", "Range of the bar." },
        { "SetValue(value [, interpolation])", "Current value. Enum.StatusBarInterpolation.ExponentialEaseOut eases toward it; Immediate snaps.", "Immediate" },
        { "SetStatusBarTexture(asset)", "Bar texture: file path, file id or atlas. GetStatusBarTexture() returns the Texture to tint or crop." },
        { "SetStatusBarColor(r, g, b [, a])", "Tints the bar texture." },
        { "SetOrientation(\"HORIZONTAL\" | \"VERTICAL\")", "Fill axis.", "HORIZONTAL" },
        { "SetReverseFill(bool)", "Fill right-to-left / top-to-bottom.", "false" },
        { "SetFillStyle(Enum.StatusBarFillStyle)", "Standard, StandardNoRangeFill, Center (grows from the middle), Reverse.", "Standard" },
        { "SetRotatesTexture(bool)", "Rotate the texture 90 degrees for vertical bars.", "false" },
        { "SetTimerDuration(duration [, interpolation, direction])", "Animate the bar from a LuaDurationObject (C_DurationUtil.CreateDuration). direction: Enum.StatusBarTimerDirection ElapsedTime / RemainingTime." },
        { "GetInterpolatedValue(), IsInterpolating(), SetToTargetValue()", "Read or finish an interpolation in progress." },
        { "SetRenderMode(Enum.StatusBarRenderMode)", "Linear or Radial (Retail 12.1+, Forever).", "Linear" },
        { "XML: <StatusBar minValue maxValue defaultValue orientation reverseFill fillStyle renderMode>", "Children <BarTexture> and <BarColor>." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/SimpleStatusBarAPIDocumentation.lua",
        "Blizzard_APIDocumentationGenerated/SimpleStatusBarConstantsDocumentation.lua",
        "Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua (SetTimerDuration)",
    },
})

-- @snippet statusbar-basic
local function CreateValueBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(240, 20)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.1, 0.75, 0.2)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(65)

    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.6)

    bar.Text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.Text:SetPoint("CENTER")
    return bar
end

local function SetBarValue(bar, value, smooth)
    local interpolation = smooth and Enum.StatusBarInterpolation.ExponentialEaseOut
        or Enum.StatusBarInterpolation.Immediate
    bar:SetValue(value, interpolation)
    bar.Text:SetFormattedText("%d / 100", value)
end
-- @end

local FILL_STYLES = { { "Standard" }, { "Center" }, { "Reverse" }, { "StandardNoRangeFill" } }

ns.AddExample("statusbar", {
    id = "statusbar-basic",
    title = "Bar with value text",
    description = "A StatusBar with a background and a centred label. Turn on \"Smooth\" and move the "
        .. "value: the bar eases toward it (ExponentialEaseOut) while the text updates at once.",
    height = 90,
    requires = { "barInterpolation" },
    code = { "statusbar-basic" },
    create = function(stage)
        local bar = CreateValueBar(stage)
        bar:SetPoint("CENTER")
        return bar
    end,
    controls = {
        { type = "slider", key = "value", label = "Value", min = 0, max = 100, step = 1, default = 65 },
        { type = "check", key = "smooth", label = "Smooth (interpolation)", default = true },
        { type = "choice", key = "fillStyle", label = "Fill style", choices = FILL_STYLES, default = "Standard" },
        { type = "check", key = "reverse", label = "Reverse fill", default = false },
    },
    apply = function(bar, key, value, values)
        if key == "value" or key == "smooth" then
            SetBarValue(bar, values.value, values.smooth)
        elseif key == "fillStyle" then
            bar:SetFillStyle(Enum.StatusBarFillStyle[value])
        elseif key == "reverse" then
            bar:SetReverseFill(value)
        end
    end,
})

-- @snippet statusbar-xml-usage
local function CreateVerticalBar(parent)
    -- UIGalleryVerticalBarTemplate is declared in the XML tab.
    local bar = CreateFrame("StatusBar", nil, parent, "UIGalleryVerticalBarTemplate")
    bar:SetValue(0.4)
    return bar
end
-- @end

ns.AddExample("statusbar", {
    id = "statusbar-xml",
    title = "Vertical bar from an XML template",
    description = "Orientation, range, texture and colour all set in XML; Lua only creates it and sets "
        .. "the value. SetRotatesTexture keeps the texture's grain along the fill axis.",
    height = 150,
    code = { "statusbar-xml", "statusbar-xml-usage" },
    create = function(stage)
        local bar = CreateVerticalBar(stage)
        bar:SetPoint("CENTER")
        return bar
    end,
    controls = {
        { type = "slider", key = "value", label = "Value", min = 0, max = 1, step = 0.01, default = 0.4 },
        { type = "check", key = "rotates", label = "Rotate texture", default = true },
    },
    apply = function(bar, key, value)
        if key == "value" then
            bar:SetValue(value)
        elseif key == "rotates" then
            bar:SetRotatesTexture(value)
        end
    end,
})

-- @snippet statusbar-timer
local function CreateTimerBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(240, 14)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(1, 0.7, 0)

    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.6)

    -- A duration object describes a time span; the bar follows it every frame by itself.
    bar.duration = C_DurationUtil.CreateDuration()
    return bar
end

local function StartTimer(bar, seconds, countDown)
    bar.duration:SetTimeFromStart(GetTime(), seconds)
    local direction = countDown and Enum.StatusBarTimerDirection.RemainingTime
        or Enum.StatusBarTimerDirection.ElapsedTime
    bar:SetTimerDuration(bar.duration, Enum.StatusBarInterpolation.Immediate, direction)
end
-- @end

ns.AddExample("statusbar", {
    id = "statusbar-timer",
    title = "Timer bar (duration object)",
    description = "SetTimerDuration hands the bar a LuaDurationObject: no OnUpdate, no SetValue per "
        .. "frame. RemainingTime drains the bar, ElapsedTime fills it. This is how Blizzard's aura "
        .. "buttons and encounter timeline draw their timers.",
    height = 70,
    requires = { "durationObjects" },
    code = { "statusbar-timer" },
    create = function(stage)
        local bar = CreateTimerBar(stage)
        bar:SetPoint("CENTER")
        return bar
    end,
    controls = {
        { type = "slider", key = "seconds", label = "Duration (s)", min = 2, max = 30, step = 1, default = 8 },
        { type = "check", key = "countDown", label = "Count down (RemainingTime)", default = true },
        { type = "button", key = "start", label = "Start" },
    },
    apply = function(bar, key, _, values)
        StartTimer(bar, values.seconds, values.countDown)
    end,
})
