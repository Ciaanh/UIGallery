local _, ns = ...

ns.AddComponent({
    id = "helptip",
    family = "layout",
    title = "Help tips and glow boxes",
    summary = "The yellow tutorial callouts. HelpTip:Show draws a pointed tip next to a region, with "
        .. "a close or \"Got it\" button and an optional CVar that remembers it was seen. GlowBoxTemplate "
        .. "is the same yellow glowing box as a plain template, for callouts you place yourself.",
    clients = "Retail, Forever",
    keywords = "help tip tutorial callout hint pointer arrow glow box HelpTip GlowBoxTemplate onboarding",
    whenToUse = {
        "Pointing out a new or unused control once: a HelpTip with a CVar or bitfield to remember it.",
        "A permanent highlighted explanation inside your own window: GlowBoxTemplate.",
        "HelpTip respects the player's \"Tutorials\" option (hideHelptips CVar): Show returns false then.",
    },
    api = {
        { "HelpTip:Show(parent, info [, relativeRegion])", "Shows the tip next to relativeRegion (default parent); false if tutorials are off. Owned by parent: HelpTip:Hide(parent, text)." },
        { "info.text / info.buttonStyle", "Text; HelpTip.ButtonStyle.None, Close, Okay, GotIt, Next, Exit.", "None" },
        { "info.targetPoint / info.alignment / info.offsetX / info.offsetY", "HelpTip.Point.RightEdgeCenter, TopEdgeLeft...; HelpTip.Alignment.Left / Center / Right.", "RightEdgeCenter, Center" },
        { "info.onAcknowledgeCallback / info.onHideCallback", "Called with info.callbackArg after the button / after any hide (with a HelpTip.HideReason)." },
        { "info.cvar + cvarValue / info.cvarBitfield + bitfieldFlag", "Remember the tip was acknowledged; it is not shown again." },
        { "HelpTip:HideAllSystem(system) + info.system", "Group your tips under one system name to hide them together." },
        { "HelpTip:IsShowing(parent, text) / HelpTip:HideAll(parent)", "Query and cleanup." },
        { "CreateFrame(\"Frame\", nil, parent, \"GlowBoxTemplate\")", "The glowing box (BG, glow corners); pair with GlowBoxArrowTemplate (.Arrow, .Glow)." },
    },
    refs = {
        "Blizzard_SharedXML/HelpTip.lua (every info field documented at the top)",
        "Blizzard_HelpPlate/Blizzard_HelpPlate.xml (GlowBoxTemplate, GlowBoxArrowTemplate)",
    },
})

local POINTS = {
    { "RightEdgeCenter", "RightEdgeCenter" }, { "LeftEdgeCenter", "LeftEdgeCenter" },
    { "TopEdgeCenter", "TopEdgeCenter" }, { "BottomEdgeCenter", "BottomEdgeCenter" },
}
local STYLES = { { "Close", "Close" }, { "GotIt", "GotIt" }, { "Okay", "Okay" }, { "None", "None" } }

-- @snippet helptip-show
local TIP_TEXT = "This button does something new. Try it."

local function ShowTip(owner, target, pointName, styleName, onAcknowledge)
    HelpTip:Hide(owner, TIP_TEXT)
    return HelpTip:Show(owner, {
        text = TIP_TEXT,
        buttonStyle = HelpTip.ButtonStyle[styleName],
        targetPoint = HelpTip.Point[pointName],
        alignment = HelpTip.Alignment.Center,
        onAcknowledgeCallback = onAcknowledge,
        system = "UIGalleryDemo",
    }, target)
end
-- @end

ns.AddExample("helptip", {
    id = "helptip-show",
    title = "HelpTip next to a button",
    description = "The tip follows the target point and button style. Its button calls "
        .. "onAcknowledgeCallback; with a cvar it would also never show again.",
    height = 200,
    code = { "helptip-show" },
    create = function(stage)
        local target = CreateFrame("Button", nil, stage, "UIPanelButtonTemplate")
        target:SetSize(120, 26)
        target:SetPoint("CENTER")
        target:SetText("New feature")
        target.Status = stage:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        target.Status:SetPoint("BOTTOMLEFT", 10, 8)
        target.owner = stage
        return target
    end,
    controls = {
        { type = "choice", key = "point", label = "Target point", choices = POINTS, default = "RightEdgeCenter", code = function(_, values)
            return ("ShowTip(owner, target, %q, %q, OnAcknowledge)"):format(values.point, values.style)
        end },
        { type = "choice", key = "style", label = "Button style", choices = STYLES, default = "Close", code = false },
        { type = "button", key = "show", label = "Show again" },
        { type = "button", key = "hide", label = "Hide" },
    },
    apply = function(target, key, _, values)
        if key == "hide" then
            HelpTip:Hide(target.owner, TIP_TEXT)
            return
        end
        local shown = ShowTip(target.owner, target, values.point, values.style, function()
            target.Status:SetText("Acknowledged")
        end)
        target.Status:SetText(shown and "" or "Not shown: the Tutorials option is off (hideHelptips CVar).")
    end,
})

-- @snippet helptip-glowbox
local function CreateGlowCallout(parent, text)
    local box = CreateFrame("Frame", nil, parent, "GlowBoxTemplate")
    box:SetSize(240, 56)
    box.Text = box:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
    box.Text:SetPoint("TOPLEFT", 12, -10)
    box.Text:SetPoint("BOTTOMRIGHT", -12, 10)
    box.Text:SetText(text)

    box.Arrow = CreateFrame("Frame", nil, box, "GlowBoxArrowTemplate")
    box.Arrow:SetPoint("TOP", box, "BOTTOM", 0, 3)
    return box
end
-- @end

ns.AddExample("helptip", {
    id = "helptip-glowbox",
    title = "GlowBoxTemplate (placed by hand)",
    description = "The same look without HelpTip's pool and rules: a frame you anchor, size and fill "
        .. "yourself. The arrow template points down; rotate or flip its textures for other sides.",
    height = 130,
    code = { "helptip-glowbox" },
    create = function(stage)
        local box = CreateGlowCallout(stage, "A glow box explains the element under the arrow.")
        box:SetPoint("TOP", 0, -16)
        return box
    end,
    controls = {
        { type = "check", key = "arrow", label = "Arrow", default = true, code = "box.Arrow:SetShown(%s)" },
        { type = "slider", key = "width", label = "Width", min = 160, max = 400, step = 10, default = 240, code = "box:SetWidth(%s)" },
    },
    apply = function(box, key, value)
        if key == "arrow" then
            box.Arrow:SetShown(value)
        elseif key == "width" then
            box:SetWidth(value)
        end
    end,
})
