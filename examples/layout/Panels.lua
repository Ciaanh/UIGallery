local _, ns = ...

ns.AddComponent({
    id = "panels",
    family = "layout",
    title = "Panels and borders",
    summary = "Frame chrome. Modern Blizzard frames draw their borders with NineSlice layouts (named "
        .. "sets of corner / edge / centre atlases); BackdropTemplate is the older tiled border, still "
        .. "the quickest flat box. Window templates (ButtonFrameTemplate, PortraitFrameTemplate) bundle "
        .. "a NineSlice, title and close button.",
    clients = "Retail, Forever (same layout list in both); BackdropTemplate everywhere",
    keywords = "frame border backdrop nineslice window dialog inset chrome background",
    whenToUse = {
        "A window: ButtonFrameTemplate or PortraitFrameTemplate (this gallery is a ButtonFrameTemplate).",
        "A sub-area inside a window: InsetFrameTemplate.",
        "A styled box in a Blizzard look: NineSlicePanelTemplate + a layout name.",
        "A flat box or a 1px border: BackdropTemplate with WHITE8X8.",
    },
    api = {
        { "CreateFrame(\"Frame\", nil, parent, \"NineSlicePanelTemplate\")", "An empty NineSlice; give it a layout. setAllPoints=\"true\" and frameLevel 500: ClearAllPoints before sizing it yourself." },
        { "NineSliceUtil.GetLayout(layoutName)", "The layout table: one { atlas, x, y } per piece. Its corner atlas size gives the smallest box the layout fits." },
        { "NineSliceUtil.ApplyLayoutByName(frame, layoutName)", "Named layouts from NineSliceLayouts.lua: Dialog, ButtonFrameTemplateNoPortrait, InsetFrameTemplate, TooltipDefaultLayout, GenericMetal, ..." },
        { "XML: <KeyValue key=\"layoutType\" value=\"Dialog\"/> on a NineSlicePanelTemplate", "Same, declared." },
        { "CreateFrame(\"Frame\", nil, parent, \"BackdropTemplate\")", "Adds SetBackdrop to any frame (required since 9.0)." },
        { "SetBackdrop({ bgFile, edgeFile, tile, tileSize, edgeSize, insets })", "Constants: BACKDROP_DIALOG_32_32, BACKDROP_DARK_DIALOG_32_32, BACKDROP_TOAST_12_12..." },
        { "SetBackdropColor / SetBackdropBorderColor(r, g, b, a)", "Tint centre and edge." },
        { "ButtonFrameTemplate_HidePortrait(frame) / _HideButtonBar(frame)", "Trim a ButtonFrameTemplate; frame:SetTitle(text) sets its title." },
    },
    refs = {
        "Blizzard_SharedXML/Mainline/NineSliceLayouts.lua",
        "Blizzard_SharedXML/NineSlice.lua",
        "Blizzard_SharedXML/Backdrop.lua",
        "Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml",
    },
})

local LAYOUTS = {
    { "Dialog" }, { "ButtonFrameTemplateNoPortrait" }, { "InsetFrameTemplate" },
    { "TooltipDefaultLayout" }, { "TooltipDefaultDarkLayout" }, { "GenericMetal" },
    { "SimplePanelTemplate" }, { "SelectionFrameTemplate" }, { "WoodenNeutralFrameTemplate" },
    { "ChatBubble" },
}

-- @snippet panels-nineslice
-- NineSlicePanelTemplate is setAllPoints="true": clear its anchors before sizing it, or it
-- covers its whole parent and SetSize does nothing.
local function CreateStyledBox(parent, layoutName, width, height)
    local box = CreateFrame("Frame", nil, parent, "NineSlicePanelTemplate")
    box:ClearAllPoints()
    box:SetSize(width, height)
    NineSliceUtil.ApplyLayoutByName(box, layoutName)

    -- Most layouts draw only the border: give the box its own background.
    local background = box:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", 6, -6)
    background:SetPoint("BOTTOMRIGHT", -6, 6)
    background:SetColorTexture(0.08, 0.08, 0.1, 0.95)
    box.Background = background
    return box
end

-- The corners keep their atlas size: a box smaller than two corners overlaps itself.
local function GetLayoutMinimumSize(layoutName)
    local corner = NineSliceUtil.GetLayout(layoutName).TopLeftCorner
    local info = corner and C_Texture.GetAtlasInfo(corner.atlas)
    if not info then
        return 0, 0
    end
    return 2 * info.width, 2 * info.height
end
-- @end

-- One box per layout: re-applying a layout over another leaves the pieces the new one does not
-- set (a Center, mirrored texture coordinates) from the previous one.
local function ShowLayout(holder, values)
    local layout = values.layout
    local minWidth, minHeight = GetLayoutMinimumSize(layout)
    local width, height = math.max(values.width, minWidth), math.max(values.height, minHeight)
    for name, box in pairs(holder.boxes) do
        box:SetShown(name == layout)
    end
    local box = holder.boxes[layout]
    if not box then
        box = CreateStyledBox(holder, layout, width, height)
        box:SetPoint("CENTER")
        box.Label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        box.Label:SetPoint("CENTER")
        holder.boxes[layout] = box
    end
    box:SetSize(width, height)
    box.Background:SetShown(values.background)
    box.Label:SetFormattedText("%s\n%d x %d (minimum %d x %d)", layout, width, height, minWidth, minHeight)
end

ns.AddExample("panels", {
    id = "panels-nineslice",
    title = "NineSlice layouts",
    description = "Corners and edges keep their atlas size, so each layout has a minimum size (two "
        .. "corners); the box grows to it. GenericMetal and WoodenNeutralFrameTemplate have 166px "
        .. "corners: they are made for full windows. Only ChatBubble draws its own centre.",
    height = 360,
    code = { "panels-nineslice" },
    create = function(stage)
        local holder = CreateFrame("Frame", nil, stage)
        holder:SetAllPoints()
        holder.boxes = {}
        return holder
    end,
    controls = {
        { type = "choice", key = "layout", label = "Layout", choices = LAYOUTS, default = "Dialog", code = "NineSliceUtil.ApplyLayoutByName(box, %s)" },
        { type = "slider", key = "width", label = "Width", min = 100, max = 700, step = 10, default = 300, code = function(_, values) return ("box:SetSize(%d, %d) -- grown to the layout's minimum"):format(values.width, values.height) end },
        { type = "slider", key = "height", label = "Height", min = 60, max = 340, step = 10, default = 140, code = false },
        { type = "check", key = "background", label = "Own background", default = true, code = "box.Background:SetShown(%s)" },
    },
    apply = function(holder, _, _, values)
        ShowLayout(holder, values)
    end,
})

-- @snippet panels-backdrop
local function CreateFlatBox(parent)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(200, 80)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.12, 0.2, 0.9)
    box:SetBackdropBorderColor(0.4, 0.6, 1, 1)
    return box
end

local function CreateDialogBox(parent)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(200, 80)
    box:SetBackdrop(BACKDROP_DIALOG_32_32)
    return box
end
-- @end

ns.AddExample("panels", {
    id = "panels-backdrop",
    title = "Backdrops",
    description = "Left: a flat box with a 1px border from a white texture. Right: the classic dialog "
        .. "backdrop constant.",
    height = 120,
    code = { "panels-backdrop" },
    create = function(stage)
        local flat = CreateFlatBox(stage)
        flat:SetPoint("CENTER", -110, 0)
        local dialog = CreateDialogBox(stage)
        dialog:SetPoint("CENTER", 110, 0)
        return flat
    end,
    controls = {
        { type = "slider", key = "alpha", label = "Background alpha", min = 0, max = 1, step = 0.05, default = 0.9, code = "box:SetBackdropColor(0.1, 0.12, 0.2, %s)" },
    },
    apply = function(flat, key, value)
        if key == "alpha" then
            flat:SetBackdropColor(0.1, 0.12, 0.2, value)
        end
    end,
})
