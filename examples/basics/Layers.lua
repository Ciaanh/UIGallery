local _, ns = ...

ns.AddComponent({
    id = "layers",
    family = "basics",
    title = "Strata, frame levels, draw layers",
    summary = "What draws on top, from coarse to fine: the frame strata (BACKGROUND to TOOLTIP), then "
        .. "the frame level inside a strata, then, inside one frame, the draw layer of each texture or "
        .. "FontString (BACKGROUND to HIGHLIGHT) and its sublevel (-8 to 7).",
    clients = "Retail, Forever, Classic",
    keywords = "strata level layer z-order order overlap SetFrameStrata SetFrameLevel SetDrawLayer sublevel toplevel",
    whenToUse = {
        "Strata: a whole window above others (DIALOG for a popup, TOOLTIP for a tooltip). A child inherits its parent's.",
        "Frame level: order between frames of one strata. A child is created above its parent (level + 1).",
        "Draw layer: order between the regions of one frame; a child frame always covers its parent's regions.",
        "SetToplevel(true) on a window raises it above its siblings when clicked.",
    },
    api = {
        { "frame:SetFrameStrata(strata)", "BACKGROUND, LOW, MEDIUM, HIGH, DIALOG, FULLSCREEN, FULLSCREEN_DIALOG, TOOLTIP. Children follow unless they set their own.", "the parent's (MEDIUM for UIParent)" },
        { "frame:SetFrameLevel(level) / GetFrameLevel()", "Order inside the strata; children are moved along with their parent.", "parent level + 1" },
        { "frame:SetFixedFrameLevel(fixed)", "Keep this level when the parent's changes." },
        { "frame:SetToplevel(toplevel) / Raise() / Lower()", "Raise on click / by hand, inside the strata." },
        { "region:SetDrawLayer(layer [, sublevel])", "BACKGROUND, BORDER, ARTWORK, OVERLAY, HIGHLIGHT (shown only while the mouse is over a Button / mouse-enabled frame). Sublevel -8 to 7.", "ARTWORK, 0" },
        { "frame:CreateTexture(name, layer, template, sublevel)", "The layer at creation." },
        { "XML: <Layers><Layer level=\"OVERLAY\" textureSubLevel=\"1\">", "The same, declared." },
        { "frame:SetFlattensRenderLayers(flatten)", "Draw the frame and its children as one layer (needed for some alpha effects)." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua",
        "Blizzard_APIDocumentationGenerated/SimpleRegionAPIDocumentation.lua",
        "Blizzard_SharedXML/UI.xsd (FRAMESTRATA, DRAWLAYER)",
    },
})

-- @snippet layers-frames
local function CreateCard(parent, r, g, b, label)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(150, 90)
    local fill = card:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetColorTexture(r, g, b, 0.95)
    card.Label = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    card.Label:SetPoint("TOPLEFT", 8, -8)
    card.Label:SetText(label)
    return card
end

-- Frame levels are absolute: place a frame relative to its parent's level.
local function SetLevelAbove(frame, parent, offset)
    frame:SetFrameLevel(parent:GetFrameLevel() + offset)
end
-- @end

ns.AddExample("layers", {
    id = "layers-frames",
    title = "Frame strata and level",
    description = "Blue sits at the stage's level + 5. Raise red's level past 5 and it covers blue; "
        .. "switch red to DIALOG and it covers blue at any level, and also the gallery window's "
        .. "neighbours (the gallery is HIGH). Lower strata are not offered: red would vanish behind "
        .. "the gallery's own background.",
    height = 170,
    code = { "layers-frames" },
    create = function(stage)
        local blue = CreateCard(stage, 0.15, 0.35, 0.85, "blue: level +5")
        blue:SetPoint("CENTER", 45, -15)
        SetLevelAbove(blue, stage, 5)
        local red = CreateCard(stage, 0.85, 0.2, 0.15, "red")
        red:SetPoint("CENTER", -45, 15)
        red.stage = stage
        return red
    end,
    controls = {
        { type = "choice", key = "strata", label = "Red strata", choices = { { "HIGH", "HIGH (gallery)" }, { "DIALOG", "DIALOG" } }, default = "HIGH", code = "red:SetFrameStrata(%s)" },
        { type = "slider", key = "level", label = "Red level (stage + n)", min = 1, max = 10, step = 1, default = 2, code = "red:SetFrameLevel(stage:GetFrameLevel() + %s)" },
    },
    apply = function(red, key, value, values)
        if key == "strata" then
            red:SetFrameStrata(value)
        end
        -- Set the level again after a strata change rather than rely on what it keeps.
        SetLevelAbove(red, red.stage, values.level)
        red.Label:SetFormattedText("red: %s, level +%d", values.strata, values.level)
    end,
})

local LAYERS = {
    { "BACKGROUND", "BACKGROUND" }, { "BORDER", "BORDER" }, { "ARTWORK", "ARTWORK" },
    { "OVERLAY", "OVERLAY" }, { "HIGHLIGHT", "HIGHLIGHT (hover)" },
}

-- @snippet layers-draw
local function CreateLayeredSquares(parent)
    -- Mouse enabled, so the HIGHLIGHT layer shows while the cursor is over the frame.
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, 120)
    frame:EnableMouse(true)

    local function Square(layer, sublevel, r, g, b, x, y)
        local square = frame:CreateTexture(nil, layer, nil, sublevel)
        square:SetSize(90, 70)
        square:SetPoint("CENTER", x, y)
        square:SetColorTexture(r, g, b)
        return square
    end
    frame.Green = Square("ARTWORK", 0, 0.2, 0.75, 0.3, 0, 0)
    frame.Red = Square("BORDER", 0, 0.85, 0.2, 0.15, -40, 20)
    return frame
end
-- @end

ns.AddExample("layers", {
    id = "layers-draw",
    title = "Draw layers inside one frame",
    description = "Green is ARTWORK, sublevel 0. Move red's layer and sublevel: same layer, the higher "
        .. "sublevel wins; same both, the order is undefined. HIGHLIGHT shows only while the cursor is "
        .. "over the frame.",
    height = 150,
    code = { "layers-draw" },
    create = function(stage)
        local frame = CreateLayeredSquares(stage)
        frame:SetPoint("CENTER")
        return frame
    end,
    controls = {
        { type = "choice", key = "layer", label = "Red layer", choices = LAYERS, default = "BORDER", code = function(_, values)
            return ("red:SetDrawLayer(%q, %d)"):format(values.layer, values.sublevel)
        end },
        { type = "slider", key = "sublevel", label = "Red sublevel", min = -8, max = 7, step = 1, default = 0, code = false },
    },
    apply = function(frame, _, _, values)
        frame.Red:SetDrawLayer(values.layer, values.sublevel)
    end,
})
