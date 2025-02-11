import os

filelist = """GroupCorrection.lua
DependencyManager.lua
Config.lua
Utils.lua
MenuRegistry.lua
CustomZone.lua
PlayerLogistics.lua
GroupMonitor.lua
ConnectionManager.lua
TaskExtensions.lua
MarkerCommands.lua
ZoneCommand.lua
BattlefieldManager.lua
Preset.lua
PlayerTracker.lua
ReconManager.lua
MissionTargetRegistry.lua
RadioFrequencyTracker.lua
PersistenceManager.lua
TemplateDB.lua
Spawner.lua
CommandFunctions.lua
JTAC.lua
CarrierMap.lua
CarrierCommand.lua
Objectives/Objective.lua
Objectives/ObjAirKillBonus.lua
Objectives/ObjBombInsideZone.lua
Objectives/ObjClearZoneOfUnitsWithAttribute.lua
Objectives/ObjDestroyGroup.lua
Objectives/ObjDestroyStructure.lua
Objectives/ObjDestroyUnitsWithAttribute.lua
Objectives/ObjDestroyUnitsWithAttributeAtZone.lua
Objectives/ObjEscortGroup.lua
Objectives/ObjFlyToZoneSequence.lua
Objectives/ObjProtectMission.lua
Objectives/ObjReconZone.lua
Objectives/ObjSupplyZone.lua
Objectives/ObjExtractSquad.lua
Objectives/ObjExtractPilot.lua
Objectives/ObjUnloadExtractedPilotOrSquad.lua
Objectives/ObjPlayerCloseToZone.lua
Objectives/ObjDeploySquad.lua
Missions/Mission.lua
Missions/CAP_Easy.lua
Missions/CAP_Medium.lua
Missions/CAS_Easy.lua
Missions/CAS_Medium.lua
Missions/CAS_Hard.lua
Missions/SEAD.lua
Missions/DEAD.lua
Missions/Supply_Easy.lua
Missions/Supply_Hard.lua
Missions/Strike_VeryEasy.lua
Missions/Strike_Easy.lua
Missions/Strike_Medium.lua
Missions/Strike_Hard.lua
Missions/Deep_Strike.lua
Missions/Escort.lua
Missions/TARCAP.lua
Missions/Recon.lua
Missions/BAI.lua
Missions/Anti_Runway.lua
Missions/CSAR.lua
Missions/Extraction.lua
Missions/DeploySquad.lua
RewardDefinitions.lua
MissionTracker.lua
SquadTracker.lua
CSARTracker.lua
GCI.lua
Starter.lua""".splitlines()

top_comment = """ --[[
Pretense Dynamic Mission Engine
## Description:

Pretense Dynamic Mission Engine (PDME) is a the heart and soul of the Pretense missions.
You are allowed to use and modify this script for personal or private use.
Please do not share modified versions of this script.
Please do not reupload missions that use this script.
Please do not charge money for access to missions using this script.

## Links:

ED Forums Post: <https://forum.dcs.world/topic/327483-pretense-dynamic-campaign>

Pretense Manual: <https://github.com/Dzsek/pretense>

If you'd like to buy me a beer: <https://www.buymeacoffee.com/dzsek>

Makes use of Mission scripting tools (Mist): <https://github.com/mrSkortch/MissionScriptingTools>

@script PDME
@author Dzsekeb

]]-- """.splitlines()

output = [x + '\n' for x in top_comment]

lua_basedir = "lua/"
for file in filelist:
    with open(lua_basedir + file, 'r') as f:
        output.append("\n")
        output.append(f"-----------------[[ {file} ]]-----------------\n")
        lines = f.readlines()
        output += lines
        output.append(f"-----------------[[ END OF {file} ]]-----------------\n")
        output.append("\n")
        output.append("\n")

compile_path = "build/pretense_compiled.lua"
if os.path.dirname(compile_path):
    os.makedirs(os.path.dirname(compile_path), exist_ok=True)
with open(compile_path, 'w') as f:
    f.writelines(output)