local _, ns = ...

ns.AddComponent({
    id = "radio",
    family = "controls",
    title = "Radio buttons",
    summary = "UIRadioButtonTemplate is a 16px round CheckButton with a label (its .text field). It has "
        .. "no notion of a group: the code that owns the buttons checks one and unchecks the others.",
    clients = "Retail, Forever, Classic",
    keywords = "radio option choice exclusive group select UIRadioButtonTemplate",
    whenToUse = {
        "Two to five exclusive options that should all stay visible.",
        "More options, or little room: a dropdown with radio entries (Dropdown and menu).",
    },
    api = {
        { "CreateFrame(\"CheckButton\", nil, parent, \"UIRadioButtonTemplate\")", "Round radio, 16x16, label in .text (GameFontNormalSmall), anchored on its right." },
        { "SetChecked(bool) / GetChecked()", "State. A click always toggles it: re-check it in OnClick to keep one selected." },
        { "SetScript(\"OnClick\", fn(self))", "Select this one and uncheck the rest of the group." },
        { "SetHitRectInsets(0, -labelWidth, 0, 0)", "Makes the label clickable." },
    },
    refs = {
        "Blizzard_SharedXML/Shared/Button/CheckButtonTemplates.xml (UIRadioButtonTemplate)",
    },
})

-- @snippet radio-group
-- options: { { value, label }, ... }. onSelect(value) runs on every change.
local function CreateRadioGroup(parent, options, onSelect)
    local group = CreateFrame("Frame", nil, parent)
    group:SetSize(200, #options * 22)
    group.buttons = {}

    function group:Select(value)
        for _, radio in ipairs(self.buttons) do
            radio:SetChecked(radio.value == value)
        end
        self.value = value
        onSelect(value)
    end

    for i, option in ipairs(options) do
        local radio = CreateFrame("CheckButton", nil, group, "UIRadioButtonTemplate")
        radio:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
        radio.value = option[1]
        radio.text:SetText(option[2])
        radio:SetHitRectInsets(0, -radio.text:GetStringWidth() - 6, 0, 0)
        radio:SetScript("OnClick", function(self)
            group:Select(self.value)
        end)
        group.buttons[i] = radio
    end
    return group
end
-- @end

ns.AddExample("radio", {
    id = "radio-group",
    title = "Radio group",
    description = "Three radios behave as one choice: clicking the selected one keeps it selected.",
    height = 100,
    code = { "radio-group" },
    create = function(stage)
        local status = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("LEFT", stage, "CENTER", 40, 0)
        local group = CreateRadioGroup(stage, {
            { "small", "Small" }, { "medium", "Medium" }, { "large", "Large" },
        }, function(value)
            status:SetText("Selected: " .. value)
        end)
        group:SetPoint("RIGHT", stage, "CENTER", -40, 0)
        group:Select("medium")
        return group
    end,
    controls = {
        { type = "check", key = "enabled", label = "Enabled", default = true, code = "radio:SetEnabled(%s) -- each radio" },
    },
    apply = function(group, key, value)
        if key == "enabled" then
            for _, radio in ipairs(group.buttons) do
                radio:SetEnabled(value)
                radio.text:SetFontObject(value and "GameFontNormalSmall" or "GameFontDisableSmall")
            end
        end
    end,
})
