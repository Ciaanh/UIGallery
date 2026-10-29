local _, ns = ...

ns.AddComponent({
    id = "fontstring",
    family = "visuals",
    title = "Text (FontString)",
    summary = "FontStrings draw text with a font object (font file, size, flags, colour, shadow, all in "
        .. "one name). Pick a Blizzard font object to match the game's styles; override pieces with "
        .. "SetFont, SetTextColor and SetShadowOffset.",
    clients = "Retail, Forever, Classic",
    keywords = "text label font typography outline shadow wrap justify",
    whenToUse = {
        "Every label. Use the game's font objects so text scales and localises like Blizzard's.",
        "GameFontNormal (gold) for labels, GameFontHighlight (white) for values, GameFontDisable for hints.",
    },
    api = {
        { "parent:CreateFontString(name, layer, fontObject)", "A text region." },
        { "SetText(text) / SetFormattedText(format, ...)", "Content. SetFormattedText avoids building strings." },
        { "SetFontObject(name) / SetFont(file, size, flags)", "Style. SetFontObject resets colour, shadow and justification to the object's: call it before the overrides. flags: \"\", \"OUTLINE\", \"THICKOUTLINE\", \"MONOCHROME\"." },
        { "SetTextColor(r, g, b [, a]) / SetShadowOffset(x, y) / SetShadowColor", "Colour and shadow." },
        { "SetJustifyH(\"LEFT\" | \"CENTER\" | \"RIGHT\") / SetJustifyV(\"TOP\" | \"MIDDLE\" | \"BOTTOM\")", "Alignment inside the region's box." },
        { "SetWidth(w) + SetWordWrap(bool) / SetMaxLines(n)", "Wrapping needs a width; MaxLines truncates with \"...\"." },
        { "GetStringWidth() / GetStringHeight() / GetUnboundedStringWidth()", "Measured size, for layout." },
        { "SetSpacing(px)", "Extra space between lines." },
    },
    refs = {
        "Blizzard_SharedXML/Mainline/SharedFonts.xml",
        "Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua",
    },
})

local FONT_OBJECTS = {
    { "GameFontNormal" }, { "GameFontHighlight" }, { "GameFontDisable" }, { "GameFontGreen" },
    { "GameFontNormalSmall" }, { "GameFontNormalMed3" }, { "GameFontNormalLarge" },
    { "GameFontNormalHuge" }, { "NumberFontNormalLarge" }, { "Fancy24Font" }, { "ChatFontNormal" },
}
local OUTLINES = { { "", "None" }, { "OUTLINE", "Outline" }, { "THICKOUTLINE", "Thick outline" } }
local JUSTIFY = { { "LEFT" }, { "CENTER" }, { "RIGHT" } }

-- @snippet fontstring-basic
local SAMPLE = "The quick brown fox jumps over the lazy dog. Long text wraps inside the width "
    .. "it is given, and the font object decides the look."

local function CreateSampleText(parent)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetWidth(360)
    text:SetText(SAMPLE)
    return text
end

-- SetFontObject copies everything the font object defines (file, size, flags, colour, shadow,
-- justification), so it undoes earlier overrides: set the font object first, then override.
local function ApplyTextStyle(text, style)
    text:SetFontObject(style.fontObject)

    local file, size = text:GetFont()
    text:SetFont(file, size, style.outline)

    text:SetJustifyH(style.justify)
    text:SetWordWrap(style.wrap)
    if style.shadow then
        text:SetShadowColor(0, 0, 0, 1)
        text:SetShadowOffset(1, -1)
    else
        text:SetShadowOffset(0, 0)
    end
end
-- @end

ns.AddExample("fontstring", {
    id = "fontstring-basic",
    title = "Font objects and text settings",
    description = "Every change re-applies the whole style, font object first: SetFontObject resets "
        .. "the outline, colour, shadow and justification the object defines. Without word wrap, text "
        .. "longer than the width ends in \"...\".",
    height = 120,
    code = { "fontstring-basic" },
    create = function(stage)
        local text = CreateSampleText(stage)
        text:SetPoint("CENTER")
        return text
    end,
    controls = {
        { type = "choice", key = "fontObject", label = "Font object", choices = FONT_OBJECTS, default = "GameFontNormal" },
        { type = "choice", key = "outline", label = "Outline", choices = OUTLINES, default = "" },
        { type = "choice", key = "justify", label = "Justify", choices = JUSTIFY, default = "CENTER" },
        { type = "check", key = "wrap", label = "Word wrap", default = true },
        { type = "check", key = "shadow", label = "Shadow", default = true },
    },
    apply = function(text, _, _, values)
        ApplyTextStyle(text, values)
    end,
})
