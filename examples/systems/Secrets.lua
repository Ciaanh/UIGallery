local _, ns = ...

ns.AddComponent({
    id = "secrets",
    family = "systems",
    title = "Secret values",
    summary = "Since 12.0 some game values are secret for addon code (combat data under restrictions, "
        .. "some unit identities): addon code can hold them and hand them to the APIs that accept "
        .. "secrets (FontString:SetText, StatusBar:SetValue...), but most other operations on them are "
        .. "refused. Test whether a value is secret; never compare, format or store one.",
    clients = "Retail, Forever, Classic",
    requires = { "secrets" },
    keywords = "secret value taint restriction issecretvalue secretwrap scrub C_Secrets combat aura cooldown 12.0",
    whenToUse = {
        "Before using any value read from the game in an operator, a format, a table key or saved data.",
        "Display-only paths (a bar's value, a text) can pass a secret straight to an API documented as accepting it (SecretArguments = AllowedWhenTainted).",
    },
    api = {
        { "issecretvalue(value)", "True when the value is secret." },
        { "canaccessvalue(value) / canaccesssecrets()", "Whether the calling function may operate on this value / on secrets at all." },
        { "hasanysecretvalues(...) / issecrettable(t) / canaccesstable(t)", "The same for several values or a table." },
        { "scrubsecretvalues(...)", "The values with every secret one replaced by nil." },
        { "secretwrap(...)", "Makes values secret: a way to test your code's secret paths outside restricted content." },
        { "C_Secrets.HasSecretRestrictions()", "False on a build without restrictions: no API returns secrets then." },
        { "C_Secrets.ShouldAurasBeSecret() / ShouldCooldownsBeSecret()", "Whether aura / cooldown queries currently produce secrets." },
        { "SecretArguments in the API documentation", "AllowedWhenTainted: accepts secrets from addon code. AllowedWhenUntainted: only from Blizzard code." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/FrameScriptDocumentation.lua (issecretvalue, secretwrap...)",
        "Blizzard_APIDocumentationGenerated/SecretPredicateAPIDocumentation.lua (C_Secrets)",
    },
})

-- @snippet secrets-probe
-- The value when this code may use it, else nil: test for secrecy, never the value itself.
local function Plain(value)
    if issecretvalue(value) then
        return nil
    end
    return value
end

-- Runs fn and describes the outcome instead of raising.
local function Try(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        return "error: " .. (tostring(result):gsub("^.-:%d+: ", ""))
    elseif issecretvalue(result) then
        return "ok, the result is secret"
    elseif result == nil then
        return "ok"
    end
    return "ok: " .. tostring(result)
end

local function ProbeSecrets(fontString)
    local wrapped, secret = pcall(secretwrap, 42)
    if not wrapped then
        return { { "secretwrap(42)", "error: " .. tostring(secret) } }
    end
    return {
        { "C_Secrets.HasSecretRestrictions()", Try(C_Secrets.HasSecretRestrictions) },
        { "C_Secrets.ShouldAurasBeSecret()", Try(C_Secrets.ShouldAurasBeSecret) },
        { "C_Secrets.ShouldCooldownsBeSecret()", Try(C_Secrets.ShouldCooldownsBeSecret) },
        { "issecretvalue(secret)", Try(issecretvalue, secret) },
        { "canaccessvalue(secret)", Try(canaccessvalue, secret) },
        { "Plain(secret)", Try(Plain, secret) },
        { "secret + 1", Try(function() return secret + 1 end) },
        { "secret == 42", Try(function() return secret == 42 end) },
        { "tostring(secret)", Try(tostring, secret) },
        { "scrubsecretvalues(secret, 7)", Try(function()
            local a, b = scrubsecretvalues(secret, 7)
            return tostring(a) .. ", " .. tostring(b)
        end) },
        { "fontString:SetText(secret)", Try(fontString.SetText, fontString, secret) },
    }
end
-- @end

ns.AddExample("secrets", {
    id = "secrets-probe",
    title = "What addon code can do with a secret",
    description = "secretwrap(42) makes a secret, then each line tries one operation in a pcall and "
        .. "shows what the client answers. The first three lines are the live C_Secrets state: run "
        .. "again in combat or in an instance to see them change. The value on the right is the "
        .. "FontString that received the secret.",
    height = 200,
    code = { "secrets-probe" },
    create = function(stage)
        local probe = CreateFrame("Frame", nil, stage)
        probe:SetAllPoints()
        probe.Left = probe:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        probe.Left:SetPoint("TOPLEFT", 14, -12)
        probe.Left:SetJustifyH("LEFT")
        probe.Right = probe:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        probe.Right:SetPoint("TOPLEFT", 260, -12)
        probe.Right:SetJustifyH("LEFT")
        probe.Target = probe:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
        probe.Target:SetPoint("TOPRIGHT", -16, -12)
        function probe:Run()
            local left, right = {}, {}
            for _, row in ipairs(ProbeSecrets(self.Target)) do
                left[#left + 1] = row[1]
                right[#right + 1] = row[2]
            end
            self.Left:SetText(table.concat(left, "\n"))
            self.Right:SetText(table.concat(right, "\n"))
        end
        probe:Run()
        return probe
    end,
    controls = {
        { type = "button", key = "run", label = "Run again" },
    },
    apply = function(probe, key)
        if key == "run" then
            probe:Run()
        end
    end,
})
