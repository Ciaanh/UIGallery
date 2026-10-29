local _, ns = ...

ns.AddComponent({
    id = "events",
    family = "basics",
    title = "Scripts and events",
    summary = "Frames react through scripts (OnShow, OnHide, OnUpdate, OnClick, OnEvent...) set with "
        .. "SetScript or HookScript. Game events reach a frame's OnEvent once it registers them. Between "
        .. "addon objects, CallbackRegistryMixin (and the global EventRegistry) carries custom events.",
    clients = "Retail, Forever, Classic",
    keywords = "event script OnEvent OnUpdate OnShow OnHide RegisterEvent throttle callback EventRegistry CallbackRegistryMixin TriggerEvent",
    whenToUse = {
        "Register game events while the frame needs them (OnShow / OnHide), not for the whole session.",
        "OnUpdate only while there is work; throttle on the accumulated elapsed time, never per frame.",
        "CallbackRegistryMixin when several parts of an addon follow one object's changes.",
        "HookScript to add to a Blizzard frame's script; SetScript replaces it.",
    },
    api = {
        { "frame:SetScript(script, fn) / HookScript(script, fn) / GetScript(script)", "Set (nil removes), add after the existing handler, read." },
        { "frame:RegisterEvent(event) / UnregisterEvent(event) / UnregisterAllEvents()", "Game events delivered to OnEvent(self, event, ...). An unknown event name raises." },
        { "frame:RegisterUnitEvent(event, unit1 [, unit2])", "A unit event for those units only." },
        { "FrameUtil.RegisterFrameForEvents(frame, events) / UnregisterFrameForEvents", "A list at once." },
        { "OnShow / OnHide", "Visibility changes, including through a parent: hiding a window hides (and fires OnHide on) every shown child." },
        { "OnUpdate(self, elapsed)", "Every drawn frame while the frame is shown; elapsed in seconds." },
        { "C_Timer.After(seconds, fn) / C_Timer.NewTimer / NewTicker", "One-shot or repeating timers; only NewTimer / NewTicker can be cancelled." },
        { "CreateFromMixins(CallbackRegistryMixin) + OnLoad() + GenerateCallbackEvents({ ... })", "An object with events: self.Event.Name." },
        { "registry:RegisterCallback(event, fn, owner) / UnregisterCallback(event, owner) / TriggerEvent(event, ...)", "fn(owner, ...). One callback per owner and event." },
        { "EventRegistry:RegisterCallback(\"GameMenuFrame.Shown\", fn, owner)", "Blizzard UI events (\"Frame.Event\" names), in Blizzard's TriggerEvent calls." },
        { "EventRegistry:RegisterFrameEventAndCallback(event, fn, owner)", "A game event as a callback, without a frame of your own." },
    },
    refs = {
        "Blizzard_SharedXMLBase/CallbackRegistry.lua",
        "Blizzard_SharedXMLBase/GlobalCallbackRegistry.lua (EventRegistry)",
        "Blizzard_SharedXMLBase/FrameUtil.lua",
    },
})

-- @snippet events-log
local EVENTS = { "MODIFIER_STATE_CHANGED", "PLAYER_TARGET_CHANGED" }

local function CreateEventLog(parent)
    local log = CreateFrame("Frame", nil, parent)
    log:SetSize(380, 90)
    log.Text = log:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    log.Text:SetPoint("TOPLEFT")
    log.Text:SetJustifyH("LEFT")
    log.lines = {}

    function log:Add(text)
        table.insert(self.lines, 1, text)
        self.lines[6] = nil
        self.Text:SetText(table.concat(self.lines, "\n"))
    end

    -- One method per event, named after it.
    function log:MODIFIER_STATE_CHANGED(key, down)
        self:Add(("MODIFIER_STATE_CHANGED %s %s"):format(key, down == 1 and "down" or "up"))
    end
    function log:PLAYER_TARGET_CHANGED()
        self:Add("PLAYER_TARGET_CHANGED, target exists: " .. tostring(UnitExists("target")))
    end
    log:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)

    -- Listen only while shown: a closed window costs nothing.
    log:SetScript("OnShow", function(self)
        FrameUtil.RegisterFrameForEvents(self, EVENTS)
        self:Add("OnShow: events registered")
    end)
    log:SetScript("OnHide", function(self)
        FrameUtil.UnregisterFrameForEvents(self, EVENTS)
    end)
    if log:IsVisible() then
        FrameUtil.RegisterFrameForEvents(log, EVENTS)
    end
    return log
end
-- @end

ns.AddExample("events", {
    id = "events-log",
    title = "Game events, registered while shown",
    description = "Press Shift, Ctrl or Alt, or change target. Untick \"Shown\": OnHide unregisters, so "
        .. "nothing arrives while hidden; tick it again and OnShow registers again. Closing the gallery "
        .. "does the same.",
    height = 120,
    code = { "events-log" },
    create = function(stage)
        local log = CreateEventLog(stage)
        log:SetPoint("TOPLEFT", 16, -14)
        return log
    end,
    controls = {
        { type = "check", key = "shown", label = "Shown", default = true, code = "log:SetShown(%s)" },
    },
    apply = function(log, key, value)
        if key == "shown" then
            log:SetShown(value)
        end
    end,
})

-- @snippet events-onupdate
local function CreateThrottledCounter(parent, interval)
    local counter = CreateFrame("Frame", nil, parent)
    counter:SetSize(300, 40)
    counter.Text = counter:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    counter.Text:SetPoint("CENTER")
    counter.interval = interval
    counter.elapsed, counter.frames, counter.ticks = 0, 0, 0

    -- Runs every drawn frame; the real work only once per interval.
    function counter:OnUpdate(elapsed)
        self.frames = self.frames + 1
        self.elapsed = self.elapsed + elapsed
        if self.elapsed < self.interval then
            return
        end
        self.elapsed = 0
        self.ticks = self.ticks + 1
        self.Text:SetFormattedText("%d ticks, %d frames", self.ticks, self.frames)
    end

    function counter:SetRunning(running)
        self:SetScript("OnUpdate", running and self.OnUpdate or nil)
    end
    return counter
end
-- @end

ns.AddExample("events", {
    id = "events-onupdate",
    title = "OnUpdate, throttled",
    description = "The frame count grows at your frame rate; the work (the tick) runs once per interval. "
        .. "Stopping removes the script, so the frame costs nothing. OnUpdate also stops while the "
        .. "frame is hidden.",
    height = 80,
    code = { "events-onupdate" },
    create = function(stage)
        local counter = CreateThrottledCounter(stage, 0.5)
        counter:SetPoint("CENTER")
        counter.Text:SetText("stopped")
        return counter
    end,
    controls = {
        { type = "check", key = "running", label = "Running", default = true, code = function(value)
            return value and "counter:SetScript(\"OnUpdate\", counter.OnUpdate)" or "counter:SetScript(\"OnUpdate\", nil)"
        end },
        { type = "slider", key = "interval", label = "Interval (s)", min = 0.1, max = 2, step = 0.1, default = 0.5, code = "counter.interval = %s" },
    },
    apply = function(counter, key, value)
        if key == "running" then
            counter:SetRunning(value)
        elseif key == "interval" then
            counter.interval = value
        end
    end,
})

-- @snippet events-callbacks
local function CreateCounterModel()
    local model = CreateFromMixins(CallbackRegistryMixin)
    model:OnLoad()
    model:GenerateCallbackEvents({ "OnChanged" })
    model.value = 0

    function model:Increment()
        self.value = self.value + 1
        self:TriggerEvent(self.Event.OnChanged, self.value)
    end
    return model
end

-- A view follows the model: the callback gets the owner first, then the event's arguments.
local function CreateCounterView(parent, model, label)
    local view = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    view.label = label
    view:SetText(label .. ": 0")
    function view:Follow(following)
        if following then
            model:RegisterCallback(model.Event.OnChanged, function(owner, value)
                owner:SetText(owner.label .. ": " .. value)
            end, view)
        else
            model:UnregisterCallback(model.Event.OnChanged, view)
        end
    end
    return view
end
-- @end

ns.AddExample("events", {
    id = "events-callbacks",
    title = "CallbackRegistryMixin",
    description = "One model, two views registered on its OnChanged event. Untick the second view: it "
        .. "unregisters and stops following.",
    height = 90,
    code = { "events-callbacks" },
    create = function(stage)
        local model = CreateCounterModel()
        local first = CreateCounterView(stage, model, "View 1")
        first:SetPoint("CENTER", -80, 0)
        first:Follow(true)
        local second = CreateCounterView(stage, model, "View 2")
        second:SetPoint("CENTER", 80, 0)
        return { model = model, second = second }
    end,
    controls = {
        { type = "button", key = "increment", label = "Increment" },
        { type = "check", key = "follow", label = "View 2 follows", default = true, code = function(value)
            return value and "model:RegisterCallback(model.Event.OnChanged, OnChanged, view2)"
                or "model:UnregisterCallback(model.Event.OnChanged, view2)"
        end },
    },
    apply = function(widgets, key, value)
        if key == "increment" then
            widgets.model:Increment()
        elseif key == "follow" then
            widgets.second:Follow(value)
        end
    end,
})
