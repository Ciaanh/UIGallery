local _, ns = ...

ns.AddComponent({
    id = "checkbox",
    family = "controls",
    title = "Checkbox",
    summary = "A CheckButton toggles a boolean. UICheckButtonTemplate gives the classic gold box with a "
        .. "label (its Text field); the Settings panel's checkboxes come from the Settings API instead.",
    clients = "Retail, Forever, Classic",
    keywords = "check toggle boolean switch option UICheckButtonTemplate",
    whenToUse = {
        "An on/off option inside your own panel.",
        "For addon options, prefer the Settings API (Settings.CreateCheckbox): see Blizzard_Settings_API_Guide.md.",
    },
    api = {
        { "CreateFrame(\"CheckButton\", nil, parent, \"UICheckButtonTemplate\")", "Gold checkbox, 32x32, label in .Text (GameFontNormalSmall)." },
        { "SetChecked(bool) / GetChecked()", "State. GetChecked returns true or false." },
        { "SetScript(\"OnClick\", fn(self))", "Fires after the state flipped: read GetChecked() inside." },
        { "SetEnabled(bool)", "Greys out the box; set the label colour yourself (GameFontDisableSmall)." },
        { "SetHitRectInsets(left, right, top, bottom)", "Negative right inset makes the label clickable too." },
    },
    refs = {
        "Blizzard_SharedXML/Shared/Button/CheckButtonTemplates.xml",
        "Blizzard_Settings_Shared/Blizzard_SettingControls.xml (SettingsCheckboxTemplate)",
    },
})

-- @snippet checkbox-basic
local function CreateLabeledCheckbox(parent, label, onToggle)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check.Text:SetText(label)
    -- Let a click on the label toggle the box as well.
    check:SetHitRectInsets(0, -check.Text:GetStringWidth() - 4, 0, 0)
    check:SetScript("OnClick", function(self)
        onToggle(self:GetChecked())
    end)
    return check
end
-- @end

ns.AddExample("checkbox", {
    id = "checkbox-basic",
    title = "Labeled checkbox",
    description = "Clicking the box or its label flips the state and calls back with the new value.",
    height = 80,
    code = { "checkbox-basic" },
    create = function(stage)
        local status = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("BOTTOM", 0, 10)
        local check = CreateLabeledCheckbox(stage, "Show nameplates", function(checked)
            status:SetText(checked and "Checked" or "Unchecked")
        end)
        check:SetPoint("CENTER", -60, 6)
        return check
    end,
    controls = {
        { type = "check", key = "enabled", label = "Enabled", default = true, code = function(value) return ('check:SetEnabled(%s)\ncheck.Text:SetFontObject("%s")'):format(tostring(value), value and "GameFontNormalSmall" or "GameFontDisableSmall") end },
    },
    apply = function(check, key, value)
        if key == "enabled" then
            check:SetEnabled(value)
            check.Text:SetFontObject(value and "GameFontNormalSmall" or "GameFontDisableSmall")
        end
    end,
})
