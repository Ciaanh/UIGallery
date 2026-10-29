local _, ns = ...

ns.AddComponent({
    id = "tabs",
    family = "layout",
    title = "Tabs",
    summary = "TabSystemTemplate is the modern tab strip (Professions, Settings-era panels): AddTab "
        .. "returns an id, a single callback reacts to the selection, and the strip lays its tabs out "
        .. "itself. Your code shows the matching content.",
    clients = "Retail, Forever (Classic: PanelTabButtonTemplate + PanelTemplates_*)",
    requires = { "tabSystem" },
    keywords = "tab strip pages sections TabSystemTemplate",
    whenToUse = {
        "Two to six peer views of the same window.",
        "More, or a hierarchy: a list on the side (like this gallery) scales better.",
    },
    api = {
        { "CreateFrame(\"Frame\", nil, parent, \"TabSystemTemplate\")", "Horizontal layout frame; tabs hang below their anchor by default (isTabOnTop false)." },
        { "tabID = tabSystem:AddTab(text)", "Adds a tab, returns its id (1, 2, ...)." },
        { "tabSystem:SetTabSelectedCallback(fn(tabID, isUserAction) -> suppress)", "Called on select; return true to keep the old tab looking selected." },
        { "tabSystem:SetTab(tabID)", "Select programmatically (calls the callback)." },
        { "SetTabEnabled(tabID, enabled, errorReason) / SetTabShown(tabID, shown)", "Disable with a tooltip reason, or hide a tab." },
        { "KeyValues: minTabWidth, maxTabWidth, tabTemplate, spacing", "Set on the template in XML (or as fields before tabs are added)." },
        { "TabSystemOwnerMixin", "Optional helper that maps tab ids to content frames (AddNamedTab, GetElementsForTab)." },
    },
    refs = {
        "Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.xml",
        "Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.lua",
        "Blizzard_SharedXML/Shared/TabSystem/TabSystemOwner.lua",
    },
})

-- @snippet tabs-basic
local function CreateTabbedPanel(parent)
    local panel = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    panel:SetSize(340, 100)

    local tabs = CreateFrame("Frame", nil, panel, "TabSystemTemplate")
    tabs:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 12, 2)

    local pages = {}
    for _, name in ipairs({ "General", "Display", "Profiles" }) do
        local page = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
        page:SetPoint("CENTER")
        page:SetText(name .. " page")
        pages[tabs:AddTab(name)] = page
    end

    tabs:SetTabSelectedCallback(function(selectedID)
        for tabID, page in pairs(pages) do
            page:SetShown(tabID == selectedID)
        end
    end)
    tabs:SetTab(1)
    panel.Tabs = tabs
    return panel
end
-- @end

ns.AddExample("tabs", {
    id = "tabs-basic",
    title = "Tab strip under a panel",
    description = "Three tabs hanging below an inset; the callback shows one page at a time. The last "
        .. "control disables the third tab with a reason (hover it).",
    height = 150,
    code = { "tabs-basic" },
    create = function(stage)
        local panel = CreateTabbedPanel(stage)
        panel:SetPoint("CENTER", 0, 14)
        return panel
    end,
    controls = {
        { type = "check", key = "profiles", label = "Profiles tab enabled", default = true },
    },
    apply = function(panel, key, value)
        if key == "profiles" then
            panel.Tabs:SetTabEnabled(3, value, "Profiles are not available yet.")
        end
    end,
})
