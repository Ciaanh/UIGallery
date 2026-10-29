local addonName, ns = ...

ns.addonName = addonName

-- The addon's only way to write to chat.
function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffUI Gallery|r: " .. tostring(msg))
end

function ns.Clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

-- Runs fn(...). An error goes to the game's error handler (BugSack catches it) and comes back as
-- false + message, so one broken example never takes the window down with it.
function ns.SafeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        geterrorhandler()(result)
        return false, result
    end
    return true, result
end

-- Interface version of the running client: 120105 Retail, 16001 Forever.
function ns.ClientInterface()
    return select(4, GetBuildInfo())
end
