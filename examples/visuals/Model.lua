local _, ns = ...

ns.AddComponent({
    id = "model",
    family = "visuals",
    title = "3D models",
    summary = "Frames that render a character or creature. PlayerModel shows a unit (SetUnit), a "
        .. "creature or a display ID, with facing, zoom and an animation; DressUpModel adds TryOn and "
        .. "Undress. ModelScene is the newer, camera-and-actors system behind the dressing room and "
        .. "the shop, driven by model scene IDs from the game data.",
    clients = "Retail, Forever, Classic",
    keywords = "model 3d character player portrait creature PlayerModel DressUpModel ModelScene actor camera animation",
    whenToUse = {
        "A character preview in your window: PlayerModel (or DressUpModel to try items on).",
        "A portrait-style bust: SetPortraitZoom(1).",
        "Several actors, camera moves, Blizzard's preset framings: ModelScene with a model scene ID.",
    },
    api = {
        { "CreateFrame(\"PlayerModel\", nil, parent)", "Also \"DressUpModel\", \"CinematicModel\", \"TabardModel\"." },
        { "model:SetUnit(unit) / SetCreature(creatureID) / SetDisplayInfo(displayID)", "What to show; RefreshUnit after the unit's look changed." },
        { "model:SetFacing(radians)", "Turn around the vertical axis; 0 faces the camera.", "0" },
        { "model:SetPortraitZoom(zoom) / SetCamDistanceScale(scale)", "0 full body, 1 head; camera distance factor.", "0, 1" },
        { "model:SetPosition(x, y, z)", "Move the model inside the frame (x towards the camera)." },
        { "model:SetAnimation(animationID)", "0 stand, 4 walk, 5 run, 60 talk (AnimationData IDs)." },
        { "dressUp:TryOn(itemLink or transmog ID) / Undress()", "DressUpModel only." },
        { "CreateFrame(\"ModelScene\", nil, parent, \"ModelSceneMixinTemplate\") + SetFromModelSceneID(id)", "A preset scene; scene:GetPlayerActor() or GetActorByTag(tag), then actor:SetModelByUnit(\"player\")." },
    },
    refs = {
        "Blizzard_APIDocumentationGenerated/FrameAPICharacterModelBaseDocumentation.lua",
        "Blizzard_APIDocumentationGenerated/SimpleModelAPIDocumentation.lua",
        "Blizzard_SharedXML/ModelSceneMixin.lua",
    },
})

local ANIMATIONS = { { 0, "Stand" }, { 4, "Walk" }, { 5, "Run" }, { 60, "Talk" }, { 69, "Dance" } }

-- @snippet model-player
local function CreatePlayerPreview(parent, width, height)
    local model = CreateFrame("PlayerModel", nil, parent)
    model:SetSize(width, height)
    model:SetUnit("player")

    -- Drag to turn the model: OnUpdate only while the button is held.
    local function FollowCursor(self)
        local x = GetCursorPosition()
        self.facing = (self.facing or 0) + (x - self.dragX) * 0.01
        self.dragX = x
        self:SetFacing(self.facing)
    end
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self)
        self.dragX = GetCursorPosition()
        self:SetScript("OnUpdate", FollowCursor)
    end)
    model:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    return model
end
-- @end

ns.AddExample("model", {
    id = "model-player",
    title = "PlayerModel of your character",
    description = "Drag the model to turn it. Zoom 1 is the portrait framing used by unit frames.",
    height = 260,
    code = { "model-player" },
    create = function(stage)
        local model = CreatePlayerPreview(stage, 220, 240)
        model:SetPoint("CENTER")
        return model
    end,
    controls = {
        { type = "slider", key = "facing", label = "Facing (radians)", min = -3.1, max = 3.1, step = 0.1, default = 0.4, code = "model:SetFacing(%s)" },
        { type = "slider", key = "zoom", label = "Portrait zoom", min = 0, max = 1, step = 0.05, default = 0, code = "model:SetPortraitZoom(%s)" },
        { type = "slider", key = "distance", label = "Camera distance", min = 0.5, max = 2, step = 0.05, default = 1, code = "model:SetCamDistanceScale(%s)" },
        { type = "choice", key = "animation", label = "Animation", choices = ANIMATIONS, default = 0, code = "model:SetAnimation(%s)" },
    },
    apply = function(model, key, value)
        if key == "facing" then
            model.facing = value
            model:SetFacing(value)
        elseif key == "zoom" then
            model:SetPortraitZoom(value)
        elseif key == "distance" then
            model:SetCamDistanceScale(value)
        elseif key == "animation" then
            model:SetAnimation(value)
        end
    end,
})
