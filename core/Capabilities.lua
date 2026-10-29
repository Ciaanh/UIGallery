local _, ns = ...

-- Optional client systems, probed once (Probe, from ADDON_LOADED) and asked afterwards. A
-- component or example lists the ones it needs in `requires`; the page shows it as unsupported
-- on a client that lacks one instead of erroring.
local Capabilities = {}
ns.Capabilities = Capabilities

Capabilities.LABELS = {
    nativeRadial = "the native radial fill (Texture:SetRadialProgressBar*, StatusBar radial render mode)",
    barInterpolation = "StatusBar interpolation (Enum.StatusBarInterpolation)",
    durationObjects = "duration objects (C_DurationUtil, StatusBar:SetTimerDuration)",
    menu = "the Blizzard_Menu dropdowns (MenuUtil, WowStyle1DropdownTemplate)",
    tabSystem = "TabSystemTemplate",
    minimalSlider = "MinimalSliderWithSteppersTemplate",
    scrollBox = "ScrollBox lists (CreateScrollBoxListLinearView)",
}

local has = {}

function Capabilities:Probe()
    -- Enum itself exists on every client; its members are what may be missing.
    has.nativeRadial = Enum.StatusBarRenderMode ~= nil
    has.barInterpolation = Enum.StatusBarInterpolation ~= nil
    has.durationObjects = C_DurationUtil ~= nil and C_DurationUtil.CreateDuration ~= nil
        and Enum.StatusBarTimerDirection ~= nil
    has.menu = MenuUtil ~= nil and MenuUtil.CreateContextMenu ~= nil
    has.tabSystem = TabSystemMixin ~= nil
    has.minimalSlider = MinimalSliderWithSteppersMixin ~= nil
    has.scrollBox = CreateScrollBoxListLinearView ~= nil and ScrollUtil ~= nil
end

function Capabilities:Has(name)
    return has[name] == true
end

-- First capability of `requires` this client lacks, or nil when all are there.
function Capabilities:Missing(requires)
    for _, name in ipairs(requires or {}) do
        if not has[name] then
            return name
        end
    end
    return nil
end
