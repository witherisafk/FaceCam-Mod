--
-- FaceCam Mod v1.2.0
-- mod made by witherisafk :3
--
-- referenced code and functionality from the following mods (please check them out!):
-- * Mod Config Menu - Impure [https://steamcommunity.com/sharedfiles/filedetails/?id=3701683951]
-- * Boiling Poo Reaction SFX For Quality 0 Items [https://steamcommunity.com/sharedfiles/filedetails/?id=3776903714]
-- * ReactionAPI [https://steamcommunity.com/sharedfiles/filedetails/?id=3096181411]
--

-- important variables
local facecam_mod = RegisterMod("FaceCam Mod", 1)
local player = Isaac.GetPlayer(0)
local json = require("json")

-- save data for mod
FaceCamMod = {
    FaceCamConfigurations = {
        version = 1.0,

        should_streamer_visible = true,
        should_streamer_visible_des = "Default: True",
        should_streamer_speak = true,
        should_streamer_speak_des = "Default: True",
        should_auto_reposition = true,
        should_auto_reposition_des = "Default: True",
        should_streamer_react = true,
        should_streamer_react_des = "Default: True",

        height_additional_modifier = 0,
        height_additional_modifier_des = "Default: 0",
        facecam_scale = 0.4,
        facecam_scale_des = "Default: 0.4",
        facecam_width = 244,
        facecam_width_des = "Default: 244",
        facecam_height = 206,
        facecam_height_des = "Default: 206",
        facecam_pos_width = 0,
        facecam_pos_width_des = "Default: 0 (only changes if Auto Repos. is False)",
        facecam_pos_height = 0,
        facecam_pos_height_des = "Default: 0 (only changes if Auto Repos. is False)",
        upon_hit_react_chance = 0,
        upon_hit_react_chance_des = "Default: 0",
        upon_kill_react_chance = 0,
        upon_kill_react_chance_des = "Default: 0",
        idle_react_chance = 0,
        idle_react_chance_des = "Default: 0",

        sfx_volume = 2.0,
        sfx_volume_des = "Default: 2.0",
        delay_threshold = 25,
        delay_threshold_des = "Default: 25"
    },

    -- sprites
    idle_sprites = {}, speaking_sprites = {}, happy_sprites = {}, angry_sprites = {}, intro_sprites = {}, death_sprites = {},

    -- sfx
    idle_sfx = {}, speaking_sfx = {}, happy_sfx = {},angry_sfx = {}, intro_sfx = {}, death_sfx = {}, hit_sfx = {}, kill_sfx = {},

    -- callbacks
    callbacks = {}
}

local persistent_data = {}

-- general variables
local screen_width, screen_height, facecam, sprite, facecam_pos, facecam_pos_width, facecam_pos_height, reaction_api
local is_mod_loaded, has_started, should_streamer_visible, should_streamer_speak, should_auto_reposition, is_holding_trinket, is_reacting, should_streamer_react = false, false, true, true, true, false, false, true
local delay, delay_threshold, height_additional_modifier, facecam_scale, facecam_width, facecam_height, upon_hit_react_chance, upon_kill_react_chance, idle_react_chance = 0, 25, 0, 0.4, 244, 206, 0, 0, 0

-- sfx stuff
local sfx = SFXManager()
local sfx_volume = 2.0

-- save and update function
function facecam_mod.SaveAndUpdate()
    -- save data
    facecam_mod:SaveData(json.encode(persistent_data))

    -- apply saved data
    should_streamer_visible = persistent_data["should_streamer_visible"]
    should_streamer_speak = persistent_data["should_streamer_speak"]
    should_auto_reposition = persistent_data["should_auto_reposition"]
    should_streamer_react = persistent_data["should_streamer_react"]

    height_additional_modifier = persistent_data["height_additional_modifier"]
    facecam_scale = persistent_data["facecam_scale"]
    facecam_width = persistent_data["facecam_width"]
    facecam_height = persistent_data["facecam_height"]
    facecam_pos_width = persistent_data["facecam_pos_width"]
    facecam_pos_height = persistent_data["facecam_pos_height"]
    upon_hit_react_chance = persistent_data["upon_hit_react_chance"]
    upon_kill_react_chance = persistent_data["upon_kill_react_chance"]
    idle_react_chance = persistent_data["idle_react_chance"]

    sfx_volume = persistent_data["sfx_volume"]
    delay_threshold = persistent_data["delay_threshold"]

    -- end function
end

-- load config function
function facecam_mod.LoadConfig()
    -- load config
    if (facecam_mod:HasData()) then -- if save exists, load it
        persistent_data = json.decode(facecam_mod:LoadData())
    else -- otherwise, reset persistent_data
        persistent_data = {}
    end

    -- update data
    persistent_data["version"] = FaceCamMod.FaceCamConfigurations["version"]

    for k, v in pairs(FaceCamMod.FaceCamConfigurations) do
        if (persistent_data[k] == nil) then
            persistent_data[k] = v
        end
    end

    -- apply existing values
    facecam_mod.SaveAndUpdate()

    -- end function
end

-- speak function
function facecam_mod.Speak(st)
    -- check if streamer should speak or if nil
    if not should_streamer_speak or not st or #st == 0 then return end

    -- play sfx
    sfx:Play(st[math.random(#st)], sfx_volume, 0, false, 1.0, 0.0)

    -- end function
end

-- animate facecam function
-- returns true / false as a form of error checking to ensure missing sprites disallow sfx to play
function facecam_mod.AnimateFaceCam(sprites)
    -- check if nil
    if not sprites or #sprites == 0 then return false end

    -- select a random animation and play it
    sprite = sprites[math.random(#sprites)]

    if not sprite.Anim then return end

    facecam = sprite.Sprite

    if sprite.Anim == "Vary" then
        facecam:PlayRandom()
    else
        facecam:Play(sprite.Anim, true)
    end

    -- end function
end

-- react function
-- : the sprites variable is supposed to be a table of loaded sprites, while the sfx variable is a table of sfx ids; see FaceCamMod.LoadFaceCam() to see how these values are initialized normally; if sprites is a bool oF value false, only a sfx from the provided sfx table will be played
function FaceCamMod.React(sprites, sfx)
    -- react
    if sprites and not sprites == false then
        facecam_mod.AnimateFaceCam(sprites)
    end

    facecam_mod.Speak(sfx)

    -- end function
end

-- is reaction api ready function
function facecam_mod.IsReactionAPI()
    reaction_api = ReactionAPI

    if not reaction_api or not reaction_api.Loaded or not reaction_api.Interface or not reaction_api.Visibility then return false else return true end

    -- end function
end

--  get best collectible function
-- TODO: functionality for all qualities in a separate func
function facecam_mod.GetBestCollectible()
    -- reaction api
    if not facecam_mod.IsReactionAPI() then return nil end

    -- get highest quality
    local q = reaction_api.Interface.cGetBestQuality(reaction_api.Visibility.VISIBLE)

    if q then return q else return nil end

    -- end function
end

-- is isaac blind function
function facecam_mod.IsIsaacBlind()
    -- reaction api
    if not facecam_mod.IsReactionAPI() then return nil end

    -- check for blind pedestals
    local _, _, b_pedestals, _ = ReactionAPI.Interface.GetCollectibleData()

    if not b_pedestals or #b_pedestals <= 0 then return false else return true end

    -- end function
end

-- start reacting function
function facecam_mod.StartReacting()
    -- set is_reacting for conditionals in Update() to operate
    is_reacting = true

    -- end function
end

-- entity take damage function
function facecam_mod.EntityTakeDamage()
    -- check if should react
    if upon_hit_react_chance > 0 and math.random(upon_hit_react_chance) == 1 then
        FaceCamMod.React(FaceCamMod.angry_sprites, FaceCamMod.hit_sfx)
    end

    -- end function
end

-- post entity kill function
function facecam_mod.PostEntityKill(_, e)
    -- check if player actually died
    local p = e:ToPlayer()

    if p and p:IsDead() and not p:WillPlayerRevive() then -- react to death
        FaceCamMod.React(FaceCamMod.death_sprites, FaceCamMod.death_sfx)

        return
    end

    if upon_kill_react_chance > 0 and math.random(upon_kill_react_chance) == 1 then -- otherwise, check if should react to getting a kill if player is not dead
        FaceCamMod.React(FaceCamMod.happy_sprites, FaceCamMod.kill_sfx)
    end

    -- end function
end

-- post game started function
function facecam_mod.PostGameStarted()
    -- load config if internal version is blank
    if persistent_data["version"] == nil then
        facecam_mod.LoadConfig()
    end

    -- define player
    player = Isaac.GetPlayer(0)

    -- end function
end

-- update function
function facecam_mod.Update()
    -- if holding trinket
    if has_started then
        if player and player:GetPlayerType() == 19 then
            is_holding_trinket = false
        elseif player and player:GetTrinket(0) >= 1 and is_holding_trinket == false then
            is_holding_trinket = true
        elseif player and player:GetTrinket(0) == 0 and is_holding_trinket == true then
            is_holding_trinket = false
        end
    end

    -- if reacting
    -- TODO: restructure for option to trigger reactions regardless of curse of the blind
    -- TODO: restructure for when specific characters are played (e.g. negative if quality 4 and playing as tainted cain, negative if blind and quality 4 absorbed by the void), and when specific room layouts are encountered; maybe by that point just put all of this in a separate func to be called here
    if is_reacting and should_streamer_react then
        local blind = facecam_mod.IsIsaacBlind()

        if blind ~= nil and not blind then -- if returned false
            local quality = facecam_mod.GetBestCollectible()

            if quality and quality == 4 then -- if quality 4 encountered
                FaceCamMod.React(FaceCamMod.happy_sprites, FaceCamMod.happy_sfx)
            elseif quality and quality == 0 then -- if quality 0 encountered
                FaceCamMod.React(FaceCamMod.angry_sprites, FaceCamMod.angry_sfx)
            end
        elseif blind then -- if returned true
            -- TODO: add positive reaction when isaac is blind and picking up a quality 4 item
        end

        is_reacting = false
    end

    -- intro sequence
    if not facecam then
        if not FaceCamMod.intro_sprites or not FaceCamMod.intro_sfx or not should_streamer_visible then return end

        if #FaceCamMod.intro_sprites > 0 and not has_started then
            delay = delay + 1

            if delay == delay_threshold then
                -- never execute this again
                has_started = true

                -- animate facecam
                facecam_mod.AnimateFaceCam(FaceCamMod.intro_sprites)

                if #FaceCamMod.intro_sfx > 0 then
                    -- speak
                    facecam_mod.Speak(FaceCamMod.intro_sfx)
                end
            else
                return
            end
        else
            return
        end
    end

    -- update
    facecam:Update()

    -- animate idle once finished
    if facecam:IsFinished(facecam:GetAnimation()) then
        facecam_mod.AnimateFaceCam(FaceCamMod.idle_sprites)
    end

    -- end function
end

-- render function
function facecam_mod.Render()
    -- check if facecam nil or if should render
    if not facecam or not should_streamer_visible then return end

    -- get screen dimensions and scale to them
    screen_width, screen_height = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
    facecam.Scale = Vector(facecam_scale, facecam_scale)

    if should_auto_reposition then
        if is_holding_trinket then -- move outta da way when a trinket is being held
            facecam_pos = Vector((screen_width / 2) - (facecam_width / 2), (screen_height + height_additional_modifier - (facecam_scale * facecam_height)))
        else
            facecam_pos = Vector((facecam_width / 2), (screen_height + height_additional_modifier - (facecam_scale * facecam_height)))
        end
    else
        facecam_pos = Vector(facecam_pos_width, facecam_pos_height)
    end

    -- render
    facecam:RenderLayer(0, facecam_pos)

    -- end function
end

-- create mod config menu function
function facecam_mod.CreateModMenuSupport()
    -- check if mod config menu ready
    local mcm = ModConfigMenu or MCM

    if not mcm then return end

    -- variables
    local category, sc_1, sc_2, sc_3 = "FaceCam Mod", "General", "Face Cam", "Misc"

    -- sub category 1
    mcm.AddText(category, sc_1, function() return "Basic configurations." end)
    mcm.AddSpace(category, sc_1)

    -- should_streamer_visible
    mcm.AddSetting(category, sc_1, {
        Type = mcm.OptionType.BOOLEAN,
        CurrentSetting = function()
            return persistent_data["should_streamer_visible"]
        end,
        Minimum = false,
        Maximum = true,
        Display = function()
            return "Visible: " .. (persistent_data["should_streamer_visible"] and "True" or "False")
        end,
        OnChange = function(current)
            persistent_data["should_streamer_visible"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Whether the face cam is visible.", FaceCamMod.FaceCamConfigurations["should_streamer_visible_des"]}})

    -- should_streamer_speak
    mcm.AddSetting(category, sc_1, {
        Type = mcm.OptionType.BOOLEAN,
        CurrentSetting = function()
            return persistent_data["should_streamer_speak"]
        end,
        Minimum = false,
        Maximum = true,
        Display = function()
            return "Streamer Can Speak: " .. (persistent_data["should_streamer_speak"] and "True" or "False")
        end,
        OnChange = function(current)
            persistent_data["should_streamer_speak"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Whether sound effects from the loaded mod should play.", FaceCamMod.FaceCamConfigurations["should_streamer_speak_des"]}})

    -- should_streamer_react
    mcm.AddSetting(category, sc_1, {
        Type = mcm.OptionType.BOOLEAN,
        CurrentSetting = function()
            return persistent_data["should_streamer_react"]
        end,
        Minimum = false,
        Maximum = true,
        Display = function()
            return "Streamer Can React: " .. (persistent_data["should_streamer_react"] and "True" or "False")
        end,
        OnChange = function(current)
            persistent_data["should_streamer_react"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Whether the streamer should react to items of specific qualities.", FaceCamMod.FaceCamConfigurations["should_streamer_react_des"]}})

    -- sub category 2
    mcm.AddText(category, sc_2, function() return "Sprite configurations." end)
    mcm.AddSpace(category, sc_2)

    -- should_auto_reposition
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.BOOLEAN,
        CurrentSetting = function()
            return persistent_data["should_auto_reposition"]
        end,
        Minimum = false,
        Maximum = true,
        Display = function()
            return "Auto Reposition: " .. (persistent_data["should_auto_reposition"] and "True" or "False")
        end,
        OnChange = function(current)
            persistent_data["should_auto_reposition"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Whether the face cam is automatically positioned; set to false to enable manual repositioning.", FaceCamMod.FaceCamConfigurations["should_auto_reposition_des"]}})

    -- height_additional_modifier
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["height_additional_modifier"]
        end,
        Minimum = -1280, -- idk, would anyone even need ts
        Maximum = 1280,
        Display = function()
            return "Additional Height: " .. persistent_data["height_additional_modifier"]
        end,
        OnChange = function(current)
            persistent_data["height_additional_modifier"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Value to add to value subtracted against screen height for vertical position of facecam. Ignore this and disable auto reposition for manual positioning.", FaceCamMod.FaceCamConfigurations["height_additional_modifier_des"]}})

    -- facecam_scale
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return math.floor(persistent_data["facecam_scale"] * 10)
        end,
        Minimum = 1,
        Maximum = 60,
        ModifyBy = 1,
        Display = function()
            return "Face Cam Scale: " .. math.floor(persistent_data["facecam_scale"] * 10)
        end,
        OnChange = function(current)
            persistent_data["facecam_scale"] = current / 10

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Scale of the face cam; this value is a multiplier. Auto repositioning requires this value to be at its default.", FaceCamMod.FaceCamConfigurations["facecam_scale_des"]}})

    -- facecam_width
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["facecam_width"]
        end,
        Minimum = 1,
        Maximum = 1920,
        Display = function()
            return "Face Cam Width: " .. persistent_data["facecam_width"]
        end,
        OnChange = function(current)
            persistent_data["facecam_width"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Width of the face cam; utilized for auto positioning, do not modify unless you know what you're doing.", FaceCamMod.FaceCamConfigurations["facecam_width_des"]}})

    -- facecam_height
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["facecam_height"]
        end,
        Minimum = 1,
        Maximum = 800,
        Display = function()
            return "Face Cam Height: " .. persistent_data["facecam_height"]
        end,
        OnChange = function(current)
            persistent_data["facecam_height"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Height of the face cam; utilized for auto positioning, do not modify unless you know what you're doing.", FaceCamMod.FaceCamConfigurations["facecam_height_des"]}})

    -- facecam_pos_width
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["facecam_pos_width"]
        end,
        Minimum = 0,
        Maximum = 800,
        Display = function()
            return "Face Cam Horizontal Pos.: " .. persistent_data["facecam_pos_width"]
        end,
        OnChange = function(current)
            persistent_data["facecam_pos_width"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Horizontal position of the face cam sprite; only changes if auto repositioning is set to false.", FaceCamMod.FaceCamConfigurations["facecam_pos_width_des"]}})

    -- facecam_pos_height
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["facecam_pos_height"]
        end,
        Minimum = 0,
        Maximum = 1920,
        Display = function()
            return "Face Cam Vertical Pos.: " .. persistent_data["facecam_pos_height"]
        end,
        OnChange = function(current)
            persistent_data["facecam_pos_height"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Vertical position of the face cam sprite; only changes if auto repositioning is set to false.", FaceCamMod.FaceCamConfigurations["facecam_pos_height_des"]}})

    -- upon_hit_react_chance
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["upon_hit_react_chance"]
        end,
        Minimum = 0,
        Maximum = 50,
        Display = function()
            return "Upon Hit React Chance: " .. persistent_data["upon_hit_react_chance"]
        end,
        OnChange = function(current)
            persistent_data["upon_hit_react_chance"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"1 in x chance to react upon getting hit; setting this to 0 disables this reaction.", FaceCamMod.FaceCamConfigurations["upon_hit_react_chance_des"]}})

    -- upon_kill_react_chance
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["upon_kill_react_chance"]
        end,
        Minimum = 0,
        Maximum = 50,
        Display = function()
            return "Upon Kill React Chance: " .. persistent_data["upon_kill_react_chance"]
        end,
        OnChange = function(current)
            persistent_data["upon_kill_react_chance"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"1 in x chance to react upon getting a kill; setting this to 0 disables this reaction.", FaceCamMod.FaceCamConfigurations["upon_kill_react_chance_des"]}})

    -- idle_react_chance
    mcm.AddSetting(category, sc_2, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["idle_react_chance"]
        end,
        Minimum = 0,
        Maximum = 50,
        Display = function()
            return "Idle React Chance: " .. persistent_data["idle_react_chance"]
        end,
        OnChange = function(current)
            persistent_data["idle_react_chance"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"WIP, currently unused; will likely work the same way as the above listed react chances.", FaceCamMod.FaceCamConfigurations["idle_react_chance_des"]}})

    -- sub category 3
    mcm.AddText(category, sc_3, function() return "Misc. configurations." end)
    mcm.AddSpace(category, sc_3)

    -- sfx_volume
    mcm.AddSetting(category, sc_3, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["sfx_volume"]
        end,
        Minimum = 0.0,
        Maximum = 20.0,
        Display = function()
            return "SFX Volume: " .. persistent_data["sfx_volume"]
        end,
        OnChange = function(current)
            persistent_data["sfx_volume"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"Volume of played SFX from the loaded mod.", FaceCamMod.FaceCamConfigurations["sfx_volume_des"]}})

    -- delay_threshold
    mcm.AddSetting(category, sc_3, {
        Type = mcm.OptionType.NUMBER,
        CurrentSetting = function()
            return persistent_data["delay_threshold"]
        end,
        Minimum = 1,
        Maximum = 100,
        Display = function()
            return "Delay Threshold: " .. persistent_data["delay_threshold"]
        end,
        OnChange = function(current)
            persistent_data["delay_threshold"] = current

            facecam_mod.SaveAndUpdate()
        end,
        Info = {"How many frames until actual sprite rendering / SFX playing for the mod occurs.", FaceCamMod.FaceCamConfigurations["delay_threshold_des"]}})

    -- end function
end

-- assign callbacks
FaceCamMod.callbacks = {
    {ModCallbacks.MC_POST_UPDATE, facecam_mod.Update },
    {ModCallbacks.MC_POST_RENDER, facecam_mod.Render },
    {ModCallbacks.MC_POST_GAME_STARTED, facecam_mod.PostGameStarted },
    {ModCallbacks.MC_POST_NEW_ROOM, facecam_mod.StartReacting },
    {ModCallbacks.MC_USE_ITEM, facecam_mod.StartReacting }, -- this and MC_USE_CARD are just in case an item spawns through using an item (e.g. magic skin, blank card, etc)
    {ModCallbacks.MC_USE_CARD, facecam_mod.StartReacting, EntityType.ENTITY_PLAYER },
    {ModCallbacks.MC_POST_ENTITY_KILL, facecam_mod.PostEntityKill, EntityType.ENTITY_PLAYER }
}

-- load facecam function
function FaceCamMod.LoadFaceCam(sprite_table, sfx_table, config)
    -- ensure this does not run multiple times
    if is_mod_loaded then return end

    -- for warnings
    local sprites_type_check, sfx_type_check = false, false

    -- initialize sprites
    for _, o in ipairs(sprite_table) do
        if o.Name then
            -- initialize
            o.Sprite = Sprite()
            o.Sprite:Load(o.Name, true)

            -- failsafe
            if not o.Type or type(o.Type) ~= "table" then
                o.Type = FaceCamMod.idle_sprites

                -- warning regarding new structure for supported mods
                if not sprites_type_check then
                    Isaac.ConsoleOutput("[FaceCam Mod] Please update the supported mod to directly reference tables for sprites as per v1.2.0!")

                    sprites_type_check = true
                end
            end

            -- save sprite
            table.insert(o.Type, o)
        end
    end

    -- initialize sound effects
    for _, o in ipairs(sfx_table) do
        if o.Name then
            local id = Isaac.GetSoundIdByName(o.Name)

            -- failsafe
            if not o.Type or type(o.Type) ~= "table" then
                o.Type = FaceCamMod.idle_sfx

                -- warning regarding new structure for supported mods
                if not sfx_type_check then
                    Isaac.ConsoleOutput("[FaceCam Mod] Please update the supported mod to directly reference tables for sound effects as per v1.2.0!")

                    sfx_type_check = true
                end
            end

            -- save sfx
            table.insert(o.Type, id)
        end
    end

    -- initialize supported mod settings
    for k, v in pairs(config) do
        FaceCamMod.FaceCamConfigurations[k] = v
    end

    -- save data
    facecam_mod.LoadConfig()

    -- add mod config menu support
    facecam_mod.CreateModMenuSupport()

    -- add callbacks
    for _, c in ipairs(FaceCamMod.callbacks) do
        if not c[3] then
            facecam_mod:AddCallback(c[1], c[2])
        else
            facecam_mod:AddCallback(c[1], c[2], c[3])
        end
    end

    -- facecam_mod:AddCallback(ModCallbacks.MC_POST_UPDATE, facecam_mod.Update)
    -- facecam_mod:AddCallback(ModCallbacks.MC_POST_RENDER, facecam_mod.Render)
    -- facecam_mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, facecam_mod.PostGameStarted)
    -- facecam_mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, facecam_mod.StartReacting)
    -- facecam_mod:AddCallback(ModCallbacks.MC_USE_ITEM, facecam_mod.StartReacting) -- this and MC_USE_CARD are just in case an item spawns through using an active (e.g. magic skin, blank card, etc)
    -- facecam_mod:AddCallback(ModCallbacks.MC_USE_CARD, facecam_mod.StartReacting)
    -- facecam_mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, facecam_mod.PostEntityKill, EntityType.ENTITY_PLAYER)
    -- facecam_mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, facecam_mod.EntityTakeDamage, EntityType.ENTITY_PLAYER)

    -- ensure this method does not run again
    is_mod_loaded = true

    -- end function
end
