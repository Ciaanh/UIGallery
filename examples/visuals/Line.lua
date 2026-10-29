local _, ns = ...

ns.AddComponent({
    id = "line",
    family = "visuals",
    title = "Lines and dividers",
    summary = "A Line is a region drawn between two anchor points, at any angle, with a thickness: "
        .. "graphs, connectors, crosshairs. For a plain separator between sections, Blizzard uses a "
        .. "divider texture instead.",
    clients = "Retail, Forever, Classic (Line); the divider atlas in Retail and Forever",
    keywords = "line divider separator rule stroke graph connector CreateLine",
    whenToUse = {
        "A connector or a graph: CreateLine, one per segment.",
        "A horizontal separator: a texture with the Options_HorizontalDivider atlas (Addons list, Settings).",
        "A 1px border: BackdropTemplate or four textures (Panels and borders).",
    },
    api = {
        { "parent:CreateLine(name, layer)", "A Line region (a Texture that knows its two ends)." },
        { "line:SetStartPoint(point, relativeTo, x, y) / SetEndPoint(...)", "The two ends, anchored like SetPoint: they follow when the anchors move." },
        { "line:SetThickness(px)", "Width of the stroke." },
        { "line:SetColorTexture(r, g, b, a) / SetTexture / SetAtlas", "What the stroke draws: a colour, or an image stretched along it." },
        { "line:SetHitRectThickness(px)", "Mouse area around a line, for hover on graphs." },
        { "texture:SetAtlas(\"Options_HorizontalDivider\", true)", "Blizzard's section divider." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/SimpleLineAPIDocumentation.lua",
        "Blizzard_AddOnList/AddonList.xml (Options_HorizontalDivider)",
    },
})

-- @snippet line-basic
local function CreateConnector(parent, fromRegion, toRegion)
    local line = parent:CreateLine(nil, "ARTWORK")
    line:SetThickness(2)
    line:SetColorTexture(1, 0.82, 0)
    line:SetStartPoint("CENTER", fromRegion)
    line:SetEndPoint("CENTER", toRegion)
    return line
end

local function CreateDivider(parent, width)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetAtlas("Options_HorizontalDivider", true)
    divider:SetWidth(width)
    return divider
end
-- @end

local function CreateDot(parent)
    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetSize(10, 10)
    dot:SetColorTexture(1, 1, 1)
    return dot
end

ns.AddExample("line", {
    id = "line-basic",
    title = "Connector line and divider",
    description = "The line is anchored to the two dots: move the right dot and it follows. Below, "
        .. "the divider atlas.",
    height = 150,
    code = { "line-basic" },
    create = function(stage)
        local holder = CreateFrame("Frame", nil, stage)
        holder:SetAllPoints()
        holder.From = CreateDot(holder)
        holder.From:SetPoint("CENTER", -150, 20)
        holder.To = CreateDot(holder)
        holder.Line = CreateConnector(holder, holder.From, holder.To)
        holder.Divider = CreateDivider(holder, 420)
        holder.Divider:SetPoint("BOTTOM", 0, 20)
        return holder
    end,
    controls = {
        { type = "slider", key = "x", label = "Right dot X", min = -100, max = 200, step = 5, default = 150, code = function(_, values) return ('to:SetPoint("CENTER", %d, %d) -- the line follows its anchor'):format(values.x, values.y) end },
        { type = "slider", key = "y", label = "Right dot Y", min = -40, max = 60, step = 5, default = 50, code = false },
        { type = "slider", key = "thickness", label = "Thickness", min = 1, max = 12, step = 1, default = 2, code = "line:SetThickness(%s)" },
    },
    apply = function(holder, key, value, values)
        if key == "thickness" then
            holder.Line:SetThickness(value)
        else
            holder.To:ClearAllPoints()
            holder.To:SetPoint("CENTER", values.x, values.y)
        end
    end,
})
