local _, ns = ...

ns.AddComponent({
    id = "dialogs",
    family = "layout",
    title = "Popup dialogs (StaticPopup)",
    summary = "The game's confirmation popups at the top of the screen. Describe a dialog once in "
        .. "StaticPopupDialogs, then StaticPopup_Show it by name; or skip the definition with the "
        .. "generic confirmation and input box helpers.",
    clients = "Retail, Forever",
    keywords = "popup dialog confirm confirmation yes no prompt input StaticPopup modal",
    whenToUse = {
        "Confirming something destructive (reset, delete), or asking for one short text.",
        "Anything richer than a line of text and two buttons: your own window (Windows).",
        "Never for protected actions from addon code: dialogs shown by an addon are tainted.",
    },
    api = {
        { "StaticPopupDialogs[\"NAME\"] = { text, button1, button2, OnAccept, OnCancel, ... }", "The definition. Prefix the key with your addon's name." },
        { "StaticPopup_Show(name [, textArg1, textArg2, data])", "Shows it; the args fill %s in text; data is passed to the callbacks. Returns the dialog frame or nil." },
        { "OnAccept(dialog, data) / OnCancel(dialog, data, reason) / OnShow(dialog, data)", "Callbacks. Return true from OnAccept to keep the dialog open." },
        { "timeout, whileDead, hideOnEscape, showAlert", "Seconds before it closes (0 = never), shown when dead, Escape closes it, warning icon." },
        { "hasEditBox, maxLetters + dialog:GetEditBox():GetText()", "A text field in the dialog." },
        { "StaticPopup_ShowGenericConfirmation(text, callback)", "Yes / No without a definition." },
        { "StaticPopup_ShowCustomGenericInputBox({ text, callback(text), acceptText, cancelText, maxLetters })", "One text field without a definition." },
        { "StaticPopup_Hide(name) / StaticPopup_Visible(name)", "Close it; find the shown one." },
    },
    refs = {
        "Blizzard_StaticPopup/StaticPopup.lua (StaticPopup_Show, the generic helpers)",
        "Blizzard_StaticPopup_Game/GameDialogDefs.lua (GENERIC_CONFIRMATION, GENERIC_INPUT_BOX and every game dialog)",
    },
})

-- @snippet dialogs-static
StaticPopupDialogs["UIGALLERY_RESET_DEMO"] = {
    text = "Reset %s to its defaults?",
    button1 = RESET,
    button2 = CANCEL,
    OnAccept = function(_, data)
        data.onReset()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
}

local function AskReset(what, onReset)
    StaticPopup_Show("UIGALLERY_RESET_DEMO", what, nil, { onReset = onReset })
end

local function AskConfirmation(onYes)
    StaticPopup_ShowGenericConfirmation("Do the thing?", onYes)
end

local function AskName(onName)
    StaticPopup_ShowCustomGenericInputBox({
        text = "Name of the new profile:",
        acceptText = ACCEPT,
        maxLetters = 24,
        callback = onName,
    })
end
-- @end

ns.AddExample("dialogs", {
    id = "dialogs-static",
    title = "Defined dialog and generic helpers",
    description = "Each button opens a popup at the top of the screen; the answer shows below.",
    height = 80,
    code = { "dialogs-static" },
    create = function(stage)
        local status = stage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("BOTTOM", 0, 10)
        local holder = CreateFrame("Frame", nil, stage)
        holder:SetAllPoints()
        holder.Status = status
        return holder
    end,
    controls = {
        { type = "button", key = "reset", label = "StaticPopup_Show" },
        { type = "button", key = "confirm", label = "Generic confirmation" },
        { type = "button", key = "input", label = "Generic input box" },
    },
    apply = function(holder, key)
        local status = holder.Status
        if key == "reset" then
            AskReset("the gallery", function() status:SetText("Reset accepted") end)
        elseif key == "confirm" then
            AskConfirmation(function() status:SetText("Confirmed") end)
        elseif key == "input" then
            AskName(function(text) status:SetText("Name: " .. text) end)
        end
    end,
})
