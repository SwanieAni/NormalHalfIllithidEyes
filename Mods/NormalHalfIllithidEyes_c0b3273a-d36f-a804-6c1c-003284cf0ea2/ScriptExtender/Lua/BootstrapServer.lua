local Constants = Ext.Require("Shared/Constants.lua")
local AppearanceManager = Ext.Require("Server/AppearanceManager.lua")

local function loadStats()
    for _, path in ipairs(Constants.STAT_FILES) do
        Ext.Stats.LoadStatsFile(path, 1)
    end
end

Ext.Events.ResetCompleted:Subscribe(function()
    loadStats()
end)

loadStats()
AppearanceManager.RegisterListeners()
