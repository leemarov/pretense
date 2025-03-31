



Config = Config or {}
Config.lossCompensation = Config.lossCompensation or 1.1 -- gives advantage to the side with less zones. Set to 0 to disable
Config.randomBoost = Config.randomBoost or 0.0004 -- adds a random factor to build speeds that changes every 30 minutes, set to 0 to disable
Config.buildSpeed = Config.buildSpeed or 10 -- structure and defense build speed
Config.missionBuildSpeedReduction = Config.missionBuildSpeedReduction or 0.12 -- reduction of build speed in case of ai missions
Config.maxDistFromFront = Config.maxDistFromFront or 129640 -- max distance in meters from front after which zone is forced into low activity state (export mode)

if Config.restrictMissionAcceptance == nil then Config.restrictMissionAcceptance = true end -- if set to true, missions can only be accepted while landed inside friendly zones

Config.missions = Config.missions or {}
Config.missionBoardSize = Config.missionBoardSize or 10

Config.carrierSpawnCost = Config.carrierSpawnCost or 1000 -- resource cost for carrier when players take off, set to 0 to disable restriction
Config.zoneSpawnCost = Config.zoneSpawnCost or 1000 -- resource cost for zones when players take off, set to 0 to disable restriction
if Config.disableUnstuck == nil then Config.disableUnstuck = false end
Config.salvageChance = Config.salvageChance or 0.5
if Config.useRadio == nil then Config.useRadio = true end
Config.gciRadioTimeout = Config.gciRadioTimeout or 60
Config.gciMaxCallouts = Config.gciMaxCallouts or 3

if Config.showInventory == nil then Config.showInventory = false end -- set to true to show mission inventory on zones

Config.chillMode = false
if Config.chillMode then
    Config.buildSpeed = 8
    Config.missionBuildSpeedReduction = 0.08
    Config.restrictMissionAcceptance = false
    Config.carrierSpawnCost = 500
    Config.zoneSpawnCost = 500
end

Config.dev = false
if Config.dev then
    Config.showInventory = true
    Config.restrictMissionAcceptance = false
end

