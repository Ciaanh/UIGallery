local _, ns = ...

ns.AddComponent({
    id = "money",
    family = "visuals",
    title = "Money display",
    summary = "Gold, silver and copper with their coin icons. SmallMoneyFrameTemplate is the frame "
        .. "Blizzard puts in merchant, quest and auction rows; GetMoneyString gives the same as a "
        .. "string to put in any FontString or tooltip line.",
    clients = "Retail, Forever",
    keywords = "money gold silver copper coin price cost currency MoneyFrame GetMoneyString",
    whenToUse = {
        "A price inside a row or a window: SmallMoneyFrameTemplate set to STATIC.",
        "Money inside text (a tooltip, a chat line, a label): GetMoneyString.",
    },
    api = {
        { "CreateFrame(\"Frame\", nil, parent, \"SmallMoneyFrameTemplate\")", "Gold / silver / copper buttons; tracks the player's money until you change its type." },
        { "MoneyFrame_SetType(frame, \"STATIC\")", "Show a fixed amount instead of the player's money (other types: PLAYER, AUCTION, GUILDBANK...)." },
        { "MoneyFrame_Update(frame, copper)", "The amount, in copper. Zero denominations collapse." },
        { "GetMoneyString(copper [, separateThousands])", "\"12g 34s 56c\" with coin icons, as a string." },
        { "C_CurrencyInfo.GetCoinTextureString(copper)", "The same from the game API." },
        { "COPPER_PER_SILVER, SILVER_PER_GOLD, COPPER_PER_GOLD", "Constants (100, 100, 10000)." },
    },
    refs = {
        "Blizzard_MoneyFrame/Mainline/MoneyFrame.xml (SmallMoneyFrameTemplate)",
        "Blizzard_MoneyFrame/Mainline/MoneyFrame.lua (MoneyFrame_Update, MoneyFrame_SetType)",
        "Blizzard_SharedXML/FormattingUtil.lua (GetMoneyString)",
    },
})

local AMOUNTS = {
    { 57, "57 copper" }, { 1234, "12s 34c" }, { 987654, "98g 76s 54c" }, { 123456789, "12,345g" },
}

-- @snippet money-basic
local function CreatePrice(parent, copper)
    local price = CreateFrame("Frame", nil, parent, "SmallMoneyFrameTemplate")
    MoneyFrame_SetType(price, "STATIC")
    MoneyFrame_Update(price, copper)
    return price
end

local function CreatePriceText(parent, copper)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetText(GetMoneyString(copper, true))
    return text
end
-- @end

ns.AddExample("money", {
    id = "money-basic",
    title = "Money frame and money string",
    description = "Top: SmallMoneyFrameTemplate (hover the coins). Bottom: GetMoneyString in a "
        .. "FontString, with thousands separated.",
    height = 90,
    code = { "money-basic" },
    create = function(stage)
        local holder = CreateFrame("Frame", nil, stage)
        holder:SetAllPoints()
        holder.Frame = CreatePrice(holder, AMOUNTS[1][1])
        holder.Frame:SetPoint("CENTER", 0, 14)
        holder.Text = CreatePriceText(holder, AMOUNTS[1][1])
        holder.Text:SetPoint("CENTER", 0, -14)
        return holder
    end,
    controls = {
        { type = "choice", key = "amount", label = "Amount", choices = AMOUNTS, default = 57 },
    },
    apply = function(holder, key, value)
        if key == "amount" then
            MoneyFrame_Update(holder.Frame, value)
            holder.Text:SetText(GetMoneyString(value, true))
        end
    end,
})
