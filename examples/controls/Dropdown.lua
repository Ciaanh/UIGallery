local _, ns = ...

ns.AddComponent({
    id = "dropdown",
    family = "controls",
    title = "Dropdown and menu",
    summary = "Blizzard_Menu (10.x+) replaced UIDropDownMenu: a DropdownButton describes its menu in a "
        .. "generator function (radios, checkboxes, buttons, titles, dividers, submenus) and regenerates "
        .. "it each time it opens. The same descriptions build right-click context menus.",
    clients = "Retail, Forever (Classic still has UIDropDownMenu)",
    requires = { "menu" },
    keywords = "select combo menu context right-click radio WowStyle1DropdownTemplate MenuUtil",
    whenToUse = {
        "Choosing one value among several (radio) or several flags (checkboxes).",
        "Right-click actions on a frame: MenuUtil.CreateContextMenu.",
        "Avoid UIDropDownMenu in new Retail code: it taints and is deprecated.",
    },
    api = {
        { "CreateFrame(\"DropdownButton\", nil, parent, \"WowStyle1DropdownTemplate\")", "The standard dropdown (WowStyle2 is the darker variant)." },
        { "dropdown:SetupMenu(function(dropdown, rootDescription) ... end)", "The generator; called on every open." },
        { "rootDescription:CreateRadio(text, isSelected(data), setSelected(data), data)", "Radio entry; the dropdown shows the selected one's text." },
        { "rootDescription:CreateCheckbox(text, isSelected(data), setSelected(data), data)", "Toggle entry; the menu stays open." },
        { "rootDescription:CreateButton(text, callback(data), data)", "Action entry." },
        { "CreateTitle(text) / CreateDivider() / CreateSpacer()", "Structure." },
        { "local sub = rootDescription:CreateButton(\"More\"); sub:CreateRadio(...)", "Any description can hold children: a submenu." },
        { "dropdown:SetDefaultText(text) / dropdown:GenerateMenu()", "Text when nothing is selected; rebuild after outside changes." },
        { "MenuUtil.CreateContextMenu(owner, function(owner, rootDescription) ... end)", "Context menu at the cursor." },
    },
    refs = {
        "Blizzard_Menu/MenuUtil.lua",
        "Blizzard_Menu/DropdownButton.lua",
        "Blizzard_Menu/Classic/MenuTemplates.xml (WowStyle1DropdownTemplate)",
    },
})

-- @snippet dropdown-radio
local function CreateSizeDropdown(parent, onSelect)
    local sizes = { "Small", "Medium", "Large" }
    local selected = "Medium"

    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(180)
    dropdown:SetupMenu(function(_, rootDescription)
        rootDescription:CreateTitle("Icon size")
        for _, size in ipairs(sizes) do
            rootDescription:CreateRadio(size,
                function() return selected == size end,
                function()
                    selected = size
                    onSelect(size)
                end)
        end
    end)
    return dropdown
end
-- @end

ns.AddExample("dropdown", {
    id = "dropdown-radio",
    title = "Single choice (radio)",
    description = "The dropdown's text follows the selected radio. The generator closes over `selected`: "
        .. "the menu is rebuilt from it on every open.",
    height = 80,
    code = { "dropdown-radio" },
    create = function(stage)
        local output = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        output:SetPoint("BOTTOM", 0, 8)
        local dropdown = CreateSizeDropdown(stage, function(size) output:SetText("Selected: " .. size) end)
        dropdown:SetPoint("CENTER", 0, 8)
        return dropdown
    end,
})

-- @snippet dropdown-checkboxes
local function CreateFilterDropdown(parent, filters)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(180)
    dropdown:SetDefaultText("Filters")
    dropdown:SetupMenu(function(_, rootDescription)
        for _, key in ipairs({ "quests", "rares", "treasures" }) do
            rootDescription:CreateCheckbox(key,
                function() return filters[key] end,
                function() filters[key] = not filters[key] end)
        end
        rootDescription:CreateDivider()
        local more = rootDescription:CreateButton("Sort by")
        for _, order in ipairs({ "Name", "Distance" }) do
            more:CreateRadio(order,
                function() return filters.sort == order end,
                function() filters.sort = order end)
        end
        rootDescription:CreateButton("Reset", function()
            filters.quests, filters.rares, filters.treasures = true, false, false
        end)
    end)
    return dropdown
end

local function AttachContextMenu(frame)
    frame:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton == "RightButton" then
            MenuUtil.CreateContextMenu(self, function(_, rootDescription)
                rootDescription:CreateTitle("Context menu")
                rootDescription:CreateButton("Say hello", function() print("Hello") end)
            end)
        end
    end)
end
-- @end

ns.AddExample("dropdown", {
    id = "dropdown-checkboxes",
    title = "Checkboxes, submenu and context menu",
    description = "Checkboxes keep the menu open; \"Sort by\" opens a submenu. Right-click the grey "
        .. "square for a context menu built from the same descriptions.",
    height = 90,
    code = { "dropdown-checkboxes" },
    create = function(stage)
        local filters = { quests = true, rares = false, treasures = false, sort = "Name" }
        local dropdown = CreateFilterDropdown(stage, filters)
        dropdown:SetPoint("CENTER", -60, 0)

        local target = CreateFrame("Frame", nil, stage)
        target:SetSize(60, 40)
        target:SetPoint("LEFT", dropdown, "RIGHT", 20, 0)
        local background = target:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(0.4, 0.4, 0.45, 0.8)
        local label = target:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        label:SetPoint("CENTER")
        label:SetText("Right-click")
        AttachContextMenu(target)
        return dropdown
    end,
})
