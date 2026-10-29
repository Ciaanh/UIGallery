local _, ns = ...

ns.AddComponent({
    id = "font-browser",
    family = "assets",
    title = "Font browser",
    summary = "Every font object the client defines (GameFontNormal, SystemFont_Shadow_Med1, ...), "
        .. "drawn in itself: GetFonts lists their names, each object's GetFont gives its file, height "
        .. "and flags. A FontString inherits one with SetFontObject or inherits=\"\".",
    clients = "Retail, Forever, Classic",
    requires = { "scrollBox", "fontList" },
    keywords = "font object typeface text GameFontNormal SetFontObject GetFonts asset",
    whenToUse = {
        "Picking the font object that matches a Blizzard frame, instead of SetFont with a file and size.",
        "A font object follows the player's text-size and language settings; a raw SetFont does not.",
    },
    api = {
        { "GetFonts()", "Names of every font object, including Blizzard's internal ones." },
        { "fontObject:GetFont()", "file, height, flags (\"OUTLINE\", \"THICK\", \"MONOCHROME\")." },
        { "fontObject:GetTextColor() / GetShadowOffset() / GetShadowColor()", "The other settings it carries." },
        { "FontString:SetFontObject(fontObjectOrName)", "Use one. Resets colour, shadow and justification to the object's." },
        { "XML: <FontString inherits=\"GameFontNormal\"/>", "The same, declared." },
        { "CreateFont(name) / fontObject:CopyFontObject(other)", "Your own font object, starting from a Blizzard one." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/FontDocumentation.lua",
        "Blizzard_Fonts_Shared/Shared/FontStyles.xml (GameFontNormal and the other definitions)",
    },
})

-- @snippet font-browser
local fontEntries

local function GetFontEntries()
    if not fontEntries then
        fontEntries = {}
        local names = GetFonts()
        table.sort(names)
        for _, name in ipairs(names) do
            local object = _G[name]
            -- A few names have no global object; skip them.
            if type(object) == "table" and object.GetFont then
                fontEntries[#fontEntries + 1] = { name = name, object = object, lower = name:lower() }
            end
        end
    end
    return fontEntries
end

local function FilterFonts(query)
    local all = GetFontEntries()
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

local SAMPLE = "Azeroth 123"

local function FontInfo(object)
    local file, height, flags = object:GetFont()
    local r, g, b = object:GetTextColor()
    return ("%s, %s, flags %q, colour %.2f %.2f %.2f"):format(tostring(file),
        height and ("%.1f"):format(height) or "?", flags or "", r or 1, g or 1, b or 1)
end

local function FontCode(name)
    return ("text:SetFontObject(%q)\n<FontString inherits=\"%s\"/>"):format(name, name)
end

ns.AddExample("font-browser", {
    id = "font-browser",
    title = "Font objects",
    description = "Each cell is its font object's name, then a sample in that font. Some are made for "
        .. "parchment (black) or for one language's glyphs, so a few look empty on this background.",
    height = 380,
    code = { { "font-browser", "Fonts" }, { "asset-grid", "Grid" } },
    create = function(stage)
        local preview
        return ns.CreateAssetBrowser(stage, {
            cellWidth = 236,
            cellHeight = 44,
            filter = FilterFonts,
            label = function(entry) return entry.name end,
            initCell = function(cell, entry)
                if not cell.Name then
                    cell.Name = cell:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
                    cell.Name:SetPoint("TOPLEFT", 4, -3)
                    cell.Name:SetPoint("RIGHT", -4, 0)
                    cell.Name:SetJustifyH("LEFT")
                    cell.Name:SetWordWrap(false)
                    cell.Sample = cell:CreateFontString(nil, "ARTWORK")
                    cell.Sample:SetPoint("TOPLEFT", 4, -16)
                    cell.Sample:SetWordWrap(false)
                end
                cell.Name:SetText(entry.name)
                cell.Sample:SetFontObject(entry.object)
                cell.Sample:SetJustifyH("LEFT")
                cell.Sample:SetText(SAMPLE)
            end,
            select = function(detail, entry)
                if not preview then
                    preview = detail.Preview:CreateFontString(nil, "ARTWORK")
                    preview:SetPoint("CENTER")
                end
                preview:SetFontObject(entry.object)
                preview:SetText("Aa")
                detail:Select(entry.name, FontInfo(entry.object), FontCode(entry.name))
            end,
        })
    end,
})
