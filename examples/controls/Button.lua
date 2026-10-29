local _, ns = ...

ns.AddComponent({
    id = "button",
    family = "controls",
    title = "Button",
    summary = "Clickable frames. Blizzard's templates cover the panel button (red, stretches to its "
        .. "text), the close cross and many icon buttons; a plain Button with normal / pushed / "
        .. "highlight textures builds any other look.",
    clients = "Retail, Forever, Classic",
    keywords = "click press close icon action UIPanelButtonTemplate",
    whenToUse = {
        "UIPanelButtonTemplate for text actions in panels and dialogs.",
        "UIPanelCloseButton for the corner cross; it hides its parent by default.",
        "A custom Button (textures + mixin) for icons and toolbar actions.",
        "Ready-made small buttons: UIMenuButtonStretchTemplate (toolbars), UIPanelSquareButton (arrows, delete), UIExpandingButtonTemplate, RefreshButtonTemplate, UIPanelInfoButton.",
    },
    api = {
        { "CreateFrame(\"Button\", name, parent, template)", "UIPanelButtonTemplate, UIPanelCloseButton, UIPanelDynamicResizeButtonTemplate..." },
        { "SetText(text) / GetFontString()", "Label of a text button." },
        { "SetEnabled(bool) / Enable() / Disable()", "Disabled buttons grey out and ignore clicks." },
        { "SetScript(\"OnClick\", fn(self, mouseButton, down))", "The click handler." },
        { "RegisterForClicks(\"LeftButtonUp\", \"RightButtonUp\", ...)", "Which clicks fire OnClick.", "LeftButtonUp" },
        { "SetNormalTexture / SetPushedTexture / SetHighlightTexture / SetDisabledTexture", "The four visual states; highlight is drawn additively on hover." },
        { "SetNormalAtlas / SetPushedAtlas / SetHighlightAtlas", "Same from atlases." },
        { "SetMotionScriptsWhileDisabled(bool)", "Keep OnEnter / OnLeave (tooltips) on a disabled button." },
        { "SquareButton_SetIcon(button, \"LEFT\" | \"RIGHT\" | \"UP\" | \"DOWN\" | \"DELETE\")", "Icon of a UIPanelSquareButton." },
        { "expanding:SetUp(expanded, \"RIGHT\" | \"LEFT\") / SetLabel / RegisterCallback(fn(self, expanded)) / SetExpanded", "UIExpandingButtonTemplate. SetUp is required before the first click." },
    },
    refs = {
        "Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml (UIPanelButtonTemplate, UIPanelCloseButton)",
        "Blizzard_SharedXML/SecureUIPanelTemplates.xml",
        "Blizzard_UIPanelTemplates/Mainline/UIPanelTemplates.xml (UIPanelSquareButton, UIExpandingButtonTemplate)",
        "Blizzard_SharedXML/Shared/Button/IconButtonTemplate.xml (SquareIconButtonTemplate, base of RefreshButtonTemplate)",
    },
})

-- @snippet button-panel
local function CreatePanelButtons(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(320, 60)

    local accept = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
    accept:SetText(ACCEPT)
    accept:SetSize(120, 24)
    accept:SetPoint("LEFT")

    local close = CreateFrame("Button", nil, holder, "UIPanelCloseButton")
    close:SetPoint("LEFT", accept, "RIGHT", 16, 0)
    -- The template hides its parent on click; replace the handler to do something else.
    close:SetScript("OnClick", function() accept:SetText(CLOSE) end)

    local counter = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    counter:SetPoint("LEFT", close, "RIGHT", 16, 0)
    local clicks = 0
    accept:SetScript("OnClick", function(self)
        clicks = clicks + 1
        counter:SetFormattedText("Clicked %d times", clicks)
        self:SetText(ACCEPT)
    end)

    holder.Accept = accept
    return holder
end
-- @end

ns.AddExample("button", {
    id = "button-panel",
    title = "Panel button and close button",
    description = "Labels come from GlobalStrings (ACCEPT, CLOSE) so they follow the client's language.",
    height = 80,
    code = { "button-panel" },
    create = function(stage)
        local holder = CreatePanelButtons(stage)
        holder:SetPoint("CENTER")
        return holder
    end,
    controls = {
        { type = "check", key = "enabled", label = "Enabled", default = true, code = "holder.Accept:SetEnabled(%s)" },
        { type = "slider", key = "width", label = "Width", min = 60, max = 200, step = 5, default = 120, code = "holder.Accept:SetWidth(%s)" },
    },
    apply = function(holder, key, value)
        if key == "enabled" then
            holder.Accept:SetEnabled(value)
        elseif key == "width" then
            holder.Accept:SetWidth(value)
        end
    end,
})

-- @snippet button-icon-usage
local function CreateIconButtons(parent)
    local icons = {
        "Interface\\Icons\\Spell_Holy_SurgeOfLight",
        "Interface\\Icons\\Spell_Nature_Lightning",
        "Interface\\Icons\\Spell_Fire_FlameBolt",
    }
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(3 * 44, 40)
    row.buttons = {}
    for i, file in ipairs(icons) do
        -- UIGalleryIconButtonTemplate and its mixin are in the XML tab.
        local button = CreateFrame("Button", nil, row, "UIGalleryIconButtonTemplate")
        button:SetPoint("LEFT", (i - 1) * 44, 0)
        button:SetIcon(file, "Spell " .. i)
        row.buttons[i] = button
    end
    return row
end
-- @end

ns.AddExample("button", {
    id = "button-icon",
    title = "Icon buttons (XML template + mixin)",
    description = "A Button declared in XML with its normal, pushed and highlight textures and a mixin "
        .. "for behaviour: SetIcon, a tooltip on hover, a press flash. Hover and click them.",
    height = 80,
    code = { "button-icon", { "button-icon-mixin", "Mixin" }, { "button-icon-usage", "Usage" } },
    create = function(stage)
        local row = CreateIconButtons(stage)
        row:SetPoint("CENTER")
        return row
    end,
    controls = {
        { type = "check", key = "desaturate", label = "Desaturate icons", default = false, code = "button.Icon:SetDesaturated(%s) -- each button" },
    },
    apply = function(row, key, value)
        if key == "desaturate" then
            for _, button in ipairs(row.buttons) do
                button.Icon:SetDesaturated(value)
            end
        end
    end,
})

-- @snippet button-icon-mixin
UIGalleryIconButtonMixin = {}

function UIGalleryIconButtonMixin:SetIcon(file, tooltip)
    self.Icon:SetTexture(file)
    self.tooltip = tooltip
end

function UIGalleryIconButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, self.tooltip)
    GameTooltip:Show()
end

function UIGalleryIconButtonMixin:OnLeave()
    GameTooltip:Hide()
end

function UIGalleryIconButtonMixin:OnClick()
    self.Flash.Anim:Restart()
end
-- @end

-- @snippet button-variants
local function CreateButtonVariants(parent, onClick)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(520, 40)

    -- Silver, stretches to any width: toolbars and filter bars.
    local menu = CreateFrame("Button", nil, row, "UIMenuButtonStretchTemplate")
    menu:SetSize(90, 26)
    menu:SetText(FILTER)
    menu:SetPoint("LEFT")
    menu:SetScript("OnClick", function() onClick("UIMenuButtonStretchTemplate") end)

    -- Square buttons with an arrow or cross: SquareButton_SetIcon picks it.
    local previous = menu
    for _, icon in ipairs({ "LEFT", "RIGHT", "UP", "DOWN", "DELETE" }) do
        local square = CreateFrame("Button", nil, row, "UIPanelSquareButton")
        SquareButton_SetIcon(square, icon)
        square:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        square:SetScript("OnClick", function() onClick("UIPanelSquareButton " .. icon) end)
        previous = square
    end

    -- An arrow that flips between collapsed and expanded, with a label on its left.
    local expand = CreateFrame("Button", nil, row, "UIExpandingButtonTemplate")
    expand:SetPoint("LEFT", previous, "RIGHT", 90, 0)
    expand:SetLabel("Details")
    expand:SetUp(false, "RIGHT")
    expand:RegisterCallback(function(_, expanded)
        onClick("UIExpandingButtonTemplate " .. (expanded and "expanded" or "collapsed"))
    end)

    local refresh = CreateFrame("Button", nil, row, "RefreshButtonTemplate")
    refresh:SetPoint("LEFT", expand, "RIGHT", 10, 0)
    refresh:SetScript("OnClick", function() onClick("RefreshButtonTemplate") end)

    local info = CreateFrame("Button", nil, row, "UIPanelInfoButton")
    info:SetPoint("LEFT", refresh, "RIGHT", 6, 0)
    info:SetScript("OnClick", function() onClick("UIPanelInfoButton") end)

    row.Buttons = { menu, expand, refresh, info }
    return row
end
-- @end

ns.AddExample("button", {
    id = "button-variants",
    title = "Other button templates",
    description = "Silver stretch button, square arrow / delete buttons (SquareButton_SetIcon), the "
        .. "expanding arrow (it calls back with its state), the refresh icon button and the info icon. "
        .. "Click one: its template shows below.",
    height = 90,
    code = { "button-variants" },
    create = function(stage)
        local status = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("BOTTOM", 0, 10)
        local row = CreateButtonVariants(stage, function(name) status:SetText(name) end)
        row:SetPoint("CENTER", 0, 8)
        return row
    end,
    controls = {
        { type = "check", key = "enabled", label = "Enabled", default = true, code = "button:SetEnabled(%s) -- each button" },
    },
    apply = function(row, key, value)
        if key == "enabled" then
            for _, button in ipairs(row.Buttons) do
                button:SetEnabled(value)
            end
        end
    end,
})
