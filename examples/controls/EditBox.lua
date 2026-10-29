local _, ns = ...

ns.AddComponent({
    id = "editbox",
    family = "controls",
    title = "Edit box",
    summary = "Text input. InputBoxTemplate is the bordered single line, SearchBoxTemplate adds a "
        .. "magnifier, placeholder and clear button, ScrollingEditBoxTemplate is a scrolling multi-line "
        .. "area with a callback registry.",
    clients = "Retail, Forever, Classic (ScrollingEditBoxTemplate: Retail, Forever)",
    keywords = "input text field search multiline textarea InputBoxTemplate SearchBoxTemplate",
    whenToUse = {
        "Names, numbers (SetNumeric), filters (SearchBoxTemplate), notes (ScrollingEditBoxTemplate).",
        "Always SetAutoFocus(false) unless the box should grab the keyboard as soon as it shows.",
    },
    api = {
        { "SetAutoFocus(bool)", "Take keyboard focus when shown. Templates set it to false.", "true for a raw EditBox" },
        { "SetText / GetText / SetMaxLetters / SetNumeric", "Content and limits." },
        { "OnEnterPressed / OnEscapePressed / OnTextChanged(self, userInput)", "Scripts. Clear focus on escape, or the player cannot move." },
        { "SearchBoxTemplate: .Instructions, .clearButton", "Placeholder text and clear button; HookScript OnTextChanged to keep the template's behaviour." },
        { "ScrollingEditBoxTemplate: SetText, GetText, GetEditBox, GetScrollBox, SetDefaultText", "Multi-line area; RegisterCallback(\"OnTextChanged\", ...)." },
        { "ScrollUtil.RegisterScrollBoxWithScrollBar(box:GetScrollBox(), scrollBar)", "Attach a MinimalScrollBar to the scrolling edit box." },
    },
    refs = {
        "Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml",
        "Blizzard_SharedXML/Shared/Scroll/ScrollTemplates.xml (ScrollingEditBoxTemplate)",
        "Blizzard_Calendar/Mainline/Blizzard_Calendar.lua (a scrolling edit box with a bar)",
    },
})

-- @snippet editbox-single
local function CreateNameInput(parent, onSubmit)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(200, 22)
    input:SetAutoFocus(false)
    input:SetMaxLetters(24)
    input:SetScript("OnEnterPressed", function(self)
        onSubmit(self:GetText())
        self:ClearFocus()
    end)
    input:SetScript("OnEscapePressed", input.ClearFocus)
    return input
end

local function CreateFilterBox(parent, onFilter)
    local search = CreateFrame("EditBox", nil, parent, "SearchBoxTemplate")
    search:SetSize(200, 22)
    -- HookScript, not SetScript: the template's own handler shows / hides the placeholder.
    search:HookScript("OnTextChanged", function(self)
        onFilter(self:GetText())
    end)
    return search
end
-- @end

ns.AddExample("editbox", {
    id = "editbox-single",
    title = "Input and search box",
    description = "Type a name and press Enter; type in the search box to see the filter callback.",
    height = 110,
    code = { "editbox-single" },
    create = function(stage)
        local output = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        output:SetPoint("BOTTOM", 0, 10)
        local input = CreateNameInput(stage, function(text) output:SetText("Submitted: " .. text) end)
        input:SetPoint("TOP", 0, -18)
        local search = CreateFilterBox(stage, function(text) output:SetText("Filter: " .. text) end)
        search:SetPoint("TOP", input, "BOTTOM", 0, -10)
        return input
    end,
    controls = {
        { type = "check", key = "numeric", label = "Numeric only", default = false, code = "input:SetNumeric(%s)" },
    },
    apply = function(input, key, value)
        if key == "numeric" then
            input:SetNumeric(value)
        end
    end,
})

-- @snippet editbox-multiline
local function CreateNotesArea(parent)
    local area = CreateFrame("Frame", nil, parent, "ScrollingEditBoxTemplate")
    area:SetSize(300, 90)

    local background = area:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.5)

    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", area, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", area, "BOTTOMRIGHT", 6, 0)
    ScrollUtil.RegisterScrollBoxWithScrollBar(area:GetScrollBox(), scrollBar)

    area:SetDefaultText("Write your notes here...")
    return area
end
-- @end

ns.AddExample("editbox", {
    id = "editbox-multiline",
    title = "Scrolling multi-line area",
    description = "Type several lines: the area scrolls and the bar follows. The placeholder shows while empty.",
    height = 120,
    code = { "editbox-multiline" },
    create = function(stage)
        local area = CreateNotesArea(stage)
        area:SetPoint("CENTER", -8, 0)
        return area
    end,
})
