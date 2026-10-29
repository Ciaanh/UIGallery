local _, ns = ...

ns.AddComponent({
    id = "procglow",
    family = "visuals",
    title = "Proc glow (spell alert)",
    summary = "The animated golden border an action button gets when a spell procs. "
        .. "ActionButtonSpellAlertTemplate holds it: a birth flipbook (ProcStartAnim) that hands over "
        .. "to a loop (ProcLoop). Put one on any square button, 1.4 times its size.",
    clients = "Retail, Forever",
    keywords = "proc glow spell alert overlay highlight action button border animation flipbook ActionButtonSpellAlertTemplate",
    whenToUse = {
        "Calling attention to a button the player should press now (a proc, a ready ability, a quest item).",
        "Use the template yourself rather than ActionButtonSpellAlertManager: the manager's table belongs to the action bars, and filling it from addon code taints it.",
    },
    api = {
        { "CreateFrame(\"Frame\", nil, button, \"ActionButtonSpellAlertTemplate\")", "Hidden at creation; size it to 1.4 x the button, centred." },
        { "alert.ProcStartAnim:Play()", "Birth burst, then the template plays ProcLoop by itself (OnFinished)." },
        { "alert.ProcLoop:Play() / Stop()", "The loop alone (skip the birth)." },
        { "alert.animationPlaying = true", "The template's OnShow restarts ProcLoop only when this is set: after a hide and show of a parent." },
        { "alert.ProcStartFlipbook / ProcLoopFlipbook / ProcAltGlow", "The textures; SetAtlas to restyle (the assisted-combat button uses OneButton_ProcLoop_Flipbook)." },
        { "ActionButtonSpellAlertManager:ShowAlert(actionButton) / HideAlert", "What Blizzard's own action buttons call." },
    },
    refs = {
        "Blizzard_ActionBar/Shared/ActionButtonSpellAlerts.xml",
        "Blizzard_ActionBar/Shared/ActionButtonSpellAlerts.lua",
    },
})

-- @snippet procglow-button
local function CreateProcButton(parent, icon, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()
    button.Icon:SetTexture(icon)

    local alert = CreateFrame("Frame", nil, button, "ActionButtonSpellAlertTemplate")
    alert:SetSize(size * 1.4, size * 1.4)
    alert:SetPoint("CENTER")
    button.Alert = alert
    return button
end

local function SetProcGlow(button, active, skipBirth)
    local alert = button.Alert
    alert.ProcStartAnim:Stop()
    alert.animationPlaying = false
    if not active then
        alert:Hide() -- the template's OnHide stops the loop
        return
    end
    alert:Show()
    -- Set after Show: OnShow would start the loop on top of the birth otherwise.
    alert.animationPlaying = true
    if skipBirth then
        alert.ProcLoop:Play()
    else
        alert.ProcStartAnim:Play()
    end
end
-- @end

ns.AddExample("procglow", {
    id = "procglow-button",
    title = "Glow on your own button",
    description = "Tick \"Glow\" to replay the birth burst then the loop. \"Skip birth\" goes straight to "
        .. "the loop, as the action bars do for a button that appears with its proc already active.",
    height = 120,
    code = { "procglow-button" },
    create = function(stage)
        local button = CreateProcButton(stage, "Interface\\Icons\\Spell_Fire_Fireball02", 48)
        button:SetPoint("CENTER")
        return button
    end,
    controls = {
        { type = "check", key = "active", label = "Glow", default = true, code = function(value, values)
            return ("SetProcGlow(button, %s, %s)"):format(tostring(value), tostring(values.skipBirth))
        end },
        { type = "check", key = "skipBirth", label = "Skip birth", default = false, code = false },
        { type = "button", key = "replay", label = "Replay" },
    },
    apply = function(button, key, _, values)
        if key == "skipBirth" then
            return
        end
        SetProcGlow(button, values.active, values.skipBirth)
    end,
})
