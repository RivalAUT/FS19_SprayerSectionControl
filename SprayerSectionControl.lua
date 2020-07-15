--
-- SprayerSectionControl
--
-- # author:	Rival
-- # date:		15.07.2020
-- # version:	0.1.2.0


SprayerSectionControl = {}
SprayerSectionControl.modDirectory  = g_currentModDirectory

function SprayerSectionControl.prerequisitesPresent(specializations)
    return true
end

function SprayerSectionControl.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", SprayerSectionControl)
	--SpecializationUtil.registerEventListener(vehicleType, "onDraw", SprayerSectionControl)
end

function SprayerSectionControl.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSprayerArea", SprayerSectionControl.processSprayerArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", SprayerSectionControl.getSprayerUsage)
end

function SprayerSectionControl.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerFullWidth", SprayerSectionControl.getSprayerFullWidth)
	SpecializationUtil.registerFunction(vehicleType, "getActiveSprayerSectionsWidth", SprayerSectionControl.getActiveSprayerSectionsWidth)
	SpecializationUtil.registerFunction(vehicleType, "changeSectionState", SprayerSectionControl.changeSectionState)
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
			--local sprayType = getXMLInt(self.xmlFile, key.."#sprayType")
			local effectNodes = StringUtil.splitString(" ", StringUtil.trim(getXMLString(self.xmlFile, key.."#effectNodeId")))
			local testAreaStart = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#testAreaStartNode"), self.i3dMappings)
			local testAreaWidth = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#testAreaWidthNode"), self.i3dMappings)
			local testAreaHeight = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#testAreaHeightNode"), self.i3dMappings)
			local workingWidth = Utils.getNoNil(getXMLFloat(self.xmlFile, key.."#workingWidth"), 3)
			if workAreaId == nil and self.spec_workArea.workAreas[i] ~= nil then
				workAreaId = i
			end
			if workAreaId ~= nil and effectNodes ~= nil and testAreaStart ~= nil and testAreaWidth ~= nil and testAreaHeight ~= nil then
				spec.sections[i] = {workAreaId=workAreaId, effectNodes=effectNodes, testAreaStart=testAreaStart, testAreaWidth=testAreaWidth, testAreaHeight=testAreaHeight, active=true, workingWidth = workingWidth}
				self.spec_workArea.workAreas[workAreaId].sscId = i
				spec.sections[i].sprayType = self.spec_workArea.workAreas[workAreaId].sprayType
			else
				print("Warning: Invalid sprayer section setup '"..key.."' in '" .. self.configFileName.."'")
			end
		end
		spec.isAutomaticMode = true
	end
	
	self.spec_ssc = spec
end

function SprayerSectionControl:onUpdate(dt)
	if self.spec_ssc.isSSCReady then
		local spec = self.spec_ssc
		if spec.isAutomaticMode and self:getIsTurnedOn() and not self:getIsAIActive() then
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
					local sActive = true
					if section.sprayType ~= nil then
						local sprayType = self:getActiveSprayType()
						if sprayType ~= nil and section.sprayType ~= sprayType.index then
							sActive = false
						end
					end
					if sActive then
						local sx,_,sz = getWorldTranslation(section.testAreaStart)
						local wx,_,wz = getWorldTranslation(section.testAreaWidth)
						local hx,_,hz = getWorldTranslation(section.testAreaHeight)
						local area, totalArea = AIVehicleUtil.getAIFruitArea(sx, sz, wx, wz, hx, hz, self:getFieldCropsQuery())
						local newState = area > 0
						if section.active ~= newState then
							self:changeSectionState(section, newState)
						end
					end
				end
			end
		end
	end
end

function SprayerSectionControl:changeSectionState(section, newState)
	if newState == nil then
		newState = not section.active
	end
	section.active = newState
	if newState and self:getIsTurnedOn() then
		if self:getAreEffectsVisible() then
			for k2,effectNodeId in pairs(section.effectNodes) do
				local sprayType = self:getActiveSprayType()
				if sprayType ~= nil then
					g_effectManager:startEffect(sprayType.effects[tonumber(effectNodeId)])
				else
					g_effectManager:startEffect(self.spec_sprayer.effects[tonumber(effectNodeId)])
				end
			end
		end
	else
		for k2,effectNodeId in pairs(section.effectNodes) do
			g_effectManager:stopEffect(self.spec_sprayer.effects[tonumber(effectNodeId)])
			local sprayType = self:getActiveSprayType()
			if sprayType ~= nil then
				g_effectManager:stopEffect(sprayType.effects[tonumber(effectNodeId)])
			else
				g_effectManager:stopEffect(self.spec_sprayer.effects[tonumber(effectNodeId)])
			end
		end
	end
end

function SprayerSectionControl:onTurnedOn()
	if self.spec_ssc.isSSCReady then
		for k,section in pairs(self.spec_ssc.sections) do
			if not section.active then
				for k2,effectNodeId in pairs(section.effectNodes) do
					g_effectManager:stopEffect(self.spec_sprayer.effects[tonumber(effectNodeId)])
					for _, sprayType in ipairs(self.spec_sprayer.sprayTypes) do
						g_effectManager:stopEffect(sprayType.effects[tonumber(effectNodeId)])
					end
				end
			end
		end
	end
end

function SprayerSectionControl:onAIImplementStart() -- turn on every section at AI hire
	if self.spec_ssc.isSSCReady then
		for k,section in pairs(self.spec_ssc.sections) do
			self:changeSectionState(section, true)
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
		if workArea.sscId ~= nil and not self.spec_ssc.sections[workArea.sscId].active then
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
