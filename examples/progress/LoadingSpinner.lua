local _, ns = ...

ns.AddComponent({
    id = "loadingspinner",
    family = "progress",
    title = "Loading spinner",
    summary = "Two ready-made \"busy\" indicators that spin while shown: LoadingSpinnerTemplate (48px, "
        .. "gold, the streaming / loading look) and SpinnerTemplate (142px ring with sparks, scales to "
        .. "any size, optional shadow). Both start on Show and stop on Hide.",
    clients = "Retail, Forever",
    keywords = "loading spinner busy wait throbber indeterminate progress",
    whenToUse = {
        "Waiting for something of unknown length: item data, a server answer, a search.",
        "A known amount of progress: a status bar or the radial fill instead.",
    },
    api = {
        { "CreateFrame(\"Frame\", nil, parent, \"LoadingSpinnerTemplate\")", "48x48. Its rotation group is .Anim, played on Show." },
        { "CreateFrame(\"Frame\", nil, parent, \"SpinnerTemplate\")", "142x142, any SetSize. Ring and Sparks atlases rotate together." },
        { "spinner:SetShown(bool)", "The only switch needed: OnShow restarts the animation, OnHide stops it." },
        { "spinner:SetDesaturated(bool)", "SpinnerTemplate: grey version (e.g. paused)." },
        { "spinner:SetShadowEnabled(bool)", "SpinnerTemplate: a soft shadow behind the ring." },
    },
    refs = {
        "Blizzard_SharedXML/SecureUIPanelTemplates.xml (LoadingSpinnerTemplate)",
        "Blizzard_SharedXML/Spinner.xml, Spinner.lua (SpinnerTemplate, SpinnerMixin)",
    },
})

-- @snippet loadingspinner-basic
local function CreateSpinners(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(220, 100)

    holder.Loading = CreateFrame("Frame", nil, holder, "LoadingSpinnerTemplate")
    holder.Loading:SetPoint("LEFT", 20, 0)

    holder.Spinner = CreateFrame("Frame", nil, holder, "SpinnerTemplate")
    holder.Spinner:SetSize(80, 80)
    holder.Spinner:SetPoint("RIGHT", -20, 0)
    return holder
end
-- @end

ns.AddExample("loadingspinner", {
    id = "loadingspinner-basic",
    title = "Both spinners",
    description = "Left: LoadingSpinnerTemplate. Right: SpinnerTemplate at 80px. Hiding them stops "
        .. "their animations.",
    height = 120,
    code = { "loadingspinner-basic" },
    create = function(stage)
        local holder = CreateSpinners(stage)
        holder:SetPoint("CENTER")
        -- In case OnShow did not run at creation (unverified): the animations are idempotent.
        holder.Loading.Anim:Play()
        holder.Spinner.Anim:Play()
        return holder
    end,
    controls = {
        { type = "check", key = "shown", label = "Shown", default = true },
        { type = "slider", key = "size", label = "SpinnerTemplate size", min = 24, max = 100, step = 2, default = 80 },
        { type = "check", key = "desaturated", label = "Desaturated", default = false },
        { type = "check", key = "shadow", label = "Shadow", default = false },
    },
    apply = function(holder, key, value)
        if key == "shown" then
            holder.Loading:SetShown(value)
            holder.Spinner:SetShown(value)
        elseif key == "size" then
            holder.Spinner:SetSize(value, value)
        elseif key == "desaturated" then
            holder.Spinner:SetDesaturated(value)
        elseif key == "shadow" then
            holder.Spinner:SetShadowEnabled(value)
        end
    end,
})
