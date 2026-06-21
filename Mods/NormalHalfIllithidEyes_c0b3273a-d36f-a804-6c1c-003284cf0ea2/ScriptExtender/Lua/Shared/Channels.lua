local Constants = Ext.Require("Shared/Constants.lua")

local Channels = {}
Channels.AppearanceRefresh = Ext.Net.CreateChannel(Constants.MOD_UUID, "AppearanceRefresh")

return Channels
