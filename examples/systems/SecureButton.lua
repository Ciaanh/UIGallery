local _, ns = ...

ns.AddComponent({
    id = "securebutton",
    family = "systems",
    title = "Secure action button",
    summary = "Protected actions (cast, use an item, target, run a macro) only run from a click on a "
        .. "secure button: SecureActionButtonTemplate reads what to do from its attributes. The button "
        .. "is protected, so creating, showing, hiding, moving it or changing its attributes is "
        .. "refused in combat, for it and for every frame that contains it.",
    clients = "Retail, Forever",
    keywords = "secure protected combat lockdown taint SecureActionButtonTemplate SetAttribute macro cast target click InCombatLockdown",
    whenToUse = {
        "A button that casts, uses, targets or runs a macro: there is no other way for addon code.",
        "Set everything up out of combat; queue changes to PLAYER_REGEN_ENABLED when InCombatLockdown().",
        "Keep it out of windows that must close in combat: hiding a parent hides the protected child, so it is refused too.",
    },
    api = {
        { "CreateFrame(\"Button\", nil, parent, \"SecureActionButtonTemplate\")", "The secure button; combine visuals after it: \"SecureActionButtonTemplate, UIPanelButtonTemplate\"." },
        { "button:SetAttribute(\"type\", kind)", "macro, spell, item, target, focus, assist, click, action, cancelaura..." },
        { "button:SetAttribute(\"macrotext\", text) / (\"spell\", name) / (\"item\", name) / (\"unit\", unit)", "The action's argument." },
        { "button:SetAttribute(\"type2\", kind)", "Per mouse button (2 = right) and modifier (\"shift-type1\")." },
        { "button:RegisterForClicks(\"AnyUp\", \"AnyDown\")", "Both: the template acts on down or up depending on the ActionButtonUseKeyDown CVar." },
        { "InCombatLockdown()", "True while protected changes are refused." },
        { "PLAYER_REGEN_DISABLED / PLAYER_REGEN_ENABLED", "Combat starts (last chance for changes) / ends (apply what was queued)." },
        { "frame:IsProtected()", "protected, explicit: whether a frame is protected, and whether by its own template." },
        { "SecureHandlerClickTemplate, SecureHandlerStateTemplate, RegisterStateDriver", "Restricted snippets that change secure frames in combat (paging, visibility)." },
    },
    refs = {
        "Blizzard_FrameXML/SecureTemplates.xml",
        "Blizzard_FrameXML/SecureTemplates.lua (SECURE_ACTIONS)",
        "Blizzard_FrameXML/SecureHandlers.lua",
    },
})

-- @snippet securebutton-window
-- A small window of its own on UIParent: it cannot be hidden in combat (it contains a protected
-- button), so it must not be part of a window that should still close then.
local function CreateSecureWindow()
    local window = CreateFrame("Frame", nil, UIParent, "DefaultPanelTemplate")
    window:SetSize(240, 110)
    window:SetPoint("CENTER", 350, 0)
    window:SetFrameStrata("DIALOG")
    window:SetTitle("Secure button")
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)

    window.Status = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    window.Status:SetPoint("BOTTOM", 0, 12)

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function()
        if InCombatLockdown() then
            -- Refused now: close when combat ends.
            window.Status:SetText("In combat: closes after combat")
            window:RegisterEvent("PLAYER_REGEN_ENABLED")
        else
            window:Hide()
        end
    end)
    window:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_ENABLED" then
            self:UnregisterEvent(event)
            self.Status:SetText("")
            self:Hide()
        end
    end)

    -- Secure template first, visuals after: UIPanelButtonTemplate has no OnClick to override it.
    local button = CreateFrame("Button", nil, window, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    button:SetSize(180, 26)
    button:SetPoint("CENTER", 0, -4)
    button:RegisterForClicks("AnyUp", "AnyDown")
    window.Button = button
    return window
end

-- Out of combat only; returns false when refused.
local function SetSecureAction(button, kind, argument, label)
    if InCombatLockdown() then
        return false
    end
    button:SetAttribute("type", kind)
    button:SetAttribute("macrotext", kind == "macro" and argument or nil)
    button:SetAttribute("unit", kind == "target" and argument or nil)
    button:SetText(label)
    return true
end
-- @end

local ACTIONS = {
    wave = { "macro", "/wave", "Wave (macro)" },
    cheer = { "macro", "/cheer", "Cheer (macro)" },
    self = { "target", "player", "Target yourself" },
    clear = { "target", "none", "Clear target" },
}

local secureWindow

ns.AddExample("securebutton", {
    id = "securebutton-window",
    title = "A secure button in its own window",
    description = "Open the window, pick an action, click the window's button. In combat the action "
        .. "still runs, but changing it, moving the window or closing it is refused (closing waits "
        .. "for the end of combat). The gallery window stays closable: the button is not in it.",
    height = 70,
    code = { "securebutton-window" },
    create = function(stage)
        local status = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        status:SetPoint("CENTER")
        status:SetText("The secure window opens next to the gallery.")
        return status
    end,
    controls = {
        { type = "button", key = "open", label = "Open the window" },
        { type = "choice", key = "action", label = "Action", default = "wave", choices = {
            { "wave", "Wave (macro)" }, { "cheer", "Cheer (macro)" }, { "self", "Target yourself" }, { "clear", "Clear target" },
        }, code = function(value)
            local action = ACTIONS[value]
            local argument = action[1] == "macro" and "macrotext" or "unit"
            return ("button:SetAttribute(\"type\", %q)\nbutton:SetAttribute(%q, %q)"):format(action[1], argument, action[2])
        end },
    },
    apply = function(status, key, value, values)
        if InCombatLockdown() then
            status:SetText("In combat: try again after combat.")
            return
        end
        if key == "open" and not secureWindow then
            secureWindow = CreateSecureWindow()
        end
        if secureWindow then
            local action = ACTIONS[values.action]
            SetSecureAction(secureWindow.Button, action[1], action[2], action[3])
            if key == "open" then
                secureWindow:Show()
            end
            status:SetText("Action: " .. action[3])
        end
    end,
})
