local _, ns = ...

ns.AddComponent({
    id = "cooldown",
    family = "progress",
    title = "Cooldown swipe",
    summary = "The Cooldown frame draws a clock-like swipe over its area, with an edge line, countdown "
        .. "numbers and an end flash (bling). Action buttons stack three of them: the cooldown, loss "
        .. "of control and charge recharge. For a progress ring, use the radial progress instead.",
    clients = "Retail, Forever, Classic",
    keywords = "cooldown swipe ring clock spinner timer percent renown",
    whenToUse = {
        "Real cooldowns on buttons and icons (countdown numbers, edge, end bling).",
        "Several overlapping timers on one icon: one Cooldown frame each (action button style).",
        "Not as a progress ring on Retail or Forever: the native radial fill does it (Radial progress).",
        "Not for secret values: SetCooldown is AllowedWhenUntainted only, addon code cannot pass one.",
    },
    api = {
        { "SetCooldown(start, duration [, modRate])", "Start a swipe: start is GetTime()-based." },
        { "SetCooldownFromDurationObject(duration [, clearIfZero])", "Same from a LuaDurationObject (Retail, Forever)." },
        { "CooldownFrame_SetDisplayAsPercentage(cooldown, percent [, seconds])", "Blizzard helper: Pause() then SetCooldown(GetTime() - seconds * percent, seconds). Freezes the swipe at percent (Blizzard's older rings)." },
        { "Pause() / Resume() / Clear()", "Freeze, continue, or remove the swipe." },
        { "SetReverse(bool)", "true: the swipe reveals the texture as time passes; false: it covers it (the usual darkening).", "false" },
        { "SetSwipeTexture(file [, r, g, b, a]) / SetSwipeColor", "What the swipe draws. A ring texture gives a ring." },
        { "SetTexCoordRange(low, high)", "Swipe texture coordinates, for an atlas region ({ x =, y = } tables)." },
        { "SetRotation(radians)", "Moves the swipe's origin. XML rotation=\"180\" (degrees) starts at the top, as Blizzard's rings do." },
        { "SetDrawEdge / SetDrawSwipe / SetDrawBling(bool)", "The bright edge line, the swipe itself, the end flash. XML: drawEdge, drawSwipe, drawBling." },
        { "XML useParentLevel=\"true\"", "Draws at the parent's frame level, so stacked cooldowns and the icon stay in one level." },
        { "SetEdgeTexture(file) / SetEdgeScale / SetUseCircularEdge(bool)", "The edge's look; circular edge follows a circle instead of the square." },
        { "SetHideCountdownNumbers(bool)", "Hide the built-in countdown text.", "false" },
        { "Template CooldownFrameTemplate", "setAllPoints, default swipe (black, 64%), edge and bling textures." },
    },
    refs = {
        "Blizzard_FrameXMLUtil/Cooldown.lua (CooldownFrame_SetDisplayAsPercentage)",
        "Blizzard_FrameXMLUtil/Mainline/Cooldown.xml (CooldownFrameTemplate)",
        "Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml (cooldown, lossOfControlCooldown, chargeCooldown)",
        "Blizzard_ActionBar/Shared/ActionButton.lua (ActionButton_ApplyCooldown)",
        "Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua",
    },
})

-- @snippet cooldown-icon
local function CreateCooldownIcon(parent)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(64, 64)

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\Icons\\Spell_Holy_SurgeOfLight")

    icon.Cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.Cooldown:SetAllPoints()
    return icon
end

local function StartCooldown(icon, seconds)
    icon.Cooldown:SetCooldown(GetTime(), seconds)
end
-- @end

ns.AddExample("cooldown", {
    id = "cooldown-icon",
    title = "Icon cooldown (CooldownFrameTemplate)",
    description = "The action-button look: a dark swipe, the edge line, countdown numbers and the "
        .. "bling when it ends. Every part can be turned off.",
    height = 110,
    code = { "cooldown-icon" },
    create = function(stage)
        local icon = CreateCooldownIcon(stage)
        icon:SetPoint("CENTER")
        return icon
    end,
    controls = {
        { type = "slider", key = "seconds", label = "Duration (s)", min = 2, max = 30, step = 1, default = 10 },
        { type = "check", key = "edge", label = "Draw edge", default = true },
        { type = "check", key = "bling", label = "Draw bling", default = true },
        { type = "check", key = "numbers", label = "Countdown numbers", default = true },
        { type = "check", key = "reverse", label = "Reverse", default = false },
        { type = "button", key = "start", label = "Start" },
    },
    apply = function(icon, key, value, values)
        local cooldown = icon.Cooldown
        if key == "edge" then
            cooldown:SetDrawEdge(value)
        elseif key == "bling" then
            cooldown:SetDrawBling(value)
        elseif key == "numbers" then
            cooldown:SetHideCountdownNumbers(not value)
        elseif key == "reverse" then
            cooldown:SetReverse(value)
        elseif key == "start" then
            StartCooldown(icon, values.seconds)
        end
    end,
})

-- @snippet cooldown-action-usage
local function CreateActionCooldowns(parent)
    -- UIGalleryActionCooldownsTemplate is declared in the XML tab.
    return CreateFrame("Frame", nil, parent, "UIGalleryActionCooldownsTemplate")
end

-- kind: "Cooldown", "LossOfControl" or "Charge" (the template's parentKeys).
local function StartTimer(icon, kind, seconds)
    icon[kind]:SetCooldown(GetTime(), seconds)
end
-- @end

ns.AddExample("cooldown", {
    id = "cooldown-action",
    title = "Action button cooldowns (XML)",
    description = "Blizzard's action buttons stack three Cooldown frames over the icon. Start them "
        .. "together to see how they overlap: the charge edge runs over the spell's swipe, loss of "
        .. "control tints it red.",
    height = 110,
    code = { "cooldown-action", { "cooldown-action-usage", "Usage" } },
    create = function(stage)
        local icon = CreateActionCooldowns(stage)
        icon:SetPoint("CENTER")
        return icon
    end,
    controls = {
        { type = "slider", key = "seconds", label = "Duration (s)", min = 2, max = 30, step = 1, default = 8 },
        { type = "button", key = "Cooldown", label = "Start cooldown" },
        { type = "button", key = "LossOfControl", label = "Start loss of control" },
        { type = "button", key = "Charge", label = "Start charge" },
    },
    apply = function(icon, key, _, values)
        if key ~= "seconds" then
            StartTimer(icon, key, values.seconds)
        end
    end,
})
