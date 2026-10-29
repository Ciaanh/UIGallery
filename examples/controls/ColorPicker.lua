local _, ns = ...

ns.AddComponent({
    id = "colorpicker",
    family = "controls",
    title = "Color picker",
    summary = "The game has one colour picker window, ColorPickerFrame. Open it with "
        .. "SetupColorPickerAndShow(info): it calls info.swatchFunc while the player drags, "
        .. "opacityFunc for the alpha slider and cancelFunc (with the starting colour) on Cancel.",
    clients = "Retail, Forever (the info table API since 10.2.5)",
    keywords = "color colour picker swatch rgb alpha opacity ColorPickerFrame",
    whenToUse = {
        "Letting the player choose any colour, usually behind a small swatch button.",
        "In the Settings panel, a colour setting row may do it for you: see Blizzard_Settings_API_Guide.md.",
    },
    api = {
        { "ColorPickerFrame:SetupColorPickerAndShow(info)", "info = { r, g, b, hasOpacity, opacity, swatchFunc, opacityFunc, cancelFunc, extraInfo }." },
        { "ColorPickerFrame:GetColorRGB()", "Current colour, inside swatchFunc." },
        { "ColorPickerFrame:GetColorAlpha()", "Current alpha (1 = opaque), inside opacityFunc." },
        { "ColorPickerFrame:GetPreviousValues()", "r, g, b, a it opened with; cancelFunc also receives them as a table { r, g, b, a }." },
        { "ColorPickerFrame:GetExtraInfo()", "Your info.extraInfo, to tell which swatch opened it." },
    },
    refs = {
        "Blizzard_ColorPickerFrame/Mainline/ColorPickerFrame.lua",
        "Blizzard_ColorPickerFrame/Mainline/ColorPickerFrame.xml",
    },
})

-- @snippet colorpicker-swatch
local function CreateColorSwatch(parent, r, g, b, a, onChange)
    local swatch = CreateFrame("Button", nil, parent)
    swatch:SetSize(24, 24)

    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0.8, 0.8, 0.8)
    local color = swatch:CreateTexture(nil, "ARTWORK")
    color:SetPoint("TOPLEFT", 2, -2)
    color:SetPoint("BOTTOMRIGHT", -2, 2)

    function swatch:SetColor(newR, newG, newB, newA)
        r, g, b, a = newR, newG, newB, newA
        color:SetColorTexture(r, g, b, a)
        onChange(r, g, b, a)
    end

    swatch:SetScript("OnClick", function(self)
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            hasOpacity = self.hasOpacity,
            opacity = a,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                self:SetColor(newR, newG, newB, a)
            end,
            opacityFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                self:SetColor(newR, newG, newB, ColorPickerFrame:GetColorAlpha())
            end,
            cancelFunc = function(previous)
                self:SetColor(previous.r, previous.g, previous.b, previous.a or 1)
            end,
        })
    end)

    swatch:SetColor(r, g, b, a)
    return swatch
end
-- @end

ns.AddExample("colorpicker", {
    id = "colorpicker-swatch",
    title = "Swatch button",
    description = "Click the swatch: the bar follows the picker live, and Cancel puts the starting "
        .. "colour back.",
    height = 90,
    code = { "colorpicker-swatch" },
    create = function(stage)
        local bar = stage:CreateTexture(nil, "ARTWORK")
        bar:SetSize(220, 20)
        bar:SetPoint("CENTER", 20, 0)
        local value = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        value:SetPoint("TOP", bar, "BOTTOM", 0, -6)
        local swatch = CreateColorSwatch(stage, 1, 0.6, 0.2, 1, function(r, g, b, a)
            bar:SetColorTexture(r, g, b, a)
            value:SetFormattedText("r %.2f  g %.2f  b %.2f  a %.2f", r, g, b, a)
        end)
        swatch:SetPoint("RIGHT", bar, "LEFT", -12, 0)
        return swatch
    end,
    controls = {
        { type = "check", key = "hasOpacity", label = "Opacity slider (hasOpacity)", default = true, code = "hasOpacity = %s, -- in the SetupColorPickerAndShow table" },
    },
    apply = function(swatch, key, value)
        if key == "hasOpacity" then
            swatch.hasOpacity = value
        end
    end,
})
