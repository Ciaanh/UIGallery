local _, ns = ...

ns.AddComponent({
    id = "icon-browser",
    family = "assets",
    title = "Icon browser",
    summary = "The icons the macro and equipment-set pickers offer, through IconDataProviderMixin: "
        .. "mostly file IDs (numbers), a few INTERFACE\\ICONS paths. The game has no file names for "
        .. "file IDs, so search matches the number or the path.",
    clients = "Retail, Forever, Classic",
    requires = { "scrollBox", "iconProvider" },
    keywords = "icon texture fileID macro picker IconDataProvider GetMacroIcons asset",
    whenToUse = {
        "Finding an icon for a button, a minimap or compartment entry, a menu.",
        "Letting the player choose one: the IconSelector templates (macro UI) take the same provider.",
    },
    api = {
        { "CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.None)", "Loads the icon list (spell then item icons). Other extra types add the spellbook's, the equipment's or the transmog outfit's icons first." },
        { "provider:GetNumIcons() / GetIconByIndex(index)", "Count and entries; index 1 is the question mark (134400)." },
        { "provider:Release()", "Drops the shared list once no provider uses it: copy what you keep, then release." },
        { "Texture:SetTexture(fileID or path)", "Draws an icon." },
        { "\"\\124T\" .. fileID .. \":16\\124t\"", "The icon inline in a FontString's text (size 16)." },
        { "XML: <Frame inherits=\"IconSelectorPopupFrameTemplate\" mixin=\"YourMixin\">", "The macro UI's icon popup (name box, filter, grid, Okay / Cancel). Your OnShow gives it an icon data provider and the selector's data." },
        { "popup.IconSelector:SetSelectionsDataProvider(getIcon(index), getCount())", "What the grid shows." },
        { "popup.IconSelector:SetSelectedCallback(fn(index, icon)) / SetSelectedIndex(index)", "Selection." },
        { "popup.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()", "The chosen icon, for your OkayButton_OnClick override." },
    },
    refs = {
        "Blizzard_FrameXMLBase/IconDataProvider.lua",
        "Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml / .lua (IconSelectorPopupFrameTemplate)",
        "Blizzard_GuildBankUI/Mainline/Blizzard_GuildBankUI.lua (GuildBankPopupFrameMixin: a full user)",
        "Blizzard_MacroUI/Blizzard_MacroUI.lua (the macro icon picker)",
    },
})

-- @snippet icon-browser
local iconEntries

local function GetIconEntries()
    if not iconEntries then
        local provider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.None)
        iconEntries = {}
        for i = 1, provider:GetNumIcons() do
            local icon = provider:GetIconByIndex(i)
            iconEntries[i] = { icon = icon, lower = tostring(icon):lower() }
        end
        -- The provider's list is shared and large; keep the copy, free the original.
        provider:Release()
    end
    return iconEntries
end

local function FilterIcons(query)
    local all = GetIconEntries()
    if query == "" then
        return all
    end
    local matches = {}
    for _, entry in ipairs(all) do
        if entry.lower:find(query, 1, true) then
            matches[#matches + 1] = entry
        end
    end
    return matches
end
-- @end

local function IconCode(icon)
    local literal = type(icon) == "number" and tostring(icon) or ("%q"):format(icon)
    return ("texture:SetTexture(%s)\nfontString:SetText(\"\\124T\" .. %s .. \":16\\124t Text\")"):format(literal, literal)
end

ns.AddExample("icon-browser", {
    id = "icon-browser",
    title = "Icons",
    description = "Several thousand icons, some listed twice (spell and item lists overlap). Type digits "
        .. "of a file ID or part of a path; click an icon for the code.",
    height = 380,
    code = { { "icon-browser", "Icons" }, { "asset-grid", "Grid" } },
    create = function(stage)
        local preview
        return ns.CreateAssetBrowser(stage, {
            cellWidth = 40,
            cellHeight = 40,
            filter = FilterIcons,
            label = function(entry) return tostring(entry.icon) end,
            initCell = function(cell, entry)
                if not cell.Icon then
                    cell.Icon = cell:CreateTexture(nil, "ARTWORK")
                    cell.Icon:SetPoint("TOPLEFT", 2, -2)
                    cell.Icon:SetPoint("BOTTOMRIGHT", -2, 2)
                end
                cell.Icon:SetTexture(entry.icon)
            end,
            select = function(detail, entry)
                if not preview then
                    preview = detail.Preview:CreateTexture(nil, "ARTWORK")
                    preview:SetAllPoints()
                end
                preview:SetTexture(entry.icon)
                local kind = type(entry.icon) == "number" and "file ID" or "path"
                detail:Select(tostring(entry.icon), kind, IconCode(entry.icon))
            end,
        })
    end,
})

-- @snippet icon-picker-mixin
UIGalleryIconPickerMixin = {}

function UIGalleryIconPickerMixin:OnShow()
    IconSelectorPopupFrameTemplateMixin.OnShow(self)
    self.iconDataProvider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.None)
    local provider = self.iconDataProvider
    self.IconSelector:SetSelectionsDataProvider(GenerateClosure(provider.GetIconByIndex, provider),
        GenerateClosure(provider.GetNumIcons, provider))

    local selectedButton = self.BorderBox.SelectedIconArea.SelectedIconButton
    self.IconSelector:SetSelectedCallback(function(_, icon)
        selectedButton:SetIconTexture(icon)
        self:SetSelectedIconText()
    end)
    -- Start on the current icon, or the question mark (index 1).
    local index = self.icon and self:GetIndexOfIcon(self.icon) or 1
    self.IconSelector:SetSelectedIndex(index)
    selectedButton:SetIconTexture(self:GetIconByIndex(index))
    self.IconSelector:ScrollToSelectedIndex()
    self:SetSelectedIconText()
end

function UIGalleryIconPickerMixin:OnHide()
    IconSelectorPopupFrameTemplateMixin.OnHide(self)
    -- The icon list is large and shared: release it while the popup is closed.
    self.iconDataProvider:Release()
    self.iconDataProvider = nil
end

function UIGalleryIconPickerMixin:OkayButton_OnClick()
    self.icon = self.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
    IconSelectorPopupFrameTemplateMixin.OkayButton_OnClick(self) -- hides the popup
    if self.onAccept then
        self.onAccept(self.icon, self.BorderBox.IconSelectorEditBox:GetText())
    end
end
-- @end

-- @snippet icon-picker-open
local picker

local function OpenIconPicker(onAccept)
    if not picker then
        picker = CreateFrame("Frame", nil, UIParent, "UIGalleryIconPickerTemplate")
        -- The template anchors its TOPLEFT to its parent's TOPRIGHT (it was made to sit beside
        -- the macro window): on UIParent that is off screen. Clear it before placing it.
        picker:ClearAllPoints()
        picker:SetPoint("CENTER")
    end
    picker.onAccept = onAccept
    picker:Show()
end
-- @end

ns.AddExample("icon-browser", {
    id = "icon-picker",
    title = "Blizzard's icon picker popup",
    description = "The macro UI's popup, reused: name box, Spell / Item filter, the grid, and drag an "
        .. "item or spell onto it to pick its icon. Okay sends the choice back here.",
    height = 80,
    code = { { "icon-picker", "XML" }, { "icon-picker-mixin", "Mixin" }, { "icon-picker-open", "Usage" } },
    create = function(stage)
        local chosen = stage:CreateTexture(nil, "ARTWORK")
        chosen:SetSize(40, 40)
        chosen:SetPoint("LEFT", 20, 0)
        chosen:SetTexture(134400)
        chosen.Text = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        chosen.Text:SetPoint("LEFT", chosen, "RIGHT", 12, 0)
        chosen.Text:SetText("No icon chosen yet")
        return chosen
    end,
    controls = {
        { type = "button", key = "open", label = "Open the picker" },
    },
    apply = function(chosen, key)
        if key ~= "open" then
            return
        end
        OpenIconPicker(function(icon, name)
            chosen:SetTexture(icon)
            chosen.Text:SetFormattedText("%s, name %q", tostring(icon), name or "")
        end)
    end,
})
