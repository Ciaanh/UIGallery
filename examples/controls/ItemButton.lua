local _, ns = ...

ns.AddComponent({
    id = "itembutton",
    family = "controls",
    title = "Item button",
    summary = "ItemButton is a frame type of its own (an intrinsic, created with CreateFrame(\"ItemButton\")): "
        .. "the bag-slot square with an icon, a stack count, a quality border and overlays. SetItem "
        .. "fills it from an item ID or link and waits for the item data if the client does not have it yet.",
    clients = "Retail, Forever",
    keywords = "item slot bag icon count stack quality border loot reward ItemButton",
    whenToUse = {
        "Showing an item: rewards, loot lists, an inventory of your own.",
        "Not for spells or plain icons: a Button with an icon texture is lighter.",
    },
    api = {
        { "CreateFrame(\"ItemButton\", nil, parent)", "37x37 slot: icon, Count, IconBorder, IconOverlay, normal / pushed / highlight textures. Left and right clicks registered." },
        { "button:SetItem(itemIDOrLink)", "Icon and quality border from the item; redraws when GET_ITEM_INFO_RECEIVED brings the data." },
        { "button:SetItemLocation(itemLocation)", "Same from an ItemLocation (bag and slot, equipment slot)." },
        { "button:SetItemButtonCount(count)", "Stack count, bottom right; hidden for 0 and 1." },
        { "button:SetItemButtonQuality(quality [, itemIDOrLink])", "Border colour from Enum.ItemQuality; nil hides the border." },
        { "button:SetItemButtonTexture(file) / SetItemButtonDesaturated(button, bool)", "Icon by hand; greyed-out icon (global function)." },
        { "button:GetItemID() / GetItemLink() / Reset()", "What it shows; Reset empties it." },
    },
    refs = {
        "Blizzard_ItemButton/Shared/ItemButtonTemplate.xml (the ItemButton intrinsic)",
        "Blizzard_ItemButton/Shared/ItemButtonTemplate.lua (ItemButtonMixin)",
        "Blizzard_ItemButton/Mainline/ItemButtonTemplate.lua (SetItemButtonCount, SetItemButtonQuality...)",
    },
})

local ITEMS = {
    { 6948, "Hearthstone" }, { 2589, "Linen Cloth" }, { 19019, "Thunderfury" },
}

-- @snippet itembutton-basic
local function CreateItemSlot(parent, itemID)
    local button = CreateFrame("ItemButton", nil, parent)
    button:SetItem(itemID)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button.itemID = itemID
    return button
end

local function ShowItem(button, itemID, count)
    button.itemID = itemID
    button:SetItem(itemID)
    button:SetItemButtonCount(count)
end
-- @end

ns.AddExample("itembutton", {
    id = "itembutton-basic",
    title = "Item slot",
    description = "Hover for the item tooltip. The border colour comes from the item's quality; the "
        .. "count only shows above 1.",
    height = 90,
    code = { "itembutton-basic" },
    create = function(stage)
        local button = CreateItemSlot(stage, ITEMS[1][1])
        button:SetPoint("CENTER")
        return button
    end,
    controls = {
        { type = "choice", key = "item", label = "Item", choices = ITEMS, default = 6948, code = "button:SetItem(%s)" },
        { type = "slider", key = "count", label = "Count", min = 0, max = 200, step = 1, default = 1, code = "button:SetItemButtonCount(%s)" },
        { type = "check", key = "desaturated", label = "Desaturated", default = false, code = "SetItemButtonDesaturated(button, %s)" },
    },
    apply = function(button, key, value, values)
        if key == "desaturated" then
            SetItemButtonDesaturated(button, value)
        else
            ShowItem(button, values.item, values.count)
            SetItemButtonDesaturated(button, values.desaturated)
        end
    end,
})
