local _, ns = ...

ns.AddComponent({
    id = "mask",
    family = "visuals",
    title = "Mask texture",
    summary = "A MaskTexture clips other textures to its alpha: round portraits, icons in a ring, "
        .. "shaped fills. One mask can clip several textures; a texture can take several masks.",
    clients = "Retail, Forever, Classic",
    keywords = "clip round circle portrait shape alpha mask",
    whenToUse = {
        "Round or shaped icons and portraits.",
        "Hiding part of a texture by shape (a gradient mask fades an edge).",
    },
    api = {
        { "parent:CreateMaskTexture([name, layer])", "The mask; position and size it like a texture." },
        { "mask:SetTexture(file, wrapH, wrapV)", "Its alpha is the shape. CLAMPTOBLACKADDITIVE keeps outside the image transparent." },
        { "mask:SetAtlas(name)", "Atlas masks exist too." },
        { "texture:AddMaskTexture(mask) / RemoveMaskTexture(mask)", "Apply or remove." },
        { "XML: <MaskTexture parentKey file><MaskedTextures><MaskedTexture childKey/></MaskedTextures></MaskTexture>", "Declared masks name the textures they clip." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/SimpleMaskTextureAPIDocumentation.lua",
        "Blizzard_AccountStore/Blizzard_AccountStoreCategoryList.xml (TempPortraitAlphaMask)",
    },
})

local MASKS = {
    { "circle", "Circle" },
    { "ring", "Ring (UIGallery media)" },
    { "none", "No mask" },
}

-- @snippet mask-circle
local MASK_FILES = {
    circle = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
    ring = "Interface\\AddOns\\UIGallery\\media\\ring",
}

local function CreateRoundIcon(parent)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(96, 96)
    icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")

    local mask = parent:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(MASK_FILES.circle, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)

    icon.Mask = mask
    return icon
end

local function SetMaskShape(icon, shape)
    if shape == "none" then
        icon:RemoveMaskTexture(icon.Mask)
        return
    end
    icon.Mask:SetTexture(MASK_FILES[shape], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:RemoveMaskTexture(icon.Mask)
    icon:AddMaskTexture(icon.Mask)
end
-- @end

ns.AddExample("mask", {
    id = "mask-circle",
    title = "Shaped icon",
    description = "The same icon clipped by Blizzard's round portrait mask, then by this addon's ring.",
    height = 130,
    code = { "mask-circle" },
    create = function(stage)
        local icon = CreateRoundIcon(stage)
        icon:SetPoint("CENTER")
        return icon
    end,
    controls = {
        { type = "choice", key = "shape", label = "Mask", choices = MASKS, default = "circle" },
    },
    apply = function(icon, key, value)
        if key == "shape" then
            SetMaskShape(icon, value)
        end
    end,
})
