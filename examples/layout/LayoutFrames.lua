local _, ns = ...

ns.AddComponent({
    id = "layoutframes",
    family = "layout",
    title = "Layout frames and frame pools",
    summary = "Let Blizzard place a row, a column or a grid of children instead of chaining SetPoint "
        .. "by hand: HorizontalLayoutFrame / VerticalLayoutFrame stack the children that have a "
        .. "layoutIndex and size themselves to them; AnchorUtil.GridLayout places a list in a grid. A "
        .. "frame pool hands out and takes back the children, so a changing list reuses its frames.",
    clients = "Retail, Forever, Classic",
    keywords = "layout stack row column grid pool reuse HorizontalLayoutFrame VerticalLayoutFrame ResizeLayoutFrame layoutIndex CreateFramePool AnchorUtil",
    whenToUse = {
        "A short list whose size changes (tags, buttons, rewards): a layout frame + a pool. Long lists: a ScrollBox.",
        "ResizeLayoutFrame: a frame that grows to contain whatever children it has, wherever they are anchored.",
        "Never CreateFrame for each refresh: frames are never freed; acquire from a pool and release.",
    },
    api = {
        { "CreateFrame(\"Frame\", nil, parent, \"HorizontalLayoutFrame\")", "Children left to right (VerticalLayoutFrame: top to bottom); also ResizeLayoutFrame, GridLayoutFrame." },
        { "child.layoutIndex = n", "Takes part in the layout, sorted by index. Shown children only (includeAsLayoutChildWhenHidden to keep the space)." },
        { "layout.spacing / topPadding / leftPadding / fixedWidth / expand / childLayoutDirection", "Container keys (XML KeyValues), read on each Layout." },
        { "child.align / expand / topPadding... / ignoreInLayout", "Per child: \"center\", \"right\" or \"bottom\"; stretch; own padding; leave out." },
        { "layout:Layout() / MarkDirty()", "Lay out now / on the next frame (several changes, one layout). Also on OnShow." },
        { "CreateFramePool(frameType, parent, template, resetFunc)", "resetFunc(pool, frame, isNew); default hides it and clears its anchors." },
        { "pool:Acquire() -> frame, isNew / Release(frame) / ReleaseAll()", "Take a frame (build its regions when isNew), give one back, give all back." },
        { "pool:EnumerateActive() / GetNumActive()", "The frames in use." },
        { "AnchorUtil.CreateGridLayout(direction, stride, paddingX, paddingY)", "direction: GridLayoutMixin.Direction.TopLeftToBottomRight, ...Vertical, LeftToRight..." },
        { "AnchorUtil.GridLayout(frames, AnchorUtil.CreateAnchor(point, relativeTo, relativePoint, x, y), layout)", "Anchors the list in that grid (cells the size of the first frame)." },
    },
    refs = {
        "Blizzard_SharedXML/LayoutFrame.xml (every key documented in comments)",
        "Blizzard_SharedXML/LayoutFrame.lua",
        "Blizzard_SharedXMLBase/Pools.lua",
        "Blizzard_SharedXMLBase/AnchorUtil.lua (GridLayout)",
    },
})

-- @snippet layoutframes-stack
local WORDS = { "Tank", "Healer", "Damage", "Mythic+", "Raid", "Voice", "Casual", "Achievements" }

-- Builds a tag's regions the first time the pool hands it out.
local function InitTag(tag)
    tag:SetHeight(22)
    local fill = tag:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetColorTexture(0.2, 0.35, 0.6, 0.8)
    tag.Text = tag:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    tag.Text:SetPoint("CENTER")
end

local function CreateTagStack(parent, template)
    local stack = CreateFrame("Frame", nil, parent, template)
    stack.pool = CreateFramePool("Frame", stack)
    return stack
end

local function ShowTags(stack, count, spacing)
    stack.pool:ReleaseAll()
    stack.spacing = spacing
    for i = 1, count do
        local tag, isNew = stack.pool:Acquire()
        if isNew then
            InitTag(tag)
        end
        tag.Text:SetText(WORDS[i])
        tag:SetWidth(tag.Text:GetStringWidth() + 16)
        tag.layoutIndex = i
        tag:Show()
    end
    stack:Layout()
end
-- @end

ns.AddExample("layoutframes", {
    id = "layoutframes-stack",
    title = "A row or a column of pooled tags",
    description = "Each change releases every tag to the pool and acquires as many as needed: past "
        .. "the first build, no frame is created. The layout frame anchors them by layoutIndex and "
        .. "resizes itself (the dim box behind is its size).",
    height = 230,
    code = { "layoutframes-stack" },
    create = function(stage)
        local stacks = {}
        for key, template in pairs({ horizontal = "HorizontalLayoutFrame", vertical = "VerticalLayoutFrame" }) do
            local stack = CreateTagStack(stage, template)
            stack:SetPoint("TOPLEFT", 16, -16)
            local bounds = stack:CreateTexture(nil, "BACKGROUND", nil, -1)
            bounds:SetAllPoints()
            bounds:SetColorTexture(1, 1, 1, 0.06)
            stacks[key] = stack
        end
        return stacks
    end,
    controls = {
        { type = "choice", key = "template", label = "Template", default = "horizontal", choices = {
            { "horizontal", "HorizontalLayoutFrame" }, { "vertical", "VerticalLayoutFrame" },
        }, code = function(value)
            return ("local stack = CreateTagStack(parent, %q)"):format(value == "horizontal" and "HorizontalLayoutFrame" or "VerticalLayoutFrame")
        end },
        { type = "slider", key = "count", label = "Tags", min = 0, max = #WORDS, step = 1, default = 5, code = function(_, values)
            return ("ShowTags(stack, %d, %d)"):format(values.count, values.spacing)
        end },
        { type = "slider", key = "spacing", label = "Spacing", min = 0, max = 20, step = 1, default = 4, code = false },
    },
    apply = function(stacks, _, _, values)
        for key, stack in pairs(stacks) do
            local active = key == values.template
            stack:SetShown(active)
            ShowTags(stack, active and values.count or 0, values.spacing)
        end
    end,
})

local DIRECTIONS = {
    { "TopLeftToBottomRight", "TopLeftToBottomRight" },
    { "TopLeftToBottomRightVertical", "TopLeftToBottomRightVertical" },
    { "TopRightToBottomLeft", "TopRightToBottomLeft" },
}

-- @snippet layoutframes-grid
local function CreateNumberedSquares(parent, count)
    local pool = CreateFramePool("Frame", parent)
    local squares = {}
    for i = 1, count do
        local square, isNew = pool:Acquire()
        if isNew then
            square:SetSize(36, 36)
            local fill = square:CreateTexture(nil, "BACKGROUND")
            fill:SetAllPoints()
            fill:SetColorTexture(0.25, 0.5, 0.3, 0.9)
            square.Text = square:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            square.Text:SetPoint("CENTER")
        end
        square.Text:SetText(i)
        square:Show()
        squares[i] = square
    end
    return squares
end

local function ArrangeInGrid(squares, parent, directionName, stride, padding)
    local direction = GridLayoutMixin.Direction[directionName]
    local layout = AnchorUtil.CreateGridLayout(direction, stride, padding, padding)
    local point = direction.x > 0 and "TOPLEFT" or "TOPRIGHT"
    local anchor = AnchorUtil.CreateAnchor(point, parent, point, 0, 0)
    AnchorUtil.GridLayout(squares, anchor, layout)
end
-- @end

ns.AddExample("layoutframes", {
    id = "layoutframes-grid",
    title = "Grid layout (AnchorUtil)",
    description = "Twelve squares placed by AnchorUtil.GridLayout: stride is the row length (the "
        .. "column length in a Vertical direction), padding the gap.",
    height = 200,
    code = { "layoutframes-grid" },
    create = function(stage)
        local holder = CreateFrame("Frame", nil, stage)
        holder:SetPoint("TOPLEFT", 16, -16)
        holder:SetPoint("BOTTOMRIGHT", -16, 16)
        holder.squares = CreateNumberedSquares(holder, 12)
        return holder
    end,
    controls = {
        { type = "slider", key = "stride", label = "Stride", min = 1, max = 12, step = 1, default = 4, code = function(_, values)
            return ("ArrangeInGrid(squares, parent, %q, %d, %d)"):format(values.direction, values.stride, values.padding)
        end },
        { type = "slider", key = "padding", label = "Padding", min = 0, max = 16, step = 1, default = 4, code = false },
        { type = "choice", key = "direction", label = "Direction", choices = DIRECTIONS, default = "TopLeftToBottomRight", code = false },
    },
    apply = function(holder, _, _, values)
        ArrangeInGrid(holder.squares, holder, values.direction, values.stride, values.padding)
    end,
})
