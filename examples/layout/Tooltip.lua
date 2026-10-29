local _, ns = ...

ns.AddComponent({
    id = "tooltip",
    family = "layout",
    title = "Tooltip",
    summary = "GameTooltip is the shared tooltip: claim it with SetOwner on enter, fill it with lines, "
        .. "Show, and Hide on leave. SharedTooltipTemplates.lua adds helpers for the standard colours "
        .. "(title, normal, instruction, error lines).",
    clients = "Retail, Forever, Classic",
    keywords = "hover help hint GameTooltip SetOwner AddLine",
    whenToUse = {
        "Explain an icon or a control on hover.",
        "Game objects (items, spells, units) have their own setters: SetItemByID, SetSpellByID, SetUnit.",
    },
    api = {
        { "GameTooltip:SetOwner(owner, anchor [, x, y])", "Takes the tooltip. Anchors: ANCHOR_RIGHT, ANCHOR_LEFT, ANCHOR_TOP, ANCHOR_BOTTOM, ANCHOR_CURSOR, ANCHOR_TOPLEFT, ANCHOR_NONE..." },
        { "GameTooltip_SetTitle(tooltip, text [, color, wrap])", "First line in the title style." },
        { "GameTooltip_AddNormalLine / AddHighlightLine / AddInstructionLine / AddErrorLine(tooltip, text [, wrap])", "Lines in the standard colours." },
        { "tooltip:AddLine(text [, r, g, b, wrap])", "A free line." },
        { "tooltip:AddDoubleLine(left, right [, lr, lg, lb, rr, rg, rb])", "Two columns." },
        { "tooltip:AddTexture(file) / GameTooltip_AddBlankLineToTooltip(tooltip)", "An icon at the start of the last line; an empty line." },
        { "tooltip:Show() / Hide()", "Show after filling (it sizes itself then); hide in OnLeave." },
    },
    refs = {
        "Blizzard_SharedXML/SharedTooltipTemplates.lua",
        "Blizzard_SharedXML/SharedTooltipTemplates.xml",
    },
})

-- @snippet tooltip-basic
local function ShowSpellTooltip(owner, anchor)
    GameTooltip:SetOwner(owner, anchor)
    GameTooltip_SetTitle(GameTooltip, "Surge of Light")
    GameTooltip:AddDoubleLine("Instant", "30 yd range", 1, 1, 1, 1, 1, 1)
    GameTooltip_AddNormalLine(GameTooltip, "Your next Flash Heal is instant and costs no mana.", true)
    GameTooltip_AddBlankLineToTooltip(GameTooltip)
    GameTooltip_AddInstructionLine(GameTooltip, "Left-click to cast")
    GameTooltip_AddErrorLine(GameTooltip, "Not enough mana")
    GameTooltip:Show()
end

local function CreateTooltipIcon(parent)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(48, 48)
    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\Icons\\Spell_Holy_SurgeOfLight")

    icon.anchor = "ANCHOR_RIGHT"
    icon:SetScript("OnEnter", function(self) ShowSpellTooltip(self, self.anchor) end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return icon
end
-- @end

ns.AddExample("tooltip", {
    id = "tooltip-basic",
    title = "Hover tooltip",
    description = "Hover the icon. Change the anchor to see where SetOwner puts the tooltip.",
    height = 90,
    code = { "tooltip-basic" },
    create = function(stage)
        local icon = CreateTooltipIcon(stage)
        icon:SetPoint("CENTER")
        return icon
    end,
    controls = {
        {
            type = "choice", key = "anchor", label = "Anchor", default = "ANCHOR_RIGHT",
            code = "GameTooltip:SetOwner(self, %s)",
            choices = {
                { "ANCHOR_RIGHT" }, { "ANCHOR_LEFT" }, { "ANCHOR_TOP" }, { "ANCHOR_BOTTOM" },
                { "ANCHOR_TOPLEFT" }, { "ANCHOR_BOTTOMRIGHT" }, { "ANCHOR_CURSOR" },
            },
        },
    },
    apply = function(icon, key, value)
        if key == "anchor" then
            icon.anchor = value
        end
    end,
})
