local Constants = Ext.Require("Shared/Constants.lua")
local Channels = Ext.Require("Shared/Channels.lua")

local AppearanceManager = {}

local function resolveCharacter(character)
    if not character or character == "" then
        return nil
    end

    if Osi.Exists and Osi.Exists(character) == 0 then
        return nil
    end

    if Osi.GetMultiplayerCharacter then
        local mpCharacter = Osi.GetMultiplayerCharacter(character)
        if mpCharacter and mpCharacter ~= "" and Osi.Exists(mpCharacter) == 1 then
            return mpCharacter
        end
    end

    return character
end

local function isLocallyOwned(character)
    character = resolveCharacter(character)
    if not character then
        return false
    end

    if not Ext.Entity or not Ext.Entity.Get then
        return true
    end

    local entity = Ext.Entity.Get(character)
    if not entity then
        return false
    end

    if entity.ServerCharacter and entity.ServerCharacter.OwnerPeerId ~= nil then
        if Ext.Net and Ext.Net.GetPeerId then
            return entity.ServerCharacter.OwnerPeerId == Ext.Net.GetPeerId()
        end
    end

    if entity.UserID and Ext.Net and Ext.Net.GetUserID then
        return entity.UserID == Ext.Net.GetUserID()
    end

    return true
end

local function hasCeremorph(character)
    return Osi.HasActiveStatus(character, Constants.STATUS_PARTIAL_CEREMORPH) == 1
end

local function getToggleState(character)
    return {
        normalEyes = Osi.HasActiveStatus(character, Constants.STATUS_NORMAL_EYES_ON) == 1,
        veins = Osi.HasActiveStatus(character, Constants.STATUS_VEINS_OFF) ~= 1,
    }
end

local function clearOverrides(character)
    for _, preset in ipairs(Constants.ALL_MOD_PRESETS) do
        Osi.RemoveCustomMaterialOverride(character, preset)
    end
    Osi.RemoveCustomMaterialOverride(character, Constants.VANILLA_HALF_ILLITHID)
end

local function selectPreset(state)
    if not state.normalEyes and state.veins then
        return Constants.VANILLA_HALF_ILLITHID
    end
    if state.normalEyes and state.veins then
        return Constants.PRESET_SCARS_ONLY
    end
    if not state.normalEyes and not state.veins then
        return Constants.PRESET_VANILLA_EYES_NO_VEINS
    end
    return Constants.PRESET_NORMAL_EYES_NO_VEINS
end

local function applyAppearance(character)
    character = resolveCharacter(character)
    if not character or not hasCeremorph(character) or not isLocallyOwned(character) then
        return
    end

    local preset = selectPreset(getToggleState(character))
    clearOverrides(character)
    Osi.AddCustomMaterialOverride(character, preset)
end

function AppearanceManager.RegisterListeners()
    Channels.AppearanceRefresh:Subscribe(function(payload)
        if payload and payload.character then
            applyAppearance(payload.character)
        end
    end)

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function()
        local party = Osi.DB_PartyMembers:Get(nil)
        if not party then
            return
        end

        for i = 1, #party do
            applyAppearance(party[i][1])
        end
    end)

    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, status)
        if status == Constants.STATUS_PARTIAL_CEREMORPH
            or status == Constants.STATUS_NORMAL_EYES_ON
            or status == Constants.STATUS_VEINS_OFF
            or status == Constants.STATUS_TOGGLE_NORMAL_EYES_PULSE
            or status == Constants.STATUS_TOGGLE_VEINS_PULSE then
            applyAppearance(character)
        end
    end)
end

return AppearanceManager
