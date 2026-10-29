local _, ns = ...

ns.AddComponent({
    id = "texture",
    family = "visuals",
    title = "Texture and atlas",
    summary = "A Texture draws a file, an atlas (a named region of a sheet, with its own size) or a "
        .. "flat colour. Vertex colour, alpha, desaturation, blend mode, texture coordinates and "
        .. "rotation change how it renders without new art.",
    clients = "Retail, Forever, Classic (atlas names differ per client: check them in each)",
    keywords = "image icon atlas file color tint desaturate blend rotate crop texcoord",
    whenToUse = {
        "Atlases for Blizzard art: SetAtlas(name, useAtlasSize) keeps the right size and crop.",
        "Files for icons (Interface\\Icons\\...) and your own art (power-of-two TGA/BLP).",
        "SetColorTexture for flat fills, lines and debug boxes.",
    },
    api = {
        { "parent:CreateTexture(name, layer [, template, subLevel])", "Layers: BACKGROUND, BORDER, ARTWORK, OVERLAY, HIGHLIGHT; subLevel -8..7 orders within a layer." },
        { "SetTexture(fileOrID) / SetAtlas(name [, useAtlasSize]) / SetColorTexture(r, g, b, a)", "What to draw. C_Texture.GetAtlasInfo(name) is nil for an unknown atlas." },
        { "SetVertexColor(r, g, b [, a]) / SetAlpha(a)", "Tint (multiplies the texture) and opacity." },
        { "SetDesaturated(bool) / SetDesaturation(0..1)", "Greyscale." },
        { "SetBlendMode(\"BLEND\" | \"ADD\" | \"MOD\" | \"ALPHAKEY\" | \"DISABLE\")", "ADD brightens: glows, highlights.", "BLEND" },
        { "SetTexCoord(left, right, top, bottom)", "Crop / flip; icons use 0.07..0.93 to hide their border." },
        { "SetRotation(radians [, normalizedPoint])", "Rotate around the centre or a point." },
        { "SetTextureSliceMargins(l, t, r, b) / SetTextureSliceMode(mode)", "Nine-slice one texture so it stretches without distorting its corners." },
        { "XML: <Texture file atlas useAtlasSize alphaMode alpha desaturated><Color/><TexCoords/></Texture>", "Same, declared." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua",
        "Blizzard_APIDocumentationGenerated/SimpleTextureAPIDocumentation.lua",
        "BlizzardInterfaceResources: Resources/AtlasInfo.lua (atlas names)",
    },
})

local SOURCES = { { "icon", "Icon file" }, { "atlas", "Atlas" }, { "color", "Colour" } }
local BLEND_MODES = { { "BLEND" }, { "ADD" }, { "MOD" }, { "ALPHAKEY" }, { "DISABLE" } }

-- @snippet texture-basic
local function CreateSample(parent)
    local texture = parent:CreateTexture(nil, "ARTWORK")
    texture:SetSize(96, 96)
    return texture
end

local function SetSource(texture, source)
    texture:SetTexCoord(0, 1, 0, 1)
    if source == "icon" then
        texture:SetTexture("Interface\\Icons\\INV_Misc_Gem_01")
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- hide the icon's border
    elseif source == "atlas" then
        texture:SetAtlas("UI-HUD-ActionBar-IconFrame")
    else
        texture:SetColorTexture(0.2, 0.6, 1, 1)
    end
end
-- @end

ns.AddExample("texture", {
    id = "texture-basic",
    title = "One texture, every render setting",
    description = "Switch the source, then tint, fade, desaturate, rotate and change the blend mode. ADD "
        .. "on a dark stage brightens; MOD darkens what is behind.",
    height = 140,
    code = { "texture-basic" },
    create = function(stage)
        local texture = CreateSample(stage)
        texture:SetPoint("CENTER")
        return texture
    end,
    controls = {
        { type = "choice", key = "source", label = "Source", choices = SOURCES, default = "icon", code = "SetSource(texture, %s)" },
        { type = "slider", key = "alpha", label = "Alpha", min = 0, max = 1, step = 0.05, default = 1, code = "texture:SetAlpha(%s)" },
        { type = "slider", key = "rotation", label = "Rotation (degrees)", min = 0, max = 360, step = 5, default = 0, code = "texture:SetRotation(math.rad(%s))" },
        { type = "check", key = "desaturated", label = "Desaturated", default = false, code = "texture:SetDesaturated(%s)" },
        { type = "check", key = "tint", label = "Red vertex colour", default = false, code = function(value) return value and "texture:SetVertexColor(1, 0.3, 0.3)" or "texture:SetVertexColor(1, 1, 1)" end },
        { type = "choice", key = "blend", label = "Blend mode", choices = BLEND_MODES, default = "BLEND", code = "texture:SetBlendMode(%s)" },
    },
    apply = function(texture, key, value)
        if key == "source" then
            SetSource(texture, value)
        elseif key == "alpha" then
            texture:SetAlpha(value)
        elseif key == "rotation" then
            texture:SetRotation(math.rad(value))
        elseif key == "desaturated" then
            texture:SetDesaturated(value)
        elseif key == "tint" then
            if value then
                texture:SetVertexColor(1, 0.3, 0.3)
            else
                texture:SetVertexColor(1, 1, 1)
            end
        elseif key == "blend" then
            texture:SetBlendMode(value)
        end
    end,
})
