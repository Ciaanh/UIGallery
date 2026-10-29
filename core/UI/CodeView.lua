local _, ns = ...

-- A read-only, copyable code block: one tab button per snippet, a multi-line EditBox sized to its
-- text (the page's scroll frame does the scrolling). Focusing it selects everything, so Ctrl+C
-- copies the snippet.
local CodeView = {}
ns.CodeView = CodeView

local TAB_HEIGHT = 22
local PADDING = 8
local FONT = "ChatFontNormal"
local LANG_LABELS = { lua = "Lua", xml = "XML" }

-- One hidden FontString measures text height for every code view.
local measure

local function MeasureHeight(text, width)
    if not measure then
        measure = UIParent:CreateFontString(nil, "BACKGROUND", FONT)
        measure:Hide()
        measure:SetJustifyH("LEFT")
        measure:SetWordWrap(true)
        measure:SetNonSpaceWrap(true)
    end
    measure:SetWidth(width)
    measure:SetText(text)
    return measure:GetStringHeight()
end

local function TabLabel(snippet, index, count)
    local label = LANG_LABELS[snippet.lang] or snippet.lang
    if snippet.label then
        return snippet.label
    end
    return count > 1 and (label .. " " .. index) or label
end

-- A read-only multi-line EditBox: focus selects everything, typing puts the code back.
function CodeView:CreateEditBox(parent, width)
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(FONT)
    editBox:SetMaxLetters(0)
    editBox:SetTextColor(0.85, 0.9, 1)
    editBox:SetWidth(width)
    editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
    editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    editBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(self.code)
            self:HighlightText()
        end
    end)
    -- Sets the text and fits the height to it; returns the height.
    function editBox:SetCode(code)
        self.code = code
        self:SetText(code)
        self:SetCursorPosition(0)
        local height = MeasureHeight(code, self:GetWidth()) + 4
        self:SetHeight(height)
        return height
    end
    return editBox
end

-- The calls matching an example's current control values, under its controls.
function CodeView:CreateLive(parent, width)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.04, 0.06, 0.04, 0.95)
    box:SetBackdropBorderColor(0.25, 0.4, 0.25, 1)
    box:SetWidth(width)
    local label = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    label:SetPoint("TOPLEFT", PADDING, -6)
    label:SetText("Calls for the current settings")
    local editBox = CodeView:CreateEditBox(box, width - 2 * PADDING)
    editBox:SetPoint("TOPLEFT", PADDING, -20)
    function box:SetCode(code)
        self:SetHeight(20 + editBox:SetCode(code) + 6)
    end
    return box
end

-- snippetIds: the example's `code` list. onResize() is called when the height changes.
function CodeView:Create(parent, width, snippetIds, onResize)
    local view = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    view:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    view:SetBackdropColor(0.04, 0.04, 0.06, 0.95)
    view:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    view:SetWidth(width)

    -- Entries are snippet ids, or { id, tabLabel }.
    view.snippets = {}
    for _, entry in ipairs(snippetIds) do
        local id, label = entry, nil
        if type(entry) == "table" then
            id, label = entry[1], entry[2]
        end
        local snippet = ns.Registry:Snippet(id) or { lang = "lua", code = "-- missing snippet: " .. id }
        table.insert(view.snippets, { lang = snippet.lang, file = snippet.file, code = snippet.code, label = label })
    end

    view.tabs = {}
    local counts = {}
    for _, snippet in ipairs(view.snippets) do
        counts[snippet.lang] = (counts[snippet.lang] or 0) + 1
    end
    local seen, x = {}, PADDING
    for i, snippet in ipairs(view.snippets) do
        seen[snippet.lang] = (seen[snippet.lang] or 0) + 1
        local tab = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
        tab:SetText(TabLabel(snippet, seen[snippet.lang], counts[snippet.lang]))
        tab:SetSize(math.max(60, tab:GetFontString():GetStringWidth() + 24), TAB_HEIGHT)
        tab:SetPoint("TOPLEFT", x, -PADDING)
        tab:SetScript("OnClick", function() CodeView.Show(view, i) end)
        x = x + tab:GetWidth() + 4
        view.tabs[i] = tab
    end

    local hint = view:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPRIGHT", -PADDING, -PADDING - 5)
    hint:SetText("Click the code, then Ctrl+C to copy")

    local file = view:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    file:SetPoint("TOPLEFT", PADDING, -PADDING - TAB_HEIGHT - 6)
    view.File = file

    local editBox = CodeView:CreateEditBox(view, width - 2 * PADDING)
    editBox:SetPoint("TOPLEFT", PADDING, -PADDING - TAB_HEIGHT - 22)
    view.EditBox = editBox
    view.onResize = onResize

    CodeView.Show(view, 1)
    return view
end

function CodeView.Show(view, index)
    local snippet = view.snippets[index]
    if not snippet then
        return
    end
    for i, tab in ipairs(view.tabs) do
        tab:SetEnabled(i ~= index)
    end
    view.File:SetText(snippet.file or "")
    local textHeight = view.EditBox:SetCode(snippet.code) - 4
    view:SetHeight(PADDING + TAB_HEIGHT + 22 + textHeight + 4 + PADDING)
    if view.onResize then
        view.onResize()
    end
end

-- One window showing every snippet of a page, to copy them all at once.
local allCodeFrame

function CodeView:ShowAll(title, entries)
    if not allCodeFrame then
        local frame = CreateFrame("Frame", "UIGalleryAllCodeFrame", UIParent, "ButtonFrameTemplate")
        ButtonFrameTemplate_HidePortrait(frame)
        ButtonFrameTemplate_HideButtonBar(frame)
        frame:SetSize(760, 600)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        table.insert(UISpecialFrames, frame:GetName())

        local hint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        hint:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 0, 14)
        hint:SetText("Click the code, then Ctrl+A and Ctrl+C to copy")

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame.Inset, "ScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 8, -8)
        scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)
        local editBox = CodeView:CreateEditBox(scrollFrame, 760 - 60)
        scrollFrame:SetScrollChild(editBox)
        frame.EditBox = editBox
        frame.ScrollFrame = scrollFrame
        allCodeFrame = frame
    end

    local parts = {}
    for _, entry in ipairs(entries) do
        local snippet = ns.Registry:Snippet(entry.id)
        if snippet then
            local comment = snippet.lang == "xml" and "<!-- %s -->" or "-- %s"
            table.insert(parts, comment:format(entry.title .. " (" .. (snippet.file or entry.id) .. ")"))
            table.insert(parts, snippet.code)
            table.insert(parts, "")
        end
    end
    allCodeFrame:SetTitle(title .. ": all code")
    allCodeFrame.EditBox:SetCode(table.concat(parts, "\n"))
    allCodeFrame.ScrollFrame:SetVerticalScroll(0)
    allCodeFrame:Show()
end
