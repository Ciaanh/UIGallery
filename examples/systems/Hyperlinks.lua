local _, ns = ...

ns.AddComponent({
    id = "hyperlinks",
    family = "systems",
    title = "Hyperlinks",
    summary = "Clickable text: an escape sequence \"\\124Htype:data\\124h[text]\\124h\" inside a "
        .. "FontString. A frame with hyperlinks enabled gets OnHyperlinkEnter / Leave / Click for the "
        .. "links of its FontStrings. Item, spell and quest links show their tooltip with "
        .. "GameTooltip:SetHyperlink; \"addon:\" links are yours, and clicks on them in chat arrive "
        .. "through EventRegistry's \"SetItemRef\" event.",
    clients = "Retail, Forever",
    keywords = "link hyperlink item spell chat click tooltip SetHyperlink SetItemRef addon link escape",
    whenToUse = {
        "Item, spell or achievement names in your own frames that the player can hover or shift-click.",
        "An \"addon:\" link printed in chat that opens your window or runs an action.",
    },
    api = {
        { "frame:SetHyperlinksEnabled(enabled)", "Deliver link scripts for the frame's FontStrings (also XML hyperlinksEnabled=\"true\")." },
        { "OnHyperlinkEnter(self, link, text, region) / OnHyperlinkLeave(self)", "Hover; link is the \"type:data\" part, text the whole escape." },
        { "OnHyperlinkClick(self, link, text, button)", "Click on a link." },
        { "GameTooltip:SetHyperlink(link)", "Tooltip of an item, spell, quest, achievement... link." },
        { "SetItemRef(link, text, button, chatFrame)", "What chat does on a click: ItemRefTooltip, shift-click to insert in the edit box, ctrl-click to try on." },
        { "LinkUtil.FormatLink(linkType, displayText, ...)", "Builds \"\\124Htype:a:b\\124h[text]\\124h\" (without the colour)." },
        { "LinkUtil.ExtractLink(text)", "linkType, linkOptions, displayText of the first link in text." },
        { "EventRegistry:RegisterCallback(\"SetItemRef\", fn, owner)", "fn(owner, link, text, button, chatFrame) for clicks on \"addon:\" links in chat." },
    },
    refs = {
        "Blizzard_SharedXML/LinkUtil.lua",
        "Blizzard_UIPanels_Game/Shared/ItemRefHandlersShared.lua (LinkTypes.AddOn)",
    },
})

-- @snippet hyperlinks-frame
-- "\124" is the pipe, the escape character of WoW text: \124c colour, \124H link, \124r reset.
local HEARTHSTONE = "\124cffffffff\124Hitem:6948\124h[Hearthstone]\124h\124r"
local FIREBALL = "\124cff71d5ff\124Hspell:133\124h[Fireball]\124h\124r"
local OWN_LINK = "\124cff40c040\124Haddon:UIGallery:demo\124h[an addon link]\124h\124r"

local function CreateLinkText(parent, onAddonLink)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(420, 60)
    frame:EnableMouse(true)
    frame:SetHyperlinksEnabled(true)

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT")
    text:SetWidth(420)
    text:SetJustifyH("LEFT")
    text:SetText(("Hover %s or %s, click them, shift-click with the chat box open, or click %s.")
        :format(HEARTHSTONE, FIREBALL, OWN_LINK))

    frame:SetScript("OnHyperlinkEnter", function(self, link)
        if not link:find("^addon:") then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    frame:SetScript("OnHyperlinkClick", function(self, link, linkText, button)
        if link:find("^addon:UIGallery:") then
            onAddonLink(link)
        else
            -- What chat does: tooltip, shift-click to insert, ctrl-click to try on.
            SetItemRef(link, linkText, button, self)
        end
    end)
    return frame
end
-- @end

ns.AddExample("hyperlinks", {
    id = "hyperlinks-frame",
    title = "Links in your own frame",
    description = "One FontString with three links. The frame handles them: item and spell links get "
        .. "their tooltip and the chat behaviour, the addon link is handled here.",
    height = 110,
    code = { "hyperlinks-frame" },
    create = function(stage)
        local result = stage:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        result:SetPoint("BOTTOMLEFT", 16, 10)
        local clicks = 0
        local frame = CreateLinkText(stage, function(link)
            clicks = clicks + 1
            result:SetFormattedText("%s clicked (%d)", link, clicks)
        end)
        frame:SetPoint("TOPLEFT", 16, -14)
        return frame
    end,
})

-- @snippet hyperlinks-chat
local chatOwner = {}

-- Chat sends clicks on "addon:" links to EventRegistry's "SetItemRef" event. One callback per
-- owner: registering again replaces it.
local function ListenToChatLinks(onClick)
    EventRegistry:RegisterCallback("SetItemRef", function(_, link)
        if link:find("^addon:UIGallery:") then
            onClick(link)
        end
    end, chatOwner)
end

local function PrintAddonLink()
    local link = LinkUtil.FormatLink("addon", "[Click me]", "UIGallery", "chat")
    print("UIGallery: \124cff40c040" .. link .. "\124r")
end
-- @end

ns.AddExample("hyperlinks", {
    id = "hyperlinks-chat",
    title = "Addon links in chat",
    description = "Print a link to the chat window, then click it there: the click comes back through "
        .. "EventRegistry and shows below.",
    height = 70,
    code = { "hyperlinks-chat" },
    create = function(stage)
        local result = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        result:SetPoint("CENTER")
        result:SetText("No click yet")
        local clicks = 0
        ListenToChatLinks(function(link)
            clicks = clicks + 1
            result:SetFormattedText("%s clicked in chat (%d)", link, clicks)
        end)
        return result
    end,
    controls = {
        { type = "button", key = "print", label = "Print to chat" },
    },
    apply = function(_, key)
        if key == "print" then
            PrintAddonLink()
        end
    end,
})
