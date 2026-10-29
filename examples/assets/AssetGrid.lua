local _, ns = ...

-- The shell shared by the asset browsers (atlases, icons, fonts): a debounced search box over a
-- ScrollBox grid, and under it the selected entry with the code to use it. Not a component of its
-- own: each browser shows the grid's snippet as its "Grid" tab.

-- @snippet asset-grid
-- opts: width, height, cellWidth, cellHeight,
--       filter(query) -> entries   (query is trimmed and lower case)
--       initCell(cell, entry)      draws one entry; cells are recycled, so set everything
--       label(entry) -> text       the tooltip
--       onSelect(entry)            a click
local function CreateAssetGrid(parent, opts)
    local browser = CreateFrame("Frame", nil, parent)
    browser:SetSize(opts.width, opts.height)

    local search = CreateFrame("EditBox", nil, browser, "SearchBoxTemplate")
    search:SetSize(240, 20)
    search:SetPoint("TOPLEFT", 6, 0)

    local count = browser:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    count:SetPoint("LEFT", search, "RIGHT", 12, 0)

    local grid = CreateFrame("Frame", nil, browser, "WowScrollBoxList")
    grid:SetPoint("TOPLEFT", 0, -28)
    grid:SetPoint("BOTTOMRIGHT", -16, 0)
    local scrollBar = CreateFrame("EventFrame", nil, browser, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", grid, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", grid, "BOTTOMRIGHT", 6, 0)

    -- As many columns as fit; a grid view sizes its cells with SetElementSize (not Extent).
    local spacing = 4
    local columns = math.max(1, math.floor((opts.width - 16 + spacing) / (opts.cellWidth + spacing)))
    local view = CreateScrollBoxListGridView(columns, 0, 0, 0, 0, spacing, spacing)
    view:SetElementSize(opts.cellWidth, opts.cellHeight)
    view:SetElementInitializer("Button", function(cell, entry)
        if not cell.Highlight then
            cell.Background = cell:CreateTexture(nil, "BACKGROUND")
            cell.Background:SetAllPoints()
            cell.Background:SetColorTexture(1, 1, 1, 0.04)
            cell.Highlight = cell:CreateTexture(nil, "HIGHLIGHT")
            cell.Highlight:SetAllPoints()
            cell.Highlight:SetColorTexture(1, 1, 1, 0.15)
            cell:SetClipsChildren(true)
            cell:SetScript("OnClick", function(self) opts.onSelect(self.entry) end)
            cell:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip_SetTitle(GameTooltip, opts.label(self.entry))
                GameTooltip:Show()
            end)
            cell:SetScript("OnLeave", GameTooltip_Hide)
        end
        cell.entry = entry
        opts.initCell(cell, entry)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(grid, scrollBar, view)

    local function Refresh()
        local entries = opts.filter(strtrim(search:GetText()):lower())
        grid:SetDataProvider(CreateDataProvider(entries))
        count:SetFormattedText("%d shown", #entries)
    end

    -- Filter once typing pauses: rebuilding a list of thousands per keystroke stutters.
    local timer
    search:HookScript("OnTextChanged", function()
        if timer then
            timer:Cancel()
        end
        timer = C_Timer.NewTimer(0.25, Refresh)
    end)
    Refresh()
    return browser
end
-- @end

-- Gallery glue: the browser on top of the stage, the selection under it.
local DETAIL_HEIGHT = 84

local function CreateDetail(stage, width)
    local detail = CreateFrame("Frame", nil, stage)
    detail:SetSize(width, DETAIL_HEIGHT)

    local line = detail:CreateTexture(nil, "BACKGROUND")
    line:SetColorTexture(1, 1, 1, 0.1)
    line:SetPoint("TOPLEFT")
    line:SetPoint("TOPRIGHT")
    line:SetHeight(1)

    -- Each browser draws its preview into this square (a texture, or a FontString for fonts).
    detail.Preview = CreateFrame("Frame", nil, detail)
    detail.Preview:SetSize(64, 64)
    detail.Preview:SetPoint("TOPLEFT", 4, -10)
    detail.Preview:SetClipsChildren(true)

    detail.Title = detail:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    detail.Title:SetPoint("TOPLEFT", detail.Preview, "TOPRIGHT", 12, 0)
    detail.Title:SetPoint("RIGHT", -4, 0)
    detail.Title:SetJustifyH("LEFT")
    detail.Title:SetText("Click an entry")

    detail.Info = detail:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    detail.Info:SetPoint("TOPLEFT", detail.Title, "BOTTOMLEFT", 0, -3)
    detail.Info:SetPoint("RIGHT", -4, 0)
    detail.Info:SetJustifyH("LEFT")

    detail.Code = ns.CodeView:CreateEditBox(detail, width - 84)
    detail.Code:SetPoint("TOPLEFT", detail.Info, "BOTTOMLEFT", 0, -5)

    function detail:Select(title, info, code)
        self.Title:SetText(title)
        self.Info:SetText(info or "")
        self.Code:SetCode(code)
    end
    return detail
end

-- Builds browser + detail in a card's stage. spec: the CreateAssetGrid opts minus width / height /
-- onSelect, plus select(detail, entry) to fill the detail.
function ns.CreateAssetBrowser(stage, spec)
    local width = stage:GetWidth() - 16
    local detail = CreateDetail(stage, width)
    detail:SetPoint("BOTTOMLEFT", 8, 4)

    local opts = {}
    for k, v in pairs(spec) do
        opts[k] = v
    end
    opts.width = width
    opts.height = stage:GetHeight() - DETAIL_HEIGHT - 16
    opts.onSelect = function(entry) spec.select(detail, entry) end
    local browser = CreateAssetGrid(stage, opts)
    browser:SetPoint("TOPLEFT", 8, -8)
    browser.Detail = detail
    return browser
end
