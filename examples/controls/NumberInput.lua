local _, ns = ...

ns.AddComponent({
    id = "numberinput",
    family = "controls",
    title = "Number input (spinner)",
    summary = "NumericInputSpinnerTemplate is a numeric InputBox between a minus and a plus arrow. "
        .. "Typing, clicking or holding an arrow (it speeds up) all go through SetValue, which clamps "
        .. "to the range and calls back.",
    clients = "Retail, Forever",
    keywords = "number numeric spinner stepper quantity count input NumericInputSpinnerTemplate",
    whenToUse = {
        "An exact whole number in a small range: a quantity, a count, a level.",
        "A value that reads better as a position on a range: a slider (Slider).",
    },
    api = {
        { "CreateFrame(\"EditBox\", nil, parent, \"NumericInputSpinnerTemplate\")", "31x20 box, arrows outside it (23px on each side). letters=\"3\": up to 999 unless SetMaxLetters." },
        { "SetMinMaxValues(min, max)", "Range; the current value is clamped right away." },
        { "SetValue(value) / GetValue()", "Clamped; calls the callback when the value changes." },
        { "SetOnValueChangedCallback(fn(self, value))", "Runs on typing, arrows and SetValue." },
        { "Increment(amount) / Decrement(amount)", "Step by amount (default 1)." },
        { "SetEnabled(bool)", "Box and both arrows." },
        { "IncrementButton / DecrementButton", "The arrow buttons (parentKeys)." },
    },
    refs = {
        "Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml (NumericInputSpinnerTemplate)",
        "Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.lua (NumericInputSpinnerMixin)",
    },
})

-- @snippet numberinput-spinner
local function CreateSpinner(parent, min, max, onChange)
    local spinner = CreateFrame("EditBox", nil, parent, "NumericInputSpinnerTemplate")
    spinner:SetMinMaxValues(min, max)
    spinner:SetOnValueChangedCallback(function(_, value)
        onChange(value)
    end)
    return spinner
end
-- @end

ns.AddExample("numberinput", {
    id = "numberinput-spinner",
    title = "Spinner with a range",
    description = "Type a number, click an arrow or hold it down. Values outside the range snap back "
        .. "to its edge.",
    height = 90,
    code = { "numberinput-spinner" },
    create = function(stage)
        local status = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("BOTTOM", 0, 10)
        local spinner = CreateSpinner(stage, 1, 20, function(value)
            status:SetFormattedText("Value: %d", value)
        end)
        spinner:SetPoint("CENTER", 0, 8)
        spinner:SetValue(5)
        return spinner
    end,
    controls = {
        { type = "slider", key = "max", label = "Maximum", min = 5, max = 999, step = 1, default = 20, code = "spinner:SetMinMaxValues(1, %s)" },
        { type = "check", key = "enabled", label = "Enabled", default = true, code = "spinner:SetEnabled(%s)" },
        { type = "button", key = "increment", label = "Increment(5)" },
    },
    apply = function(spinner, key, value)
        if key == "max" then
            spinner:SetMinMaxValues(1, value)
        elseif key == "enabled" then
            spinner:SetEnabled(value)
        elseif key == "increment" then
            spinner:Increment(5)
        end
    end,
})
