
Config = Config or {}
Config.lossCompensation = Config.lossCompensation or 1.1 -- gives advantage to the side with less zones. Set to 0 to disable
Config.randomBoost = Config.randomBoost or 0.0004 -- adds a random factor to build speeds that changes every 30 minutes, set to 0 to disable
Config.buildSpeed = Config.buildSpeed or 10 -- structure and defense build speed
Config.supplyBuildSpeed = Config.supplyBuildSpeed or 85 -- supply helicopters and convoys build speed
Config.missionBuildSpeedReduction = Config.missionBuildSpeedReduction or 0.12 -- reduction of build speed in case of ai missions
Config.maxDistFromFront = Config.maxDistFromFront or 129640 -- max distance in meters from front after which zone is forced into low activity state (export mode)

if Config.restrictMissionAcceptance == nil then Config.restrictMissionAcceptance = true end -- if set to true, missions can only be accepted while landed inside friendly zones

Config.missions = Config.missions or {}
Config.missionBoardSize = Config.missionBoardSize or 15

Config.carrierSpawnCost = Config.carrierSpawnCost or 500 -- resource cost for carrier when players take off, set to 0 to disable restriction
Config.zoneSpawnCost = Config.zoneSpawnCost or 500 -- resource cost for zones when players take off, set to 0 to disable restriction

