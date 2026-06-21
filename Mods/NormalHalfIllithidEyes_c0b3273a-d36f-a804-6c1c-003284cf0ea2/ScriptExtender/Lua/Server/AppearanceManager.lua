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

function AppearanceManager.ApplyAppearance(character)
    character = resolveCharacter(character)
    if not character or not hasCeremorph(character) then
        return
    end

    local state = getToggleState(character)
    local preset = selectPreset(state)

    clearOverrides(character)
    Osi.AddCustomMaterialOverride(character, preset)

    Channels.AppearanceRefresh:Broadcast({ character = character })
end

local function grantSpellbookSpells(character)
    character = resolveCharacter(character)
    if not character or not hasCeremorph(character) then
        return
    end

    if Osi.HasPassive(character, Constants.PASSIVE_WATCHER) ~= 1 then
        Osi.AddPassive(character, Constants.PASSIVE_WATCHER)
    end

    if Osi.HasSpell(character, Constants.SHOUT_NORMAL_EYES) ~= 1 then
        Osi.AddSpell(character, Constants.SHOUT_NORMAL_EYES, 0, 0)
    end
    if Osi.HasSpell(character, Constants.SHOUT_TOGGLE_VEINS) ~= 1 then
        Osi.AddSpell(character, Constants.SHOUT_TOGGLE_VEINS, 0, 0)
    end
end

local function cleanupCharacter(character)
    character = resolveCharacter(character)
    if not character then
        return
    end

    Osi.RemoveStatus(character, Constants.STATUS_NORMAL_EYES_ON, character)
    Osi.RemoveStatus(character, Constants.STATUS_VEINS_OFF, character)
    Osi.RemoveStatus(character, Constants.STATUS_TOGGLE_NORMAL_EYES_PULSE, character)
    Osi.RemoveStatus(character, Constants.STATUS_TOGGLE_VEINS_PULSE, character)
    Osi.RemovePassive(character, Constants.PASSIVE_WATCHER)
    clearOverrides(character)
end

local function handleTogglePulse(character, pulseStatus, onStatus)
    character = resolveCharacter(character)
    if not character or not hasCeremorph(character) then
        return
    end

    Osi.RemoveStatus(character, pulseStatus, character)

    if Osi.HasActiveStatus(character, onStatus) == 1 then
        Osi.RemoveStatus(character, onStatus, character)
    else
        Osi.ApplyStatus(character, onStatus, -1, 1, character)
    end

    AppearanceManager.ApplyAppearance(character)
end

local function refreshParty()
    local party = Osi.DB_PartyMembers:Get(nil)
    if not party then
        return
    end

    for i = 1, #party do
        local member = resolveCharacter(party[i][1])
        if member and hasCeremorph(member) then
            grantSpellbookSpells(member)
            AppearanceManager.ApplyAppearance(member)
        end
    end
end

function AppearanceManager.RegisterListeners()
    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function()
        refreshParty()
    end)

    Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character)
        if hasCeremorph(resolveCharacter(character)) then
            grantSpellbookSpells(character)
            AppearanceManager.ApplyAppearance(character)
        end
    end)

    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, status)
        character = resolveCharacter(character)
        if not character then
            return
        end

        if status == Constants.STATUS_PARTIAL_CEREMORPH then
            grantSpellbookSpells(character)
            AppearanceManager.ApplyAppearance(character)
            return
        end

        if status == Constants.STATUS_TOGGLE_NORMAL_EYES_PULSE then
            handleTogglePulse(character, Constants.STATUS_TOGGLE_NORMAL_EYES_PULSE, Constants.STATUS_NORMAL_EYES_ON)
            return
        end

        if status == Constants.STATUS_TOGGLE_VEINS_PULSE then
            handleTogglePulse(character, Constants.STATUS_TOGGLE_VEINS_PULSE, Constants.STATUS_VEINS_OFF)
            return
        end
    end)

    Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(character, status)
        if status ~= Constants.STATUS_PARTIAL_CEREMORPH then
            return
        end
        cleanupCharacter(character)
    end)
end

return AppearanceManager
