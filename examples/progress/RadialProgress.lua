local _, ns = ...

ns.AddComponent({
    id = "radial",
    family = "progress",
    title = "Radial progress",
    summary = "Rings and arcs filled by angle, native since 12.1: any Texture can be cut radially "
        .. "(SetRadialProgressBar*), and a StatusBar can drive that cut from its value (render mode "
        .. "Radial). The texture gives the shape (ring, disc, arc); the radial fill only masks it by angle.",
    clients = "Retail 12.1+, Forever (not Classic, not in the 12.0.5 API dump)",
    requires = { "nativeRadial" },
    keywords = "circular ring arc round gauge percent cooldown",
    whenToUse = {
        "A circular amount: experience ring, cooldown-like progress, completion percentage.",
        "Use the StatusBar form when the value has a min/max or should ease (interpolation, timers).",
        "Use the Texture form for a fixed shape (a full track behind the fill) or a one-off percent.",
        "Secret values: SetRadialProgressBarPercent and StatusBar:SetValue accept them from addon code.",
    },
    api = {
        { "Texture:SetRadialProgressBarPercent(percent)", "Fill amount, 0 to 1. Accepts secret values (AllowedWhenTainted)." },
        { "Texture:SetRadialProgressBarStartOffset(offset)", "Where the fill starts, as a fraction of a turn. 0 is at the bottom.", "0" },
        { "Texture:SetRadialProgressBarEndOffset(offset)", "Where the fill ends, as a fraction of a turn. An absolute position, like the start: 0.125 to 0.875 is a 270 degree arc open at the bottom.", "1" },
        { "Texture:SetRadialProgressBarReverse(reverse)", "Fill counter-clockwise.", "false" },
        { "Texture:SetRadialProgressBarFeather(feather)", "Softness of the fill's leading edge, 0 to 1.", "0" },
        { "Texture:ClearRadialProgressBar()", "Back to a normal texture." },
        { "Get... for each of the above", "GetRadialProgressBarPercent returns a secret when it was set from one." },
        { "StatusBar:SetRenderMode(Enum.StatusBarRenderMode.Radial)", "The bar sets its texture's radial percent from its value instead of resizing it. Offsets, reverse and feather are set on GetStatusBarTexture()." },
        { "XML: <Texture><RadialProgressBar barFillPercent startOffset endOffset reverse feather/></Texture>", "Same settings declared on a texture." },
        { "XML: <StatusBar renderMode=\"Radial\">", "Radial status bar." },
        { "anim:SetFromPercent(percent) / SetToPercent(percent)", "Animation created with group:CreateAnimation(\"RadialProgress\"): animates the radial percent of its target (see the animation example)." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua",
        "Blizzard_APIDocumentationGenerated/SimpleStatusBarConstantsDocumentation.lua (StatusBarRenderMode)",
        "Blizzard_APIDocumentationGenerated/SimpleAnimRadialProgressAPIDocumentation.lua",
        "Blizzard_SharedXML/UI.xsd (RadialProgressBar, renderMode)",
    },
})

-- @snippet radial-ring
local RING = "Interface\\AddOns\\UIGallery\\media\\ring"

local function CreateRadialRing(parent, size)
    -- The track: the full ring, dimmed.
    local track = parent:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(RING)
    track:SetVertexColor(0.2, 0.2, 0.25)

    -- The fill: a StatusBar whose texture is cut by angle from the bar's value.
    local ring = CreateFrame("StatusBar", nil, parent)
    ring:SetSize(size, size)
    ring:SetStatusBarTexture(RING)
    ring:SetStatusBarColor(1, 0.75, 0.1)
    ring:SetRenderMode(Enum.StatusBarRenderMode.Radial)
    ring:SetMinMaxValues(0, 1)
    ring:GetStatusBarTexture():SetRadialProgressBarStartOffset(0.5) -- start at the top

    track:SetAllPoints(ring)

    ring.Text = ring:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ring.Text:SetPoint("CENTER")
    return ring
end

local function SetRingValue(ring, value, smooth)
    local interpolation = smooth and Enum.StatusBarInterpolation.ExponentialEaseOut
        or Enum.StatusBarInterpolation.Immediate
    ring:SetValue(value, interpolation)
    ring.Text:SetFormattedText("%d%%", value * 100)
end
-- @end

ns.AddExample("radial", {
    id = "radial-ring",
    title = "Ring (StatusBar, radial render mode)",
    description = "A StatusBar in radial render mode over a dimmed track. Value, range and easing are "
        .. "the bar's; start offset, direction and feather are set on its texture. Check which way "
        .. "\"Reverse\" turns: the docs say reverse = counter-clockwise.",
    height = 170,
    code = { "radial-ring" },
    create = function(stage)
        local ring = CreateRadialRing(stage, 140)
        ring:SetPoint("CENTER")
        return ring
    end,
    controls = {
        { type = "slider", key = "value", label = "Value", min = 0, max = 1, step = 0.01, default = 0.42, code = function(value, values) return ("ring:SetValue(%g, Enum.StatusBarInterpolation.%s)"):format(value, values.smooth and "ExponentialEaseOut" or "Immediate") end },
        { type = "check", key = "smooth", label = "Smooth (interpolation)", default = true, code = false },
        { type = "slider", key = "start", label = "Start offset (0 = bottom)", min = 0, max = 1, step = 0.05, default = 0.5, code = "ring:GetStatusBarTexture():SetRadialProgressBarStartOffset(%s)" },
        { type = "check", key = "reverse", label = "Reverse", default = false, code = "ring:GetStatusBarTexture():SetRadialProgressBarReverse(%s)" },
        { type = "slider", key = "feather", label = "Feather", min = 0, max = 0.5, step = 0.01, default = 0, code = "ring:GetStatusBarTexture():SetRadialProgressBarFeather(%s)" },
    },
    apply = function(ring, key, value, values)
        local texture = ring:GetStatusBarTexture()
        if key == "value" or key == "smooth" then
            SetRingValue(ring, values.value, values.smooth)
        elseif key == "start" then
            texture:SetRadialProgressBarStartOffset(value)
        elseif key == "reverse" then
            texture:SetRadialProgressBarReverse(value)
        elseif key == "feather" then
            texture:SetRadialProgressBarFeather(value)
        end
    end,
})

-- @snippet radial-arc-usage
local function CreateArc(parent)
    -- UIGalleryRadialArcTemplate is declared in the XML tab.
    local arc = CreateFrame("Frame", nil, parent, "UIGalleryRadialArcTemplate")
    arc.Fill:SetRadialProgressBarPercent(0.6)
    return arc
end
-- @end

ns.AddExample("radial", {
    id = "radial-arc",
    title = "Arc (Texture, XML)",
    description = "Two textures of the same full ring, each with a <RadialProgressBar>: the track is "
        .. "always full, the fill follows the percent. Both offsets are absolute positions (0 = bottom): "
        .. "start 0.125 / end 0.875 is a 270 degree arc open at the bottom.",
    height = 170,
    code = { "radial-arc", "radial-arc-usage" },
    create = function(stage)
        local arc = CreateArc(stage)
        arc:SetPoint("CENTER")
        return arc
    end,
    controls = {
        { type = "slider", key = "percent", label = "Percent", min = 0, max = 1, step = 0.01, default = 0.6, code = "arc.Fill:SetRadialProgressBarPercent(%s)" },
        { type = "slider", key = "start", label = "Start offset", min = 0, max = 1, step = 0.025, default = 0.125, code = function(value) return ("arc.Track:SetRadialProgressBarStartOffset(%g)\narc.Fill:SetRadialProgressBarStartOffset(%g)"):format(value, value) end },
        { type = "slider", key = "finish", label = "End offset", min = 0, max = 1, step = 0.025, default = 0.875, code = function(value) return ("arc.Track:SetRadialProgressBarEndOffset(%g)\narc.Fill:SetRadialProgressBarEndOffset(%g)"):format(value, value) end },
    },
    apply = function(arc, key, value)
        if key == "percent" then
            arc.Fill:SetRadialProgressBarPercent(value)
        elseif key == "start" then
            arc.Track:SetRadialProgressBarStartOffset(value)
            arc.Fill:SetRadialProgressBarStartOffset(value)
        elseif key == "finish" then
            arc.Track:SetRadialProgressBarEndOffset(value)
            arc.Fill:SetRadialProgressBarEndOffset(value)
        end
    end,
})

-- @snippet radial-animation
local function CreateAnimatedRing(parent)
    local ring = parent:CreateTexture(nil, "ARTWORK")
    ring:SetSize(120, 120)
    ring:SetTexture("Interface\\AddOns\\UIGallery\\media\\ring")
    ring:SetVertexColor(0.3, 0.8, 1)
    ring:SetRadialProgressBarStartOffset(0.5)
    ring:SetRadialProgressBarPercent(0)

    local group = ring:CreateAnimationGroup()
    local fill = group:CreateAnimation("RadialProgress")
    fill:SetFromPercent(0)
    fill:SetToPercent(1)
    fill:SetDuration(1.5)
    fill:SetSmoothing("OUT")
    group:SetToFinalAlpha(true)
    ring.FillAnim = group
    ring.Fill = fill
    return ring
end
-- @end

ns.AddExample("radial", {
    id = "radial-animation",
    title = "RadialProgress animation",
    description = "An animation type that moves a texture's radial percent from one value to another. "
        .. "Created with CreateAnimation(\"RadialProgress\"); no Blizzard UI uses it yet.",
    height = 150,
    code = { "radial-animation" },
    create = function(stage)
        local ring = CreateAnimatedRing(stage)
        ring:SetPoint("CENTER")
        return ring
    end,
    controls = {
        { type = "slider", key = "from", label = "From", min = 0, max = 1, step = 0.05, default = 0, code = "ring.Fill:SetFromPercent(%s)" },
        { type = "slider", key = "to", label = "To", min = 0, max = 1, step = 0.05, default = 1, code = "ring.Fill:SetToPercent(%s)" },
        { type = "slider", key = "duration", label = "Duration (s)", min = 0.2, max = 4, step = 0.1, default = 1.5, code = "ring.Fill:SetDuration(%s)" },
        { type = "button", key = "play", label = "Play" },
    },
    apply = function(ring, key, value, values)
        if key == "from" then
            ring.Fill:SetFromPercent(value)
        elseif key == "to" then
            ring.Fill:SetToPercent(value)
        elseif key == "duration" then
            ring.Fill:SetDuration(value)
        elseif key == "play" then
            ring.FillAnim:Stop()
            ring.FillAnim:Play()
        end
    end,
})
