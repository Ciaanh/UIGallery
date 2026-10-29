local _, ns = ...

ns.AddComponent({
    id = "scale",
    family = "basics",
    title = "Scale and pixel size",
    summary = "Sizes are in UI units, not pixels: the screen is 768 units high, times the frame's "
        .. "effective scale (its own scale times every parent's, UIParent's included). A 1-unit line "
        .. "can land between two pixels and blur or vanish; round sizes to whole pixels to keep it sharp.",
    clients = "Retail, Forever (SetRoundLayoutToNearestPixel); Classic (the rest)",
    keywords = "scale pixel perfect crisp blurry line border UI scale effective PixelUtil SetScale",
    whenToUse = {
        "SetScale to grow or shrink a whole frame and its children together (a resizable window, a nameplate).",
        "Pixel rounding for thin lines and borders: 1-pixel separators, outlines, grids.",
        "SetIgnoreParentScale for a frame that must keep its size whatever the UI scale.",
    },
    api = {
        { "frame:SetScale(scale) / GetScale()", "The frame's own factor; children inherit it.", "1" },
        { "region:GetEffectiveScale()", "Own scale times every parent's: what a unit is worth on screen." },
        { "frame:SetIgnoreParentScale(ignore)", "Start the product from 1 instead of the parent's." },
        { "GetPhysicalScreenSize()", "Width and height in pixels; GetScreenHeight() is in UI units." },
        { "PixelUtil.GetPixelToUIUnitFactor()", "768 / physical height: one pixel at scale 1, in units." },
        { "PixelUtil.GetNearestPixelSize(size, effectiveScale [, minPixels])", "A size rounded to whole pixels for that scale (minPixels: never below)." },
        { "region:SetRoundLayoutToNearestPixel(enabled)", "The engine rounds the region's size and anchors to pixels; Blizzard prefers it to PixelUtil.SetSize / SetPoint (deprecated)." },
        { "texture:SetSnapToPixelGrid(snap) / SetTexelSnappingBias(bias)", "Texture sampling on the pixel grid: 0 bias and no snap to let a texture move smoothly." },
    },
    refs = {
        "Blizzard_SharedXML/PixelUtil.lua",
        "Blizzard_APIDocumentationGenerated/SimpleScriptRegionResizingAPIDocumentation.lua",
    },
})

-- @snippet scale-lines
local function CreateLineSamples(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(260, 110)

    local function Line(y, label)
        local line = frame:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(1, 1, 1)
        line:SetPoint("TOPLEFT", 90, y)
        line:SetPoint("TOPRIGHT", -10, y)
        local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetPoint("RIGHT", line, "LEFT", -8, 0)
        text:SetText(label)
        return line
    end
    -- 1 UI unit: at most scales that is not a whole number of pixels.
    frame.Raw = Line(-20, "1 unit")
    frame.Raw:SetHeight(1)
    -- Exactly one pixel at the frame's current effective scale: recompute when the scale changes.
    frame.Pixel = Line(-50, "1 pixel")
    -- The engine rounds this one: size and anchors snap to whole pixels.
    frame.Rounded = Line(-80, "rounded")
    frame.Rounded:SetHeight(1)
    frame.Rounded:SetRoundLayoutToNearestPixel(true)
    return frame
end

local function UpdatePixelLine(frame)
    local onePixel = PixelUtil.GetNearestPixelSize(1, frame:GetEffectiveScale(), 1)
    frame.Pixel:SetHeight(onePixel)
end
-- @end

ns.AddExample("scale", {
    id = "scale-lines",
    title = "One unit is not one pixel",
    description = "Three lines meant to be thin. Move the scale: the 1-unit line changes thickness or "
        .. "blurs, the PixelUtil line stays one pixel, the rounded one stays whole pixels. The numbers "
        .. "are this frame's effective scale and the size of a pixel in its units.",
    height = 160,
    code = { "scale-lines" },
    create = function(stage)
        local frame = CreateLineSamples(stage)
        frame:SetPoint("CENTER", 0, 10)
        frame.Info = stage:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        frame.Info:SetPoint("BOTTOM", 0, 8)
        return frame
    end,
    controls = {
        { type = "slider", key = "scale", label = "Scale", min = 0.5, max = 2, step = 0.05, default = 1, code = "frame:SetScale(%s)" },
    },
    apply = function(frame, key, value)
        frame:SetScale(value)
        UpdatePixelLine(frame)
        local scale = frame:GetEffectiveScale()
        frame.Info:SetFormattedText("effective scale %.3f, 1 pixel = %.3f units, screen %dx%d px",
            scale, PixelUtil.GetPixelToUIUnitFactor() / scale, GetPhysicalScreenSize())
    end,
})
