local _, ns = ...

ns.AddComponent({
    id = "scrolllist",
    family = "layout",
    title = "Scroll list (ScrollBox)",
    summary = "ScrollBox + DataProvider is the modern list: a view creates only the visible rows from a "
        .. "pool, an initializer fills each row from its data, and changing the DataProvider updates "
        .. "the list. Replaces FauxScrollFrame and HybridScrollFrame.",
    clients = "Retail, Forever",
    requires = { "scrollBox" },
    keywords = "list table rows scroll virtual DataProvider WowScrollBoxList MinimalScrollBar",
    whenToUse = {
        "Any list longer than its frame: logs, inventories, search results.",
        "Short fixed content that only needs scrolling: a ScrollFrame (ScrollFrameTemplate) is simpler.",
    },
    api = {
        { "CreateFrame(\"Frame\", nil, parent, \"WowScrollBoxList\")", "The list area." },
        { "CreateFrame(\"EventFrame\", nil, parent, \"MinimalScrollBar\")", "The thin modern scroll bar." },
        { "local view = CreateScrollBoxListLinearView()", "Rows stacked vertically (also: CreateScrollBoxListGridView, tree views)." },
        { "view:SetElementInitializer(templateOrFrameType, fn(frame, data))", "Row template (or a frame type such as \"Button\") and how to fill it. Frames are recycled: reset everything you set." },
        { "view:SetElementExtent(height) / SetElementExtentCalculator(fn(index, data))", "Row height, fixed or per row." },
        { "view:SetElementFactory(fn(factory, data))", "Several row kinds: call factory(template, initializer) per data." },
        { "ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)", "Wires the three together." },
        { "CreateDataProvider(table) / provider:Insert(data) / Remove / Flush / SetSortComparator", "The rows' data; the list follows its changes." },
        { "scrollBox:SetDataProvider(provider [, ScrollBoxConstants.RetainScrollPosition])", "Show a provider." },
        { "scrollBox:ScrollToElementData(data) / ForEachFrame(fn(frame, data))", "Navigation and updates of the visible rows." },
    },
    refs = {
        "Blizzard_SharedXML/Shared/Scroll/ScrollTemplates.xml",
        "Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua",
        "Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua",
        "Blizzard_SharedXMLBase/DataProvider.lua",
    },
})

-- @snippet scrolllist-lua
local function CreateZoneList(parent)
    local list = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    list:SetSize(260, 140)
    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", list, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 6, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(20)
    -- A plain "Button" frame type: the initializer creates its regions the first time.
    view:SetElementInitializer("Button", function(row, data)
        if not row.Label then
            row.Label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row.Label:SetPoint("LEFT", 6, 0)
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.1)
        end
        row.Label:SetFormattedText("%d. %s", data.index, data.name)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(list, scrollBar, view)

    local provider = CreateDataProvider()
    for i = 1, 60 do
        provider:Insert({ index = i, name = "Zone " .. i })
    end
    list:SetDataProvider(provider)
    list.provider = provider
    return list
end
-- @end

ns.AddExample("scrolllist", {
    id = "scrolllist-lua",
    title = "List with a Lua-only row",
    description = "60 rows, about 7 frames: scroll and the same frames are re-filled. The \"Add row\" "
        .. "button inserts into the DataProvider and the list updates by itself.",
    height = 170,
    code = { "scrolllist-lua" },
    create = function(stage)
        local list = CreateZoneList(stage)
        list:SetPoint("CENTER", -8, 0)
        return list
    end,
    controls = {
        { type = "button", key = "add", label = "Add row" },
        { type = "button", key = "bottom", label = "Scroll to end" },
    },
    apply = function(list, key)
        local provider = list.provider
        if key == "add" then
            local index = provider:GetSize() + 1
            provider:Insert({ index = index, name = "New zone " .. index })
        elseif key == "bottom" then
            list:ScrollToEnd()
        end
    end,
})

-- @snippet scrolllist-xml-usage
local function CreateItemList(parent, items)
    local list = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    list:SetSize(280, 140)
    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", list, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 6, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("UIGalleryItemRowTemplate", function(row, data)
        row:Init(data)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(list, scrollBar, view)
    list:SetDataProvider(CreateDataProvider(items))
    return list
end
-- @end

local ITEM_ICONS = {
    "Interface\\Icons\\INV_Sword_04", "Interface\\Icons\\INV_Shield_06", "Interface\\Icons\\INV_Potion_51",
    "Interface\\Icons\\INV_Misc_Gem_01", "Interface\\Icons\\INV_Chest_Cloth_17",
}

ns.AddExample("scrolllist", {
    id = "scrolllist-xml",
    title = "List with an XML row template",
    description = "The row's layout (icon, name, count) lives in XML with a mixin; the size comes from the "
        .. "template, so no SetElementExtent is needed.",
    height = 170,
    code = { "scrolllist-xml", { "scrolllist-xml-mixin", "Mixin" }, { "scrolllist-xml-usage", "Usage" } },
    create = function(stage)
        local items = {}
        for i = 1, 25 do
            items[i] = { name = "Item " .. i, icon = ITEM_ICONS[(i - 1) % #ITEM_ICONS + 1], count = i * 3 }
        end
        local list = CreateItemList(stage, items)
        list:SetPoint("CENTER", -8, 0)
        return list
    end,
})

-- @snippet scrolllist-xml-mixin
UIGalleryItemRowMixin = {}

function UIGalleryItemRowMixin:Init(data)
    self.Icon:SetTexture(data.icon)
    self.Name:SetText(data.name)
    self.Count:SetText(data.count)
end
-- @end
