local _, ns = ...

ns.AddComponent({
    id = "animation",
    family = "visuals",
    title = "Animations",
    summary = "AnimationGroups animate regions without OnUpdate: Alpha, Scale, Rotation, Translation, "
        .. "FlipBook (sprite sheets), and in 12.1 RadialProgress. Animations of the same order play "
        .. "together, higher orders after; the group can loop or bounce.",
    clients = "Retail, Forever, Classic (RadialProgress: Retail 12.1+, Forever)",
    keywords = "animate fade pulse spin bounce flipbook sprite smoothing loop",
    whenToUse = {
        "Feedback: a fade-in, a pulse on change, a spinning loader, a sprite effect.",
        "Value-driven motion (a bar easing to a value): StatusBar interpolation is simpler.",
    },
    api = {
        { "local group = region:CreateAnimationGroup()", "Groups live on a frame or a region." },
        { "group:CreateAnimation(type)", "\"Alpha\", \"Scale\", \"Rotation\", \"Translation\", \"FlipBook\", \"Path\", \"RadialProgress\"..." },
        { "anim:SetDuration(s) / SetStartDelay(s) / SetOrder(n) / SetSmoothing(\"IN\" | \"OUT\" | \"IN_OUT\" | \"NONE\")", "Timing." },
        { "Alpha: SetFromAlpha / SetToAlpha; Scale: SetScaleFrom / SetScaleTo; Rotation: SetDegrees; Translation: SetOffset", "Per type." },
        { "anim:SetTarget(region) / SetChildKey(key)", "Animate another region than the group's owner." },
        { "group:SetLooping(\"NONE\" | \"REPEAT\" | \"BOUNCE\")", "Looping.", "NONE" },
        { "group:Play() / Stop() / Pause() / Restart() / IsPlaying()", "Control." },
        { "group:SetToFinalAlpha(bool)", "Keep the final alpha after the group ends." },
        { "group:SetScript(\"OnFinished\", fn) / OnLoop / OnPlay", "Events." },
        { "FlipBook: SetFlipBookRows / Columns / Frames / FrameWidth / FrameHeight", "Sprite sheet layout; the region shows one cell at a time." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/SimpleAnimGroupAPIDocumentation.lua",
        "Blizzard_APIDocumentationGenerated/SimpleAnimAPIDocumentation.lua",
        "Blizzard_ActionBar/Shared/ActionButtonSpellAlerts.xml (proc flipbooks)",
    },
})

local KINDS = { { "pulse", "Pulse (Scale)" }, { "fade", "Fade (Alpha)" }, { "spin", "Spin (Rotation)" }, { "slide", "Slide (Translation)" } }
local LOOPING = { { "NONE" }, { "REPEAT" }, { "BOUNCE" } }
local SMOOTHING = { { "NONE" }, { "IN" }, { "OUT" }, { "IN_OUT" } }

-- @snippet animation-basic
local function CreateAnimatedIcon(parent)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(56, 56)
    icon:SetTexture("Interface\\Icons\\Spell_Fire_FlameBolt")
    icon.group = icon:CreateAnimationGroup()
    return icon
end

-- Rebuilds the group with one animation of the given kind.
local function SetAnimation(icon, kind, duration, looping, smoothing)
    local group = icon.group
    group:Stop()
    group:RemoveAnimations()

    local anim
    if kind == "pulse" then
        anim = group:CreateAnimation("Scale")
        anim:SetScaleFrom(1, 1)
        anim:SetScaleTo(1.4, 1.4)
    elseif kind == "fade" then
        anim = group:CreateAnimation("Alpha")
        anim:SetFromAlpha(1)
        anim:SetToAlpha(0)
    elseif kind == "spin" then
        anim = group:CreateAnimation("Rotation")
        anim:SetDegrees(-360)
    else
        anim = group:CreateAnimation("Translation")
        anim:SetOffset(80, 0)
    end
    anim:SetDuration(duration)
    anim:SetSmoothing(smoothing)
    group:SetLooping(looping)
    group:Play()
end
-- @end

ns.AddExample("animation", {
    id = "animation-basic",
    title = "Basic animation types",
    description = "Pick a type, a duration, the looping and the smoothing; the group is rebuilt and "
        .. "played on every change. BOUNCE plays forward then backward.",
    height = 130,
    code = { "animation-basic" },
    create = function(stage)
        local icon = CreateAnimatedIcon(stage)
        icon:SetPoint("CENTER", -40, 0)
        return icon
    end,
    controls = {
        { type = "choice", key = "kind", label = "Animation", choices = KINDS, default = "pulse", code = function(_, v) return ('SetAnimation(icon, "%s", %g, "%s", "%s")'):format(v.kind, v.duration, v.looping, v.smoothing) end },
        { type = "slider", key = "duration", label = "Duration (s)", min = 0.1, max = 3, step = 0.1, default = 0.6, code = false },
        { type = "choice", key = "looping", label = "Looping", choices = LOOPING, default = "BOUNCE", code = false },
        { type = "choice", key = "smoothing", label = "Smoothing", choices = SMOOTHING, default = "IN_OUT", code = false },
        { type = "button", key = "play", label = "Replay" },
    },
    apply = function(icon, _, _, values)
        SetAnimation(icon, values.kind, values.duration, values.looping, values.smoothing)
    end,
})

-- @snippet animation-flipbook-usage
local function CreateProcLoop(parent)
    -- UIGalleryFlipbookTemplate is declared in the XML tab; its OnShow plays the loop.
    return CreateFrame("Frame", nil, parent, "UIGalleryFlipbookTemplate")
end
-- @end

ns.AddExample("animation", {
    id = "animation-flipbook",
    title = "FlipBook (sprite sheet, XML)",
    description = "The action bar's proc glow: an atlas holding a 6 x 5 grid of 30 frames, played by a "
        .. "FlipBook animation that loops. Declared entirely in XML, started by the frame's OnShow script.",
    height = 130,
    code = { "animation-flipbook", "animation-flipbook-usage" },
    create = function(stage)
        local loop = CreateProcLoop(stage)
        loop:SetPoint("CENTER")
        return loop
    end,
    controls = {
        { type = "slider", key = "duration", label = "Cycle (s)", min = 0.2, max = 3, step = 0.1, default = 1, code = function(value) return ("loop.Flipbook.Anim.Flip:SetDuration(%g)\nloop.Flipbook.Anim:Restart()"):format(value) end },
    },
    apply = function(loop, key, value)
        if key == "duration" then
            loop.Flipbook.Anim.Flip:SetDuration(value)
            loop.Flipbook.Anim:Restart()
        end
    end,
})
