local _, ns = ...

-- One example: live preview ("stage"), title and description, the playground controls, and the
-- code behind a toggle. The example's create / apply run through ns.SafeCall: an error shows in
-- the stage (and in BugSack) instead of breaking the page.
local Card = {}
ns.Card = Card

local PADDING = 12
local GAP = 8
local DEFAULT_STAGE_HEIGHT = 120

local function SetFlatBackdrop(frame, r, g, b, a, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(r, g, b, a)
    frame:SetBackdropBorderColor(border, border, border, 1)
end

local function StageMessage(stage, text, r, g, b)
    local message = stage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    message:SetPoint("LEFT", 16, 0)
    message:SetPoint("RIGHT", -16, 0)
    message:SetJustifyH("CENTER")
    message:SetWordWrap(true)
    message:SetTextColor(r, g, b)
    message:SetText(text)
end

local function Apply(card, key, value, values)
    local example = card.example
    if card.widget and example.apply then
        local ok, err = ns.SafeCall(example.apply, card.widget, key, value, values)
        if not ok then
            card.Status:SetText("apply(" .. tostring(key) .. ") failed: " .. tostring(err))
        end
    end
end

function Card:Create(parent, width, example, onResize)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    SetFlatBackdrop(card, 0.1, 0.1, 0.12, 0.9, 0.25)
    card:SetWidth(width)
    card.example = example
    card.onResize = onResize

    local inner = width - 2 * PADDING

    local stage = CreateFrame("Frame", nil, card, "BackdropTemplate")
    SetFlatBackdrop(stage, 0.02, 0.02, 0.03, 0.9, 0.18)
    stage:SetPoint("TOPLEFT", PADDING, -PADDING)
    stage:SetSize(inner, example.height or DEFAULT_STAGE_HEIGHT)
    card.Stage = stage

    local title = card:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -GAP)
    title:SetText(example.title)

    local description = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    description:SetWidth(inner)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)
    description:SetText(example.description or "")
    card.Description = description

    local status = card:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
    status:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -2)
    status:SetWidth(inner)
    status:SetJustifyH("LEFT")
    card.Status = status

    local missing = ns.Capabilities:Missing(example.requires)
    if missing then
        StageMessage(stage, "Not available on this client: needs " .. ns.Capabilities.LABELS[missing] .. ".",
            0.6, 0.6, 0.6)
    else
        local ok, widget = ns.SafeCall(example.create, stage)
        if ok then
            card.widget = widget
        else
            StageMessage(stage, "create() failed:\n" .. tostring(widget), 1, 0.3, 0.3)
        end
    end

    if card.widget and #example.controls > 0 then
        local controls, values = ns.Controls:Create(card, inner, example.controls, function(key, value, all)
            Apply(card, key, value, all)
        end)
        card.Controls = controls
        for _, spec in ipairs(example.controls) do
            if spec.type ~= "button" then
                Apply(card, spec.key, values[spec.key], values)
            end
        end
    end

    if #example.code > 0 then
        local toggle = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        toggle:SetText("Show code")
        toggle:SetSize(110, 22)
        toggle:SetScript("OnClick", function()
            if not card.Code then
                card.Code = ns.CodeView:Create(card, inner, example.code, function() Card.Layout(card) end)
            else
                card.Code:SetShown(not card.Code:IsShown())
            end
            toggle:SetText(card.Code:IsShown() and "Hide code" or "Show code")
            Card.Layout(card)
        end)
        card.Toggle = toggle
    end

    Card.Layout(card)
    return card
end

-- Stacks the optional parts under the description and sets the card's height.
function Card.Layout(card)
    local y = PADDING + card.Stage:GetHeight() + GAP + 20 + 4 + card.Description:GetStringHeight()
    if card.Status:GetText() and card.Status:GetText() ~= "" then
        y = y + 2 + card.Status:GetStringHeight()
    end
    if card.Controls then
        y = y + GAP + 4
        card.Controls:ClearAllPoints()
        card.Controls:SetPoint("TOPLEFT", PADDING, -y)
        y = y + card.Controls:GetHeight()
    end
    if card.Toggle then
        y = y + GAP
        card.Toggle:ClearAllPoints()
        card.Toggle:SetPoint("TOPLEFT", PADDING, -y)
        y = y + card.Toggle:GetHeight()
    end
    if card.Code and card.Code:IsShown() then
        y = y + GAP
        card.Code:ClearAllPoints()
        card.Code:SetPoint("TOPLEFT", PADDING, -y)
        y = y + card.Code:GetHeight()
    end
    card:SetHeight(y + PADDING)
    if card.onResize then
        card.onResize()
    end
end
