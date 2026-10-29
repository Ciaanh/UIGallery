local addonName, ns = ...

-- Bootstrap: SavedVariables, capability probe, slash command, addon compartment.
--   /uigallery            toggle the window
--   /uigallery <search>   open it on the first component matching <search> (id or title)

local function FindComponent(query)
    query = query:lower()
    for _, family in ipairs(ns.Registry.FAMILIES) do
        for _, component in ipairs(family.components) do
            if component.id == query then
                return component.id
            end
        end
    end
    for _, family in ipairs(ns.Registry.FAMILIES) do
        for _, component in ipairs(family.components) do
            if ns.Registry:Matches(component, query) then
                return component.id
            end
        end
    end
end

SLASH_UIGALLERY1 = "/uigallery"
SLASH_UIGALLERY2 = "/uig"
SlashCmdList.UIGALLERY = function(msg)
    msg = strtrim(msg or "")
    if msg == "" then
        ns.Window:Toggle()
        return
    end
    local componentId = FindComponent(msg)
    if componentId then
        ns.Window:Show(componentId)
    else
        ns.Print("no component matches \"" .. msg .. "\".")
    end
end

-- Named by the toc's AddonCompartmentFunc.
function UIGallery_OnAddonCompartmentClick()
    ns.Window:Toggle()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    UIGalleryDB = UIGalleryDB or {}
    ns.Capabilities:Probe()
end)
