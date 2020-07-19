----------------------------------------------------------------------------------------------------
-- loader
----------------------------------------------------------------------------------------------------
-- Purpose: Loads the SprayerSectionControl mod.
--
-- Copyright (c) Wopster, 2020
----------------------------------------------------------------------------------------------------

local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("SprayerSectionControl.lua", directory))
source(Utils.getFilename("SprayerSectionControlHUD.lua", directory))

local sscHud

---Returns true when the local instance of ssc is set, false otherwise.
local function isEnabled()
    return sscHud ~= nil
end

--[[local function loadedMission(mission, node)
    if not isEnabled() then
        return
    end

    if mission.cancelLoading then
        return
    end

    sscHud:load(mission)
end]]

---Load the mod.
local function load(mission)
    assert(sscHud == nil)

    sscHud = SprayerSectionControlHUD:new(mission, g_i18n, g_inputBinding, g_gui, g_soundManager, directory, modName)

    getfenv(0)["g_sprayerSectionControlHUD"] = sscHud

    addModEventListener(sscHud)
end

local function validateVehicleTypes(vehicleTypeManager)
    g_specializationManager:addSpecialization("sprayerSectionControl", "SprayerSectionControl", Utils.getFilename("SprayerSectionControl.lua", directory), nil)

    for typeName, typeEntry in pairs(g_vehicleTypeManager:getVehicleTypes()) do
        if SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations) and not SpecializationUtil.hasSpecialization(SowingMachine, typeEntry.specializations) and not SpecializationUtil.hasSpecialization(Cultivator, typeEntry.specializations) then
            g_vehicleTypeManager:addSpecialization(typeName, modName .. ".sprayerSectionControl")
        end
    end
end

---Unload the mod when the game is closed.
local function unload()
    if not isEnabled() then
        return
    end

    if sscHud ~= nil then
        sscHud:delete()
        -- GC
        sscHud = nil
        getfenv(0)["g_sprayerSectionControlHUD"] = nil
    end
end

local function init()
    FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)

    Mission00.load = Utils.prependedFunction(Mission00.load, load)
    --Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)

    VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
end

init()
