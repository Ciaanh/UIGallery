local _, ns = ...

ns.AddComponent({
    id = "window",
    family = "layout",
    title = "Windows",
    summary = "Blizzard's window templates give a border (a NineSlice layout), a background, a title "
        .. "and often a close button and a round portrait. Moving, resizing and closing with Escape "
        .. "are a few calls on top.",
    clients = "Retail, Forever (same templates; Forever adds gamepad focus frames)",
    keywords = "window frame panel dialog portrait title close move drag resize escape DefaultPanelTemplate PortraitFrameTemplate",
    whenToUse = {
        "A main addon window with an icon: PortraitFrameTemplate (ButtonFrameTemplate adds a button bar and an inset).",
        "A plain titled window: DefaultPanelTemplate, or DefaultPanelFlatTemplate for the flat dark look.",
        "A small dialog: DialogBorderTemplate with a DialogHeaderTemplate title.",
    },
    api = {
        { "frame:SetTitle(text)", "Title text (TitledPanelMixin, on every template here but SimplePanelTemplate and dialogs)." },
        { "frame:SetPortraitToAsset(file) / SetPortraitToUnit(unit) / SetPortraitToClassIcon(class)", "Round portrait of the Portrait and ButtonFrame templates; SetPortraitShown(false) hides it." },
        { "ButtonFrameTemplate_HidePortrait(frame) / _HideButtonBar(frame)", "Trim a ButtonFrameTemplate." },
        { "header:Setup(text)", "DialogHeaderTemplate: sets the text and fits the header's width to it." },
        { "SetMovable(true) + RegisterForDrag(\"LeftButton\") + StartMoving / StopMovingOrSizing", "Drag to move. XML: movable=\"true\"." },
        { "resize:Init(target, minW, minH, maxW, maxH)", "PanelResizeButtonTemplate: the corner grip. The target needs SetResizable(true) (XML resizable=\"true\")." },
        { "resize:SetOnResizeCallback(fn(button, width, height, isActive))", "Called while sizing; SetOnResizeStoppedCallback(fn(target)) at the end." },
        { "tinsert(UISpecialFrames, frameName)", "Escape closes the window. Needs a frame name." },
        { "SetClampedToScreen(true) / SetToplevel(true)", "Stay on screen; come to the front when clicked." },
    },
    refs = {
        "Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml (PortraitFrameTemplate, DefaultPanelTemplate, ButtonFrameTemplate, PanelResizeButtonTemplate)",
        "Blizzard_SharedXML/PortraitFrame.lua (PortraitFrameMixin, TitledPanelMixin)",
        "Blizzard_SharedXML/Shared/Dialog/DialogTemplates.xml (DialogBorderTemplate, DialogHeaderTemplate)",
    },
})

local TEMPLATES = {
    { "PortraitFrameTemplate" }, { "ButtonFrameTemplate" }, { "PortraitFrameFlatTemplate" },
    { "DefaultPanelTemplate" }, { "DefaultPanelFlatTemplate" }, { "SimplePanelTemplate" },
    { "Dialog", "DialogBorderTemplate + DialogHeaderTemplate" },
}

-- @snippet window-templates
local function CreateWindow(parent, template, title)
    local window = CreateFrame("Frame", nil, parent, template)
    window:SetSize(340, 220)
    if window.SetTitle then
        window:SetTitle(title)
    end
    if window.SetPortraitToAsset then
        window:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Book_09")
    end
    return window
end

local function CreateDialog(parent, title)
    local dialog = CreateFrame("Frame", nil, parent)
    dialog:SetSize(340, 160)
    dialog.Border = CreateFrame("Frame", nil, dialog, "DialogBorderTemplate")
    dialog.Header = CreateFrame("Frame", nil, dialog, "DialogHeaderTemplate")
    dialog.Header:Setup(title)
    return dialog
end
-- @end

-- One window per template, built on first use (templates cannot be swapped on a frame).
local function ShowTemplate(holder, template, values)
    for name, window in pairs(holder.windows) do
        window:SetShown(name == template)
    end
    local window = holder.windows[template]
    if not window then
        if template == "Dialog" then
            window = CreateDialog(holder, "Dialog")
        else
            window = CreateWindow(holder, template, template)
        end
        window:SetPoint("CENTER", 0, -10)
        holder.windows[template] = window
    end
    if window.SetPortraitShown then
        window:SetPortraitShown(values.portrait)
    end
end

ns.AddExample("window", {
    id = "window-templates",
    title = "Window templates",
    description = "The same frame with each template. The Portrait, ButtonFrame and Flat portrait "
        .. "templates have a close button (it hides the window: pick another template and back).",
    height = 270,
    code = { "window-templates" },
    create = function(stage)
        local holder = CreateFrame("Frame", nil, stage)
        holder:SetAllPoints()
        holder.windows = {}
        return holder
    end,
    controls = {
        { type = "choice", key = "template", label = "Template", choices = TEMPLATES, default = "PortraitFrameTemplate", code = function(value) if value == "Dialog" then return 'CreateDialog(parent, "Dialog")' end return ('CreateWindow(parent, "%s", "%s")'):format(value, value) end },
        { type = "check", key = "portrait", label = "Portrait", default = true, code = "window:SetPortraitShown(%s)" },
    },
    apply = function(holder, _, _, values)
        ShowTemplate(holder, values.template, values)
    end,
})

-- @snippet window-floating-mixin
UIGalleryFloatingWindowMixin = {}

function UIGalleryFloatingWindowMixin:OnLoad()
    self:SetTitle("Floating window")
    self:RegisterForDrag("LeftButton")
    self.ResizeButton:Init(self, 240, 140, 640, 480)
    self.ResizeButton:SetOnResizeCallback(function(_, width, height)
        self:UpdateBody(width, height)
    end)
    self:UpdateBody(self:GetSize())
end

function UIGalleryFloatingWindowMixin:OnDragStart()
    self:StartMoving()
end

function UIGalleryFloatingWindowMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function UIGalleryFloatingWindowMixin:UpdateBody(width, height)
    self.Body:SetFormattedText("Drag to move, pull the corner grip to resize, Escape or the "
        .. "cross to close.\n\nSize: %d x %d", width, height)
end
-- @end

-- @snippet window-floating-usage
local floatingWindow

local function GetFloatingWindow()
    if not floatingWindow then
        -- A name, so that UISpecialFrames (closed by Escape) can find it.
        floatingWindow = CreateFrame("Frame", "UIGalleryDemoWindow", UIParent, "UIGalleryFloatingWindowTemplate")
        floatingWindow:SetPoint("CENTER")
        tinsert(UISpecialFrames, floatingWindow:GetName())
    end
    return floatingWindow
end
-- @end

ns.AddExample("window", {
    id = "window-floating",
    title = "Movable, resizable window (XML)",
    description = "A real top-level window built from DefaultPanelTemplate, a close button and the "
        .. "corner grip. Open it and move it around.",
    height = 70,
    code = { "window-floating", { "window-floating-mixin", "Mixin" }, { "window-floating-usage", "Usage" } },
    create = function(stage)
        local open = CreateFrame("Button", nil, stage, "UIPanelButtonTemplate")
        open:SetSize(160, 24)
        open:SetText("Open the window")
        open:SetPoint("CENTER")
        open:SetScript("OnClick", function()
            local window = GetFloatingWindow()
            window:SetShown(not window:IsShown())
        end)
        return open
    end,
})
