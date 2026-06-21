local Constants = Ext.Require("Shared/Constants.lua")

local SpellRegistration = {}

local SHOUTS = {
    Constants.SHOUT_NORMAL_EYES,
    Constants.SHOUT_TOGGLE_VEINS,
}

local function appendSpells(spellList)
    local result = spellList or ""
    for _, shout in ipairs(SHOUTS) do
        if not result:find(shout, 1, true) then
            if result == "" then
                result = shout
            else
                result = result .. ";" .. shout
            end
        end
    end
    return result
end

function SpellRegistration.RegisterCommonSpells()
    local spellSet = Ext.Stats.Get("CommonPlayerActions")
    if not spellSet then
        _P("[NormalHalfIllithidEyes] WARNING: CommonPlayerActions spellset not found.")
        return
    end

    local updated = appendSpells(spellSet.Spells)
    if updated ~= spellSet.Spells then
        spellSet.Spells = updated
        spellSet:Sync()
        _P("[NormalHalfIllithidEyes] Registered shouts in CommonPlayerActions.")
    end
end

return SpellRegistration
