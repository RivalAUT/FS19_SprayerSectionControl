----------------------------------------------------------------------------------------------------
-- loader
----------------------------------------------------------------------------------------------------
-- Purpose: Loads the SprayerSectionControl mod.
--
-- Copyright (c) Rival, 2020
-- Original loader script created by Wopster
----------------------------------------------------------------------------------------------------

local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("SprayerSectionControl.lua", directory))

local function validateVehicleTypes(vehicleTypeManager)
    g_specializationManager:addSpecialization("sprayerSectionControl", "SprayerSectionControl", Utils.getFilename("SprayerSectionControl.lua", directory), nil)

    for typeName, typeEntry in pairs(g_vehicleTypeManager:getVehicleTypes()) do
        if SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations) and not SpecializationUtil.hasSpecialization(SowingMachine, typeEntry.specializations) and not SpecializationUtil.hasSpecialization(Cultivator, typeEntry.specializations) then
            g_vehicleTypeManager:addSpecialization(typeName, modName .. ".sprayerSectionControl")
        end
    end
end

VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)