local _, ns = ...

ns.AddComponent({
    id = "slider",
    family = "controls",
    title = "Slider",
    summary = "Pick a number in a range. MinimalSliderWithSteppersTemplate is the modern one (the "
        .. "Settings panel's): a thin track, back / forward steppers and value labels through "
        .. "formatters. A raw Slider widget gives full control of the look.",
    clients = "Retail, Forever (MinimalSlider); raw Slider everywhere",
    requires = { "minimalSlider" },
    keywords = "range number value stepper MinimalSliderWithSteppersTemplate",
    whenToUse = {
        "A bounded number: scale, alpha, size, volume.",
        "Steps that are few and named read better as a dropdown.",
    },
    api = {
        { "slider:Init(value, min, max, steps, formatters)", "MinimalSlider setup. steps = number of increments between min and max." },
        { "formatters[MinimalSliderWithSteppersMixin.Label.X] = fn(value) -> text", "Labels Left, Right, Top, Min, Max; only those with a formatter show." },
        { "slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, fn(owner, value), owner)", "Value changes (drag, steppers, SetValue). Also OnInteractStart / OnInteractEnd." },
        { "slider:SetValue(value) / slider:SetEnabled(bool)", "Programmatic value; enable state greys the track." },
        { "Raw Slider: SetOrientation, SetMinMaxValues, SetValueStep, SetObeyStepOnDrag, SetThumbTexture", "The underlying widget." },
        { "Raw Slider: SetScript(\"OnValueChanged\", fn(self, value, userInput))", "userInput is true for a drag." },
    },
    refs = {
        "Blizzard_SharedXML/Shared/Slider/MinimalSlider.xml",
        "Blizzard_SharedXML/Shared/Slider/MinimalSlider.lua",
    },
})

-- @snippet slider-minimal
local function CreateScaleSlider(parent, onChange)
    local slider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(260)
    local formatters = {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
            return ("%d%%"):format(value * 100)
        end,
    }
    -- value 1, from 0.5 to 2 in 30 steps of 0.05
    slider:Init(1, 0.5, 2, 30, formatters)
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        onChange(value)
    end, slider)
    return slider
end
-- @end

ns.AddExample("slider", {
    id = "slider-minimal",
    title = "Minimal slider with steppers",
    description = "Drag, click the steppers, or use the mouse wheel over it. The icon scales live.",
    height = 110,
    code = { "slider-minimal" },
    create = function(stage)
        local icon = stage:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
        icon:SetSize(32, 32)
        icon:SetPoint("CENTER", 0, 22)
        local slider = CreateScaleSlider(stage, function(value)
            icon:SetSize(32 * value, 32 * value)
        end)
        slider:SetPoint("BOTTOM", 0, 10)
        return slider
    end,
    controls = {
        { type = "check", key = "enabled", label = "Enabled", default = true },
    },
    apply = function(slider, key, value)
        if key == "enabled" then
            slider:SetEnabled(value)
        end
    end,
})

-- @snippet slider-raw
local function CreateVerticalSlider(parent)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetOrientation("VERTICAL")
    slider:SetSize(16, 100)
    slider:SetMinMaxValues(0, 10)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(1, 1, 1, 0.15)
    track:SetPoint("TOP")
    track:SetPoint("BOTTOM")
    track:SetWidth(4)

    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")

    slider.Value = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slider.Value:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    slider:SetScript("OnValueChanged", function(self, value)
        self.Value:SetText(value)
    end)
    slider:SetValue(3)
    return slider
end
-- @end

ns.AddExample("slider", {
    id = "slider-raw",
    title = "Raw Slider widget",
    description = "No template: orientation, range, step and a thumb texture. Drag the thumb.",
    height = 130,
    code = { "slider-raw" },
    create = function(stage)
        local slider = CreateVerticalSlider(stage)
        slider:SetPoint("CENTER")
        return slider
    end,
})
