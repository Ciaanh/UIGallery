local _, ns = ...

ns.AddComponent({
    id = "atlas-browser",
    family = "assets",
    title = "Atlas browser",
    summary = "Every texture atlas of the client, by name: C_Texture.GetAtlasElements lists them and "
        .. "C_Texture.GetAtlasInfo gives each one's size, file and texture coordinates. Search, click "
        .. "one, copy the call that draws it.",
    clients = "Retail, Forever, Classic",
    requires = { "scrollBox", "atlasList" },
    keywords = "atlas texture art icon sprite SetAtlas GetAtlasInfo search asset",
    whenToUse = {
        "Finding Blizzard art for a frame: borders, arrows, badges, backgrounds, map pins.",
        "Prefer an atlas to a texture path with tex coords: the atlas keeps working when Blizzard repacks its files.",
    },
    api = {
        { "C_Texture.GetAtlasElements()", "Every atlas name of the client (tens of thousands): build the list once." },
        { "C_Texture.GetAtlasInfo(atlas)", "width, height, file / filename, left/right/top/bottomTexCoord, tilesHorizontally / tilesVertically; nil for an unknown name." },
        { "C_Texture.GetAtlasExists(atlas)", "Whether a name is an atlas." },
        { "Texture:SetAtlas(atlas [, useAtlasSize [, filterMode]])", "Draw an atlas; useAtlasSize also sizes the texture to it." },
        { "XML: <Texture atlas=\"name\" useAtlasSize=\"true\"/>", "The same, declared." },
        { "CreateScrollBoxListGridView(stride, top, bottom, left, right, hSpacing, vSpacing)", "The grid: stride columns, padding, spacing (Grid tab)." },
        { "view:SetElementSize(width, height)", "Cell size of a grid view; SetElementExtent raises on it." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/TextureUtilsDocumentation.lua",
        "Blizzard_SharedXML/Shared/Scroll/ScrollBoxGridView.lua",
    },
})

-- @snippet atlas-browser
local atlasEntries

-- The full list, once: one table per atlas so the DataProvider can tell them apart.
local function GetAtlasEntries()
    if not atlasEntries then
        local names = C_Texture.GetAtlasElements()
        table.sort(names)
        atlasEntries = {}
        for i, name in ipairs(names) do
            atlasEntries[i] = { name = name, lower = name:lower() }
        end
    end
    return atlasEntries
end

local function FilterAtlases(query)
    local all = GetAtlasEntries()
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

-- Fits the atlas into the cell, keeping its aspect ratio.
local function DrawAtlas(texture, name, box)
    local info = C_Texture.GetAtlasInfo(name)
    local width, height = info and info.width or box, info and info.height or box
    local scale = math.min(box / math.max(width, 1), box / math.max(height, 1))
    texture:SetAtlas(name)
    texture:SetSize(math.max(width * scale, 1), math.max(height * scale, 1))
    return info
end
-- @end

local function AtlasCode(name, info)
    local lines = { ("texture:SetAtlas(%q, true)"):format(name) }
    if info then
        lines[1] = lines[1] .. (" -- %dx%d"):format(info.width, info.height)
    end
    table.insert(lines, ('<Texture atlas="%s" useAtlasSize="true"/>'):format(name))
    return table.concat(lines, "\n")
end

ns.AddExample("atlas-browser", {
    id = "atlas-browser",
    title = "Atlases",
    description = "Type part of a name (\"arrow\", \"checkmark\", \"UI-Frame\"): the list filters a "
        .. "quarter second after the last key. Click an atlas for its size, file and the code; hover "
        .. "for its name.",
    height = 380,
    code = { { "atlas-browser", "Atlases" }, { "asset-grid", "Grid" } },
    create = function(stage)
        local preview
        return ns.CreateAssetBrowser(stage, {
            cellWidth = 64,
            cellHeight = 64,
            filter = FilterAtlases,
            label = function(entry) return entry.name end,
            initCell = function(cell, entry)
                if not cell.Atlas then
                    cell.Atlas = cell:CreateTexture(nil, "ARTWORK")
                    cell.Atlas:SetPoint("CENTER")
                end
                DrawAtlas(cell.Atlas, entry.name, 56)
            end,
            select = function(detail, entry)
                if not preview then
                    preview = detail.Preview:CreateTexture(nil, "ARTWORK")
                    preview:SetPoint("CENTER")
                end
                local info = DrawAtlas(preview, entry.name, 64)
                local text
                if info then
                    text = ("%d x %d, file %s%s%s"):format(info.width, info.height,
                        tostring(info.filename or info.file),
                        info.tilesHorizontally and ", tiles horizontally" or "",
                        info.tilesVertically and ", tiles vertically" or "")
                end
                detail:Select(entry.name, text, AtlasCode(entry.name, info))
            end,
        })
    end,
})
