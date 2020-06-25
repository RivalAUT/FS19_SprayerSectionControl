--
-- SprayerSectionControl
--
-- # Author:  Rival
-- # date: 24.06.2020


SprayerSectionControl = {}

function SprayerSectionControl.prerequisitesPresent(specializations)
    return true
end

function SprayerSectionControl.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SprayerSectionControl)
end

function SprayerSectionControl.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSprayerArea", SprayerSectionControl.processSprayerArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", SprayerSectionControl.getSprayerUsage)
end

function SprayerSectionControl.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerFullWidth", SprayerSectionControl.getSprayerFullWidth)
	SpecializationUtil.registerFunction(vehicleType, "getActiveSprayerSectionsWidth", SprayerSectionControl.getActiveSprayerSectionsWidth)
end


function SprayerSectionControl:onLoad(savegame)
	local spec = {}
	spec.sections = {}
	if hasXMLProperty(self.xmlFile, "vehicle.sprayerSectionControl") then
		spec.isSSCReady = true
	else
		spec.isSSCReady = false
	end
	if spec.isSSCReady then
		local i = 0
		while true do
			local key = string.format("vehicle.sprayerSectionControl.sections.section(%d)", i)
			if not hasXMLProperty(self.xmlFile, key) then
				break
			end
			i = i + 1
			local workAreaId = getXMLInt(self.xmlFile, key.."#workAreaId")
			local effectNodeId = getXMLInt(self.xmlFile, key.."#effectNodeId")
			local testAreaStart = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#testAreaStartNode"), self.i3dMappings)
			local testAreaWidth = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#testAreaWidthNode"), self.i3dMappings)
			local testAreaHeight = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#testAreaHeightNode"), self.i3dMappings)
			local workingWidth = Utils.getNoNil(getXMLFloat(self.xmlFile, key.."#workingWidth"), 2);
			if workAreaId == nil and self.spec_workArea.workAreas[i] ~= nil then
				workAreaId = i
			end
			if effectNodeId == nil and self.spec_sprayer.effects[i] ~= nil then
				effectNodeId = i
			end
			if workAreaId ~= nil and effectNodeId ~= nil and testAreaStart ~= nil and testAreaWidth ~= nil and testAreaHeight ~= nil then
				spec.sections[i] = {workAreaId=workAreaId, effectNodeId=effectNodeId, testAreaStart=testAreaStart, testAreaWidth=testAreaWidth, testAreaHeight=testAreaHeight, active=true, workingWidth = workingWidth}
				self.spec_workArea.workAreas[workAreaId].sscId = i
			else
				print("Warning: Invalid sprayer section setup '"..key.."' in '" .. self.configFileName.."'")
			end
		end
	end
	
	self.spec_ssc = spec
end

function SprayerSectionControl:onUpdate(dt)
	if self.spec_ssc.isSSCReady then
		local spec = self.spec_ssc;
		if self:getIsTurnedOn() and not self:getIsAIActive() then
			if #spec.sections > 0 then
				local fillType = self:getFillUnitLastValidFillType(self:getSprayerFillUnitIndex())
				if fillType == FillType.UNKNOWN then
					fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
				end
				local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
				if sprayTypeDesc ~= nil then
					if sprayTypeDesc.isHerbicide then
						self:setAIFruitRequirements(g_fruitTypeManager:getFruitTypeByName("weed").index, 1, 2)
					elseif sprayTypeDesc.isFertilizer then
						self:clearAITerrainDetailRequiredRange()
						self:clearAITerrainDetailProhibitedRange()
						self:addAITerrainDetailRequiredRange(g_currentMission.plowValue, g_currentMission.plowValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
						self:addAITerrainDetailRequiredRange(g_currentMission.cultivatorValue, g_currentMission.cultivatorValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
						self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
						self:addAITerrainDetailRequiredRange(g_currentMission.sowingWidthValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
						self:addAITerrainDetailRequiredRange(g_currentMission.grassValue, g_currentMission.grassValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
						self:addAITerrainDetailProhibitedRange(sprayTypeDesc.groundType, sprayTypeDesc.groundType, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
						self:addAITerrainDetailProhibitedRange(g_currentMission.sprayLevelMaxValue, g_currentMission.sprayLevelMaxValue, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
					end
				end
				for k,section in pairs(spec.sections) do
					local sx,_,sz = getWorldTranslation(section.testAreaStart)
					local wx,_,wz = getWorldTranslation(section.testAreaWidth)
					local hx,_,hz = getWorldTranslation(section.testAreaHeight)
					local area, totalArea = AIVehicleUtil.getAIFruitArea(sx, sz, wx, wz, hx, hz, self:getFieldCropsQuery())
					local newState = area > 0
					if section.active ~= newState then
						section.active = newState
						--print(string.format("Section %d was turned %s", section.workAreaId, newState and "on" or "off"))
						if newState then
							if self:getAreEffectsVisible() then
								g_effectManager:startEffect(self.spec_sprayer.effects[section.effectNodeId])
								local sprayType = self:getActiveSprayType()
								if sprayType ~= nil then
									g_effectManager:startEffect(sprayType.effects[section.effectNodeId])
								end
							end
						else
							g_effectManager:stopEffect(self.spec_sprayer.effects[section.effectNodeId])
							for _, sprayType in ipairs(self.spec_sprayer.sprayTypes) do
								g_effectManager:stopEffect(sprayType.effects[section.effectNodeId])
							end
						end
					end
				end
			end
		end
	end
end

function SprayerSectionControl:onTurnedOn()
	if self.spec_ssc.isSSCReady then
		for k,section in pairs(self.spec_ssc.sections) do
			if not section.active then
				g_effectManager:stopEffect(self.spec_sprayer.effects[section.effectNodeId])
				for _, sprayType in ipairs(self.spec_sprayer.sprayTypes) do
					g_effectManager:stopEffect(sprayType.effects[section.effectNodeId])
				end
			end
		end
	end
end

function SprayerSectionControl:getSprayerUsage(superFunc, fillType, dt)
	local origUsage = superFunc(self, fillType, dt)
	if self.spec_ssc.isSSCReady then
		return origUsage * self:getActiveSprayerSectionsWidth() / self:getSprayerFullWidth()
	else
		return origUsage
	end
end

function SprayerSectionControl:processSprayerArea(superFunc, workArea, dt)
	if self.spec_ssc.isSSCReady then
		if not self.spec_ssc.sections[workArea.sscId].active then
			return 0,0
		end
	end
	local changedArea, totalArea = superFunc(self, workArea, dt)
	return changedArea, totalArea
end

function SprayerSectionControl:getSprayerFullWidth()
	local width = 0
	for k,section in pairs(self.spec_ssc.sections) do
		width = width + section.workingWidth
	end
	return width
end

function SprayerSectionControl:getActiveSprayerSectionsWidth()
	local width = 0
	for k,section in pairs(self.spec_ssc.sections) do
		if section.active then
			width = width + section.workingWidth
		end
	end
	return width
end