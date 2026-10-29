local _, ns = ...

-- A component's page, top to bottom: family, title, summary, clients, "When to use", the example
-- cards, the API table (the component's options) and the Blizzard source files it comes from.
-- Built once per component on first view; the window keeps it.
local Page = {}
ns.Page = Page

local SECTION_GAP = 18
local NAME_COLUMN = 250

-- Every block is a region plus the gap above it; Layout stacks them and sizes the page.
local function AddBlock(page, region, gap, height)
    table.insert(page.blocks, { region = region, gap = gap or 6, height = height })
    return region
end

local function AddText(page, fontObject, text, gap, indent)
    local fs = page:CreateFontString(nil, "ARTWORK", fontObject)
    fs:SetWidth(page:GetWidth() - (indent or 0))
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    fs:SetText(text)
    fs.indent = indent
    return AddBlock(page, fs, gap)
end

local CLIENTS = { { "retail", "Retail" }, { "forever", "Forever" }, { "classic", "Classic" } }

-- "Retail Forever Classic", green where the row's symbols are in that client's UI source.
local function AvailabilityText(info)
    local parts = {}
    for _, client in ipairs(CLIENTS) do
        local color = info[client[1]] and "ff40c040" or "ffd04040"
        table.insert(parts, ("|c%s%s|r"):format(color, client[2]))
    end
    return table.concat(parts, "  ")
end

local function ShowMissing(row)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, "Not in this client's UI source")
    for _, client in ipairs(CLIENTS) do
        local missing = row.availability.missing[client[1]]
        if missing then
            GameTooltip_AddNormalLine(GameTooltip, client[2] .. ": " .. missing)
        end
    end
    GameTooltip:Show()
end

-- The generated entry for a row, unless the row changed since tools/gen-availability.py ran.
local function GetAvailability(componentId, index, name)
    local rows = ns.Availability and ns.Availability[componentId]
    local info = rows and rows[index]
    if info and info.name == name and info.retail ~= nil then
        return info
    end
end

local function AddApiRow(page, entry, availability)
    local row = CreateFrame("Frame", nil, page)
    row:SetWidth(page:GetWidth())

    local line = row:CreateTexture(nil, "BACKGROUND")
    line:SetColorTexture(1, 1, 1, 0.08)
    line:SetPoint("TOPLEFT")
    line:SetPoint("TOPRIGHT")
    line:SetHeight(1)

    local name = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    name:SetPoint("TOPLEFT", 4, -6)
    name:SetWidth(NAME_COLUMN - 12)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(true)
    name:SetText(entry[1])

    local description = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", NAME_COLUMN, -6)
    description:SetWidth(page:GetWidth() - NAME_COLUMN - 4)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)
    local text = entry[2] or ""
    if entry[3] then
        text = text .. "\nDefault: " .. entry[3]
    end
    description:SetText(text)

    local nameHeight = name:GetStringHeight()
    if availability then
        local badges = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        badges:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        badges:SetText(AvailabilityText(availability))
        nameHeight = nameHeight + 3 + badges:GetStringHeight()
        if availability.missing then
            row.availability = availability
            row:EnableMouse(true)
            row:SetScript("OnEnter", ShowMissing)
            row:SetScript("OnLeave", GameTooltip_Hide)
        end
    end

    row:SetHeight(math.max(nameHeight, description:GetStringHeight()) + 12)
    return AddBlock(page, row, 0)
end

function Page:Create(parent, width, component)
    local page = CreateFrame("Frame", nil, parent)
    page:SetWidth(width)
    page:SetHeight(1)
    page.blocks = {}
    page.component = component

    AddText(page, "GameFontDisableSmall", component.familyTitle, 0)
    local title = AddText(page, "GameFontNormalHuge", component.title, 4)

    local codeEntries = {}
    for _, example in ipairs(component.examples) do
        for _, entry in ipairs(example.code) do
            table.insert(codeEntries, { id = type(entry) == "table" and entry[1] or entry, title = example.title })
        end
    end
    if #codeEntries > 0 then
        local allCode = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
        allCode:SetText("All code")
        allCode:SetSize(100, 22)
        allCode:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
        allCode:SetScript("OnClick", function()
            ns.CodeView:ShowAll(component.title, codeEntries)
        end)
        title:SetWidth(page:GetWidth() - 110)
    end
    AddText(page, "GameFontHighlight", component.summary, 8)
    if component.clients then
        AddText(page, "GameFontDisableSmall", "Clients: " .. component.clients, 8)
    end
    local missing = ns.Capabilities:Missing(component.requires)
    if missing then
        AddText(page, "GameFontRedSmall",
            "This client lacks " .. ns.Capabilities.LABELS[missing] .. ": the examples cannot run here.", 4)
    end

    if component.whenToUse then
        AddText(page, "GameFontNormalLarge", "When to use", SECTION_GAP)
        for _, line in ipairs(component.whenToUse) do
            AddText(page, "GameFontHighlightSmall", "- " .. line, 4, 8)
        end
    end

    AddText(page, "GameFontNormalLarge", "Examples", SECTION_GAP)
    page.building = true
    for _, example in ipairs(component.examples) do
        local card = ns.Card:Create(page, width, example, function() Page.Layout(page) end)
        AddBlock(page, card, 10)
    end
    page.building = nil

    if component.api and #component.api > 0 then
        AddText(page, "GameFontNormalLarge", "API", SECTION_GAP)
        AddText(page, "GameFontDisableSmall", "Under each name: the clients whose UI source has it, "
            .. "checked by tools/gen-availability.py. Hover a row with a red client for what is missing.", 4)
        for i, entry in ipairs(component.api) do
            AddApiRow(page, entry, GetAvailability(component.id, i, entry[1]))
        end
    end

    if component.refs and #component.refs > 0 then
        AddText(page, "GameFontNormalLarge", "Blizzard sources", SECTION_GAP)
        AddText(page, "GameFontDisableSmall", "Under Interface/AddOns/ in the client's UI source:", 4)
        for _, ref in ipairs(component.refs) do
            AddText(page, "GameFontHighlightSmall", ref, 2, 8)
        end
    end

    Page.Layout(page)
    return page
end

function Page.Layout(page)
    if page.building then
        return
    end
    local y = 0
    for _, block in ipairs(page.blocks) do
        local region = block.region
        y = y + block.gap
        region:ClearAllPoints()
        region:SetPoint("TOPLEFT", region.indent or 0, -y)
        if region.GetStringHeight then
            y = y + region:GetStringHeight()
        else
            y = y + region:GetHeight()
        end
    end
    page:SetHeight(y + 20)
end
