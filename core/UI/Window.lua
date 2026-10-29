local _, ns = ...

-- The gallery window: a search box and the component list on the left (families as headers),
-- the selected component's page on the right in a scroll frame. Built on first Show.
local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 1080, 720
local NAV_WIDTH = 230
local HEADER_HEIGHT, ITEM_HEIGHT = 28, 22

local pages = {}

local function InitHeader(frame, data)
    if not frame.Label then
        frame.Label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        frame.Label:SetPoint("BOTTOMLEFT", 8, 4)
    end
    frame.Label:SetText(data.family.title)
end

local function InitItem(button, data)
    if not button.Label then
        button.Selected = button:CreateTexture(nil, "BACKGROUND")
        button.Selected:SetAllPoints()
        button.Selected:SetColorTexture(1, 0.82, 0, 0.18)
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.08)
        button.Label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        button.Label:SetPoint("LEFT", 20, 0)
        button.Label:SetPoint("RIGHT", -6, 0)
        button.Label:SetJustifyH("LEFT")
        button:SetScript("OnClick", function(self) Window:Select(self.componentId) end)
    end
    local component = data.component
    button.componentId = component.id
    button.Label:SetText(component.title)
    if ns.Capabilities:Missing(component.requires) then
        button.Label:SetTextColor(0.5, 0.5, 0.5)
    else
        button.Label:SetTextColor(1, 1, 1)
    end
    button.Selected:SetShown(component.id == Window.selectedId)
end

function Window:Build()
    local frame = CreateFrame("Frame", "UIGalleryFrame", UIParent, "ButtonFrameTemplate")
    ButtonFrameTemplate_HidePortrait(frame)
    ButtonFrameTemplate_HideButtonBar(frame)
    frame.Inset:Hide()
    frame:SetTitle("UI Gallery")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        UIGalleryDB.window = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)
    local saved = UIGalleryDB.window
    if saved then
        frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
    else
        frame:SetPoint("CENTER")
    end
    -- Escape closes it, like Blizzard's panels.
    table.insert(UISpecialFrames, frame:GetName())
    self.frame = frame

    local navInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    navInset:SetPoint("TOPLEFT", 10, -28)
    navInset:SetPoint("BOTTOMLEFT", 10, 10)
    navInset:SetWidth(NAV_WIDTH)

    local search = CreateFrame("EditBox", nil, navInset, "SearchBoxTemplate")
    search:SetPoint("TOPLEFT", 12, -8)
    search:SetPoint("TOPRIGHT", -8, -8)
    search:SetHeight(20)
    search:HookScript("OnTextChanged", function(self)
        Window:RefreshList(self:GetText())
    end)
    self.search = search

    local scrollBox = CreateFrame("Frame", nil, navInset, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 4, -34)
    scrollBox:SetPoint("BOTTOMRIGHT", -18, 4)
    local scrollBar = CreateFrame("EventFrame", nil, navInset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)
    local view = CreateScrollBoxListLinearView()
    view:SetElementFactory(function(factory, data)
        if data.family then
            factory("Frame", InitHeader)
        else
            factory("Button", InitItem)
        end
    end)
    view:SetElementExtentCalculator(function(_, data)
        return data.family and HEADER_HEIGHT or ITEM_HEIGHT
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
    self.scrollBox = scrollBox

    local pageInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    pageInset:SetPoint("TOPLEFT", navInset, "TOPRIGHT", 6, 0)
    pageInset:SetPoint("BOTTOMRIGHT", -10, 10)

    local scrollFrame = CreateFrame("ScrollFrame", nil, pageInset, "ScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -14)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    self.scrollFrame = scrollFrame
    self.pageWidth = WIDTH - 10 - NAV_WIDTH - 6 - 10 - 16 - 30

    self:RefreshList("")
end

function Window:RefreshList(query)
    local provider = CreateDataProvider()
    for _, family in ipairs(ns.Registry.FAMILIES) do
        local matches = {}
        for _, component in ipairs(family.components) do
            if ns.Registry:Matches(component, query) then
                table.insert(matches, component)
            end
        end
        if #matches > 0 then
            provider:Insert({ family = family })
            for _, component in ipairs(matches) do
                provider:Insert({ component = component })
            end
        end
    end
    self.scrollBox:SetDataProvider(provider)
end

function Window:Select(componentId)
    local component = ns.Registry:Get(componentId) or ns.Registry:First()
    if not component then
        return
    end
    if self.currentPage then
        self.currentPage:Hide()
    end
    local page = pages[component.id]
    if not page then
        page = ns.Page:Create(self.scrollFrame, self.pageWidth, component)
        pages[component.id] = page
    end
    page:Show()
    self.scrollFrame:SetScrollChild(page)
    self.scrollFrame:SetVerticalScroll(0)
    self.currentPage = page
    self.selectedId = component.id
    UIGalleryDB.selected = component.id
    self.scrollBox:ForEachFrame(function(frame, data)
        if frame.Selected then
            frame.Selected:SetShown(data.component and data.component.id == component.id)
        end
    end)
end

function Window:Show(componentId)
    if not self.frame then
        self:Build()
    end
    self.frame:Show()
    self:Select(componentId or self.selectedId or UIGalleryDB.selected)
end

function Window:Toggle()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    else
        self:Show()
    end
end
