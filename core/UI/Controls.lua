local _, ns = ...

-- The "playground" under an example's preview: one control per spec, laid out in a grid. Every
-- change calls onChange(key, value); `values` always holds the current value of each control.
--
-- Control specs:
--   { type = "slider", key, label, min, max, step, default [, format(value) -> string] }
--   { type = "check",  key, label, default }
--   { type = "choice", key, label, choices = { { value, text }, ... }, default }
--   { type = "button", key, label }            onChange(key, true) on click
local Controls = {}
ns.Controls = Controls

local CELL_WIDTH, CELL_HEIGHT = 236, 48

local function DefaultFormat(spec)
    if spec.format then
        return spec.format
    end
    if spec.step and spec.step < 1 then
        return function(value) return ("%.2f"):format(value) end
    end
    return function(value) return tostring(math.floor(value + 0.5)) end
end

local function AddLabel(cell, text)
    local label = cell:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 2, 0)
    label:SetText(text)
    return label
end

local builders = {}

function builders.slider(cell, spec, onChange)
    AddLabel(cell, spec.label)
    local slider = CreateFrame("Frame", nil, cell, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("TOPLEFT", 0, -14)
    slider:SetSize(CELL_WIDTH - 50, 26)
    local steps = math.max(1, math.floor((spec.max - spec.min) / spec.step + 0.5))
    local format = DefaultFormat(spec)
    slider:Init(spec.default, spec.min, spec.max, steps, {
        [MinimalSliderWithSteppersMixin.Label.Right] = format,
    })
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        onChange(spec.key, value)
    end, cell)
end

function builders.check(cell, spec, onChange)
    local check = CreateFrame("CheckButton", nil, cell, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 0, -10)
    check:SetSize(26, 26)
    check.Text:SetText(spec.label)
    check.Text:SetFontObject("GameFontHighlightSmall")
    check:SetChecked(spec.default and true or false)
    check:SetScript("OnClick", function(self)
        onChange(spec.key, self:GetChecked() and true or false)
    end)
end

function builders.choice(cell, spec, onChange)
    AddLabel(cell, spec.label)
    local dropdown = CreateFrame("DropdownButton", nil, cell, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", 0, -16)
    dropdown:SetWidth(CELL_WIDTH - 20)
    local selected = spec.default
    dropdown:SetupMenu(function(_, rootDescription)
        for _, choice in ipairs(spec.choices) do
            local value, text = choice[1], choice[2] or tostring(choice[1])
            rootDescription:CreateRadio(text,
                function() return selected == value end,
                function()
                    selected = value
                    onChange(spec.key, value)
                end)
        end
    end)
end

function builders.button(cell, spec, onChange)
    local button = CreateFrame("Button", nil, cell, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", 0, -14)
    button:SetText(spec.label)
    button:SetSize(math.max(100, button:GetFontString():GetStringWidth() + 30), 24)
    button:SetScript("OnClick", function() onChange(spec.key, true) end)
end

-- Returns the container (its height set) and the values table.
function Controls:Create(parent, width, specs, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(width)
    local values = {}
    local perRow = math.max(1, math.floor(width / CELL_WIDTH))
    for i, spec in ipairs(specs) do
        if spec.type ~= "button" then
            values[spec.key] = spec.default
        end
        local cell = CreateFrame("Frame", nil, container)
        cell:SetSize(CELL_WIDTH - 8, CELL_HEIGHT)
        local column, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
        cell:SetPoint("TOPLEFT", column * CELL_WIDTH, -row * CELL_HEIGHT)
        local build = builders[spec.type]
        assert(build, "unknown control type " .. tostring(spec.type))
        build(cell, spec, function(key, value)
            if spec.type ~= "button" then
                values[key] = value
            end
            onChange(key, value, values)
        end)
    end
    local rows = math.ceil(#specs / perRow)
    container:SetHeight(rows * CELL_HEIGHT)
    return container, values
end
