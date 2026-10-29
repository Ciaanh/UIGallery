local _, ns = ...

ns.AddComponent({
    id = "anchors",
    family = "basics",
    title = "Anchors (SetPoint)",
    summary = "A region's position and size come from its anchors: each SetPoint ties one of its nine "
        .. "points to a point of another region, with an offset. One anchor plus a size places it; two "
        .. "opposite anchors stretch it, and the size follows the target.",
    clients = "Retail, Forever, Classic",
    keywords = "anchor point SetPoint ClearAllPoints SetAllPoints position layout offset relative",
    whenToUse = {
        "Always ClearAllPoints before re-anchoring: SetPoint adds or replaces one point and keeps the others.",
        "Anchor to the parent or a sibling; a chain of anchors moves together when its root moves.",
        "Two anchors (TOPLEFT + BOTTOMRIGHT, or LEFT + RIGHT) when the region must follow its target's size.",
    },
    api = {
        { "region:SetPoint(point [, relativeTo [, relativePoint]] [, x, y])", "point / relativePoint: TOPLEFT, TOP, TOPRIGHT, LEFT, CENTER, RIGHT, BOTTOMLEFT, BOTTOM, BOTTOMRIGHT. relativeTo defaults to the parent, relativePoint to point. y grows upwards.", "relativeTo = parent" },
        { "region:ClearAllPoints()", "Remove every anchor." },
        { "region:SetAllPoints([relativeTo])", "TOPLEFT and BOTTOMRIGHT on the target: same rectangle.", "the parent" },
        { "region:GetNumPoints() / GetPoint(index) / GetPointByName(point)", "Read anchors back: point, relativeTo, relativePoint, x, y." },
        { "region:AdjustPointsOffset(x, y)", "Shift every anchor's offset." },
        { "frame:SetClampedToScreen(clamped)", "Keep a frame inside the screen when it is moved." },
        { "region:IsAnchoringRestricted()", "True when a protected anchor chain forbids moving it in combat." },
        { "PixelUtil.SetPoint(region, point, relativeTo, relativePoint, x, y)", "SetPoint with offsets rounded to whole physical pixels (see Scale and pixels)." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/SimpleScriptRegionResizingAPIDocumentation.lua",
        "Blizzard_SharedXMLBase/PixelUtil.lua",
    },
})

local POINTS = {
    { "TOPLEFT", "TOPLEFT" }, { "TOP", "TOP" }, { "TOPRIGHT", "TOPRIGHT" },
    { "LEFT", "LEFT" }, { "CENTER", "CENTER" }, { "RIGHT", "RIGHT" },
    { "BOTTOMLEFT", "BOTTOMLEFT" }, { "BOTTOM", "BOTTOM" }, { "BOTTOMRIGHT", "BOTTOMRIGHT" },
}

-- @snippet anchors-point
local function CreateBox(parent, width, height, r, g, b, label)
    local box = CreateFrame("Frame", nil, parent)
    box:SetSize(width, height)
    local fill = box:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetColorTexture(r, g, b, 0.6)
    local text = box:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetText(label)
    return box
end

local function AnchorBox(box, target, point, relativePoint, x, y)
    box:ClearAllPoints()
    box:SetPoint(point, target, relativePoint, x, y)
end
-- @end

local function AnchorCode(_, values)
    return ("box:ClearAllPoints()\nbox:SetPoint(%q, target, %q, %d, %d)"):format(values.point,
        values.relativePoint, values.x, values.y)
end

ns.AddExample("anchors", {
    id = "anchors-point",
    title = "One anchor and a size",
    description = "The orange box has a fixed size and one anchor on the blue target. Pick its point and "
        .. "the target's point: the box's point sits on the target's, then the offset moves it.",
    height = 220,
    code = { "anchors-point" },
    create = function(stage)
        local target = CreateBox(stage, 160, 80, 0.2, 0.4, 0.9, "target")
        target:SetPoint("CENTER")
        local box = CreateBox(stage, 70, 36, 1, 0.55, 0.1, "box")
        box.target = target
        return box
    end,
    controls = {
        { type = "choice", key = "point", label = "Box point", choices = POINTS, default = "TOPLEFT", code = AnchorCode },
        { type = "choice", key = "relativePoint", label = "Target point", choices = POINTS, default = "BOTTOMRIGHT", code = false },
        { type = "slider", key = "x", label = "x offset", min = -40, max = 40, step = 1, default = 0, code = false },
        { type = "slider", key = "y", label = "y offset (up is +)", min = -40, max = 40, step = 1, default = 0, code = false },
    },
    apply = function(box, _, _, values)
        AnchorBox(box, box.target, values.point, values.relativePoint, values.x, values.y)
    end,
})

-- @snippet anchors-stretch
-- Two anchors: the bar's width follows the target, its height is its own.
local function StretchBar(bar, target, inset, spacing)
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", target, "BOTTOMLEFT", inset, -spacing)
    bar:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", -inset, -spacing)
    bar:SetHeight(20)
end
-- @end

ns.AddExample("anchors", {
    id = "anchors-stretch",
    title = "Two anchors: stretch",
    description = "The bar is anchored under both bottom corners of the target, so its width is the "
        .. "target's minus the insets. Change the target's width: the bar follows without a SetWidth.",
    height = 180,
    code = { "anchors-stretch", { "anchors-point", "Helpers" } },
    create = function(stage)
        local target = CreateBox(stage, 300, 70, 0.2, 0.4, 0.9, "target")
        target:SetPoint("TOP", 0, -30)
        local bar = CreateBox(stage, 1, 20, 0.2, 0.8, 0.3, "bar")
        bar.target = target
        return bar
    end,
    controls = {
        { type = "slider", key = "width", label = "Target width", min = 120, max = 600, step = 10, default = 300, code = "target:SetWidth(%s)" },
        { type = "slider", key = "inset", label = "Inset", min = 0, max = 50, step = 1, default = 10, code = function(_, values)
            return ("bar:SetPoint(\"TOPLEFT\", target, \"BOTTOMLEFT\", %d, %d)\nbar:SetPoint(\"TOPRIGHT\", target, \"BOTTOMRIGHT\", %d, %d)"):format(
                values.inset, -values.spacing, -values.inset, -values.spacing)
        end },
        { type = "slider", key = "spacing", label = "Spacing", min = 0, max = 40, step = 1, default = 6, code = false },
    },
    apply = function(bar, key, value, values)
        if key == "width" then
            bar.target:SetWidth(value)
        else
            StretchBar(bar, bar.target, values.inset, values.spacing)
        end
    end,
})
