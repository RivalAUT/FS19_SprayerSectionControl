----------------------------------------------------------------------------------------------------
-- loader
----------------------------------------------------------------------------------------------------
-- Purpose: Loads the SprayerSectionControl mod.
--
-- Copyright (c) Rival, 2020
-- Original loader script created by Wopster
----------------------------------------------------------------------------------------------------

SSCLoader = {};
local SSCLoader_mt = Class(SSCLoader);
addModEventListener(SSCLoader);

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

--[[function SSCLoader:loadMap()
	table.insert(g_storeManager:getItemByCustomEnvironment(modName).functions, g_i18n:getText("function_SprayerSectionControl_ready"))
end]]

function SSCLoader:mouseEvent(posX, posY, isDown, isUp, mouseKey)
	if g_currentMission.paused or g_gui.currentGui ~= nil then return end
	
	if isDown then
		SprayerSectionControl:onMouseEvent(posX, posY, isDown, isUp, mouseKey)
	end
end
