--
-- SprayerSectionControl
--
-- # author:	Rival
-- # date:		19.07.2020
-- # version:	0.2.0.0


SprayerSectionControl = {}
SprayerSectionControl.modDirectory  = g_currentModDirectory

SprayerSectionControl.HUDUVs = {
    BACKGROUND = { 992, 100, 32, 32 },
    SECTION_MID = { 710, 0, 166, 165 },
    SECTION_LEFT_1 = { 520, 105, 180, 60 },
    SECTION_LEFT_2 = { 362, 105, 153, 60 },
    SECTION_LEFT_3 = { 200, 105, 160, 60 },
    SECTION_LEFT_4 = { 12, 105, 185, 60 },
    SECTION_RIGHT_1 = { 520, 34, 180, 60 },
    SECTION_RIGHT_2 = { 362, 34, 153, 60 },
    SECTION_RIGHT_3 = { 200, 34, 160, 60 },
    SECTION_RIGHT_4 = { 12, 34, 185, 60 },
    SECTION_LEFT_SPRAY_1 = { 0, 165, 218, 90 },
    SECTION_LEFT_SPRAY_2 = { 218, 165, 190, 90 },
    SECTION_MID_SPRAY = { 410, 165, 155, 90 },
    SECTION_RIGHT_SPRAY_2 = { 566, 165, 190, 90 },
    SECTION_RIGHT_SPRAY_1 = { 756, 165, 218, 90 },
    SECTION_ONOFF = { 936, 0, 88, 88 }
}
SprayerSectionControl.COLOR = {
    RED = { 0.7, 0, 0, 1 },
    YELLOW = { 0.8, 0.5, 0, 1 },
    GREEN = { 0, 0.7, 0, 1 },
}

function SprayerSectionControl.prerequisitesPresent(specializations)
    return true
end

function SprayerSectionControl.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SprayerSectionControl) -- onDraw
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveRootVehicle", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", SprayerSectionControl)
end

function SprayerSectionControl.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSprayerArea", SprayerSectionControl.processSprayerArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", SprayerSectionControl.getSprayerUsage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SprayerSectionControl.doCheckSpeedLimit)
end

function SprayerSectionControl.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerFullWidth", SprayerSectionControl.getSprayerFullWidth)
	SpecializationUtil.registerFunction(vehicleType, "getActiveSprayerSectionsWidth", SprayerSectionControl.getActiveSprayerSectionsWidth)
	SpecializationUtil.registerFunction(vehicleType, "changeSectionState", SprayerSectionControl.changeSectionState)
	SpecializationUtil.registerFunction(vehicleType, "changeSectionGroupState", SprayerSectionControl.changeSectionGroupState)
	SpecializationUtil.registerFunction(vehicleType, "toggleAutomaticMode", SprayerSectionControl.toggleAutomaticMode)
	SpecializationUtil.registerFunction(vehicleType, "createSSCHUDElement", SprayerSectionControl.createSSCHUDElement)
	SpecializationUtil.registerFunction(vehicleType, "createTestAreas", SprayerSectionControl.createTestAreas)
end

function SprayerSectionControl:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
		if self.spec_ssc == nil then
			self.spec_ssc = {}
		else
			if not self.spec_ssc.isSSCReady then
				return
			end
		end
        local spec = self.spec_ssc
		spec.actionEvents = {}
        self:clearActionEventsTable(spec.actionEvents)

        if self:getIsActiveForInput(true, true) then																-- ..., triggerUp, triggerDown, triggerAlways, startActive
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHOW_SSC_HUD, self, SprayerSectionControl.processActionEvent, false, true, false, true)
            local _, actionEventId2 = self:addActionEvent(spec.actionEvents, InputAction.SHOW_SSC_MOUSE, self, SprayerSectionControl.processActionEvent, false, true, false, true)
        end
    end
end

function SprayerSectionControl:onLoad(savegame)
	self.spec_ssc = {}
	local spec = self.spec_ssc
	spec.sections = {}
	spec.groups = {}
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
			local testStart, testWidth, testHeight, coordinates = self:createTestAreas(workAreaId)
			local effectNodes = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, key.."#effectNodeId"))
			local workingWidth = Utils.getNoNil(getXMLFloat(self.xmlFile, key.."#workingWidth"), 3)
			
			if testStart ~= nil and testWidth ~= nil and testHeight ~= nil and effectNodes ~= nil then
				spec.sections[i] = {workAreaId=workAreaId, effectNodes=effectNodes, testAreaStart=testStart, testAreaWidth=testWidth, testAreaHeight=testHeight, active=true, workingWidth = workingWidth, direction = 1, coordinates = coordinates}
				self:getWorkAreaByIndex(workAreaId).sscId = i
				spec.sections[i].sprayType = self:getWorkAreaByIndex(workAreaId).sprayType
			else
				print("Warning: Invalid sprayer section setup '"..key.."' in '" .. self.configFileName.."'!")
			end
		end
		if hasXMLProperty(self.xmlFile, "vehicle.sprayerSectionControl.groups") then
			local j=0
			while true do
				local key = string.format("vehicle.sprayerSectionControl.groups.group(%d)", j)
				if not hasXMLProperty(self.xmlFile, key) then
					break
				end
				j = j + 1
				local sectionIds = StringUtil.splitString(" ", StringUtil.trim(getXMLString(self.xmlFile, key.."#sectionIds")))
				if sectionIds ~= nil then
					spec.groups[j] = sectionIds
				end
			end
		else
			for j=1, #spec.sections do
				spec.groups[j] = {j}
			end
		end
		for k,group in ipairs(spec.groups) do
			for _,sectionId in ipairs(group) do
				spec.sections[tonumber(sectionId)].group = k
			end
		end
		
		spec.herbicideQuery = FieldCropsQuery:new(g_currentMission.terrainDetailId)
		local desc = g_fruitTypeManager:getWeedFruitType()
		spec.herbicideQuery:addRequiredCropType(g_currentMission.fruits[desc.index].id, 1, 3, desc.startStateChannel, desc.numStateChannels, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		
		spec.fertilizerQuery = FieldCropsQuery:new(g_currentMission.terrainDetailId)
		spec.fertilizerQuery:addRequiredGroundValue(g_currentMission.cultivatorValue, g_currentMission.plowValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		spec.fertilizerQuery:addRequiredGroundValue(g_currentMission.sowingValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		spec.fertilizerQuery:addRequiredGroundValue(g_currentMission.grassValue, g_currentMission.grassValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		local fillType = self:getFillUnitLastValidFillType(self:getSprayerFillUnitIndex())
		if fillType == FillType.UNKNOWN then
			fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
		end
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
		spec.fertilizerQuery:addProhibitedGroundValue(sprayTypeDesc.groundType, sprayTypeDesc.groundType, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
		spec.fertilizerQuery:addProhibitedGroundValue(g_currentMission.sprayLevelMaxValue, g_currentMission.sprayLevelMaxValue, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
		
		spec.isAutomaticMode = true
		spec.hudActive = true
		spec.hud = {}
		
		local sections = math.min(#spec.groups, 13)
		local midSection = math.ceil(sections/2)
		local even = false
		if midSection == sections/2 then -- section count even --> no middle part in HUD
			midSection = midSection+1
			even = true
		end
		local image = SprayerSectionControl.modDirectory .. "sschud.dds"
		local uiScale = g_gameSettings.uiScale
		local hudScale = 0.33
		local wpx = SprayerSectionControl.HUDUVs.SECTION_LEFT_4[3]
		if midSection > 2 then
			wpx = wpx + SprayerSectionControl.HUDUVs.SECTION_LEFT_3[3]
		end
		if midSection > 3 then
			wpx = wpx + SprayerSectionControl.HUDUVs.SECTION_LEFT_2[3]
		end
		if midSection > 4 then
			wpx = wpx + ((midSection-4) * SprayerSectionControl.HUDUVs.SECTION_LEFT_1[3])
		end
		if even then
			wpx = 2 * wpx
			midSection = midSection-0.5
		else
			wpx = SprayerSectionControl.HUDUVs.SECTION_MID[3] + 2 * wpx
		end

		local w,h = getNormalizedScreenValues(wpx * uiScale * hudScale, 350 * uiScale * hudScale)
		local w2,h2 = getNormalizedScreenValues((wpx+80) * uiScale * hudScale, 350 * uiScale * hudScale)
		local baseX = 1-g_safeFrameOffsetX-w
		local baseY = 0.6

		spec.hud.sections = {}
		spec.hud.buttons = {}
		local lastW, lastH
		local offsetX = 0
		for j=1, sections do
			if j < midSection then
				local jj = math.max(5-j,1)
				spec.hud.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs["SECTION_LEFT_"..tostring(jj)], Overlay.ALIGN_VERTICAL_BOTTOM)
				spec.hud.sections[j]:setPosition(baseX+offsetX+lastW/2)
				spec.hud.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX+lastW/2, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs[(jj == 1 or jj == 4) and "SECTION_LEFT_SPRAY_1" or "SECTION_LEFT_SPRAY_2"], Overlay.ALIGN_VERTICAL_TOP, self.changeSectionGroupState, j)
				offsetX = offsetX + lastW
			end
			if j == midSection then
				spec.hud.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs.SECTION_MID, Overlay.ALIGN_VERTICAL_BOTTOM)
				spec.hud.sections[j]:setPosition(baseX+offsetX+lastW/2)
				spec.hud.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX+lastW/2, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs.SECTION_MID_SPRAY, Overlay.ALIGN_VERTICAL_TOP, self.changeSectionGroupState, j)
				offsetX = offsetX + lastW
			end
			if j > midSection then
				local jj = math.max(j-sections+4,1)
				spec.hud.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs["SECTION_RIGHT_"..tostring(jj)], Overlay.ALIGN_VERTICAL_BOTTOM)
				spec.hud.sections[j]:setPosition(baseX+offsetX+lastW/2)
				spec.hud.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX+lastW/2, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs[(jj == 1 or jj == 4) and "SECTION_RIGHT_SPRAY_1" or "SECTION_RIGHT_SPRAY_2"], Overlay.ALIGN_VERTICAL_TOP, self.changeSectionGroupState, j)
				offsetX = offsetX + lastW
			end
		end
		spec.hud.midSection = math.ceil(midSection)
		spec.hud.autoModeButton,_,_ = self:createSSCHUDElement(image, baseX+lastW/2, baseY+lastH, hudScale*uiScale*1.75, SprayerSectionControl.HUDUVs.SECTION_ONOFF, Overlay.ALIGN_VERTICAL_BOTTOM, self.toggleAutomaticMode)
		spec.hud.bg = Overlay:new(image, self.spec_ssc.hud.sections[spec.hud.midSection].x+(even and self.spec_ssc.hud.sections[spec.hud.midSection].offsetX or 0), baseY+h/5, w2, h)
		spec.hud.bg:setUVs(getNormalizedUVs(SprayerSectionControl.HUDUVs.BACKGROUND, { 1024, 256 }))
		spec.hud.bg:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
		spec.hud.bg:setColor(0.015, 0.015, 0.015, 0.9)
	end
end

function SprayerSectionControl:createTestAreas(workAreaId)
	local workArea = self:getWorkAreaByIndex(workAreaId)
	if workArea == nil then	
		print(string.format("Error: workArea %d not found! Could not create testArea!", workareaId))
		return
	end
	local parentNode = getParent(workArea.start)
	local x1,y1,z1 = worldToLocal(parentNode, getWorldTranslation(workArea.start))
	local x2,y2,z2 = worldToLocal(workArea.start, getWorldTranslation(workArea.width))
	local x3,y3,z3 = worldToLocal(workArea.start, getWorldTranslation(workArea.height))
	local max1 = math.max(z2,z3)
	local adjust = g_client.serverStreamId ~= 0 and 1.8 or 1
	if max1 == 0 then
		z1 = z1 + adjust
	end
	if (z2 == max1 and max1 ~= 0) then
		z2 = z2 + adjust
	elseif (max1 == 0 and z2 < max1) then
		z2 = z2 - adjust
	end
	if (z3 == max1 and max1 ~= 0) then
		z3 = z3 + adjust
	elseif (max1 == 0 and z3 < max1) then
		z3 = z3 - adjust
	end
	local testAreaStartNode = createTransformGroup(string.format("testAreaStart%d", workAreaId))
	setTranslation(testAreaStartNode, x1,y1,z1)
	link(parentNode, testAreaStartNode)
	
	local testAreaWidthNode = createTransformGroup(string.format("testAreaWidth%d", workAreaId))
	setTranslation(testAreaWidthNode, x2,y2,z2)
	link(testAreaStartNode, testAreaWidthNode)
	
	local testAreaHeightNode = createTransformGroup(string.format("testAreaHeight%d", workAreaId))
	setTranslation(testAreaHeightNode, x3,y3,z3)
	link(testAreaStartNode, testAreaHeightNode)
	
	return testAreaStartNode, testAreaWidthNode, testAreaHeightNode, {x1,y1,z1,adjust}
end

function SprayerSectionControl:createSSCHUDElement(image, x, y, hudScale, uvs, alignment, onClickCallback, sectionId)
	local w,h = getNormalizedScreenValues(uvs[3]*hudScale, uvs[4]*hudScale)
	local overlay = Overlay:new(image, x, y, w, h)
	overlay:setUVs(getNormalizedUVs(uvs, { 1024, 256 }))
	overlay:setAlignment(alignment, Overlay.ALIGN_HORIZONTAL_CENTER)
	overlay:setIsVisible(true)
	if onClickCallback ~= nil then
		overlay.onClickCallback = onClickCallback
		if sectionId ~= nil then
			overlay.sectionId = sectionId
			if self.spec_ssc.sections[sectionId].active then
				overlay:setColor(unpack(SprayerSectionControl.COLOR.YELLOW))
			else
				overlay:setColor(unpack(SprayerSectionControl.COLOR.RED))
			end
		else
			overlay:setColor(unpack(SprayerSectionControl.COLOR.GREEN))
		end
	end
	return overlay, w, h
end

function SprayerSectionControl:onUpdateTick(dt)
	if self.spec_ssc.isSSCReady then
		local spec = self.spec_ssc
		if spec.isAutomaticMode and self:getIsTurnedOn() then
			if #spec.sections > 0 then
				for k,section in pairs(spec.sections) do
					local sActive = true
					if section.sprayType ~= nil then
						local sprayType = self:getActiveSprayType()
						if sprayType ~= nil and section.sprayType ~= sprayType.index then
							sActive = false
						end
					end
					if sActive then
						if self.movingDirection == 1 and section.direction ~= 1 then -- if driving reverse, adjust testAreas to cover area behind sprayer
							setTranslation(section.testAreaStart, section.coordinates[1], section.coordinates[2], section.coordinates[3])
							section.direction = 1
						elseif self.movingDirection == 0 and section.direction ~= 0 then
							setTranslation(section.testAreaStart, section.coordinates[1], section.coordinates[2], section.coordinates[3]-section.coordinates[4]/2)
							section.direction = 0
						elseif self.movingDirection == -1 and section.direction ~= -1 then
							setTranslation(section.testAreaStart, section.coordinates[1], section.coordinates[2], section.coordinates[3]-section.coordinates[4])
							section.direction = -1
						end
						local fillType = self:getFillUnitLastValidFillType(self:getSprayerFillUnitIndex())
						if fillType == FillType.UNKNOWN then
							fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
						end
						local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
						local query = spec.fertilizerQuery
						if sprayTypeDesc ~= nil and sprayTypeDesc.isHerbicide then
							query = spec.herbicideQuery
						end
						local sx,_,sz = getWorldTranslation(section.testAreaStart)
						local wx,_,wz = getWorldTranslation(section.testAreaWidth)
						local hx,_,hz = getWorldTranslation(section.testAreaHeight)
						local area, totalArea = AIVehicleUtil.getAIFruitArea(sx, sz, wx, wz, hx, hz, query)
						local isAreaOwned = SprayerSectionControl.getIsAreaOwned(self:getActiveFarm(), sx, sz, wx, wz, hx, hz) -- check if is owned area
						local newState = area > 0 and self:getLastSpeed() > 1 and isAreaOwned
						if section.active ~= newState then
							self:changeSectionState(section, newState)
						end
					end
				end
			end
		end
	end
end

function SprayerSectionControl:onMouseEvent(posX, posY, isDown, isUp, mouseButton)
	if mouseButton == 1 then
		local eventUsed = false
		local controlledVehicle = g_currentMission.controlledVehicle
		if controlledVehicle ~= nil then
			local vehicle = controlledVehicle:getSelectedVehicle() -- workaround for non-existing self
			if vehicle ~= nil and vehicle.spec_ssc ~= nil and vehicle.spec_ssc.isSSCReady then
				if not vehicle.spec_ssc.isAutomaticMode then
					for i,button in ipairs(vehicle.spec_ssc.hud.buttons) do
						local x, y = button:getPosition()
						local cursorInElement = GuiUtils.checkOverlayOverlap(posX, posY, x+button.offsetX, y+button.offsetY, button.width, button.height)
						if not eventUsed then
							if cursorInElement then
								button.onClickCallback(vehicle, button.sectionId)
								eventUsed = true
								break
							end
						end
					end
				end
				if not eventUsed then
					local autoModeButton = vehicle.spec_ssc.hud.autoModeButton
					local cursorInElement = GuiUtils.checkOverlayOverlap(posX, posY, autoModeButton.x+autoModeButton.offsetX, autoModeButton.y+autoModeButton.offsetY, autoModeButton.width, autoModeButton.height)
					if cursorInElement then
						vehicle.spec_ssc.hud.autoModeButton.onClickCallback(vehicle)
						eventUsed = true
					end
				end
			end
		end
	end
end

function SprayerSectionControl:onUpdate()
	if not g_gui:getIsGuiVisible() and self:getIsActiveForInput(false, true) and self.spec_ssc.isSSCReady and self.spec_ssc.hudActive then
		self.spec_ssc.hud.bg:render()
		for k,hud in pairs(self.spec_ssc.hud.sections) do
			hud:render()
		end
		for k,hud in pairs(self.spec_ssc.hud.buttons) do
			hud:render()
		end
		self.spec_ssc.hud.autoModeButton:render()
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(self.spec_ssc.hud.sections[self.spec_ssc.hud.midSection].x, self.spec_ssc.hud.sections[self.spec_ssc.hud.midSection].y+self.spec_ssc.hud.sections[self.spec_ssc.hud.midSection].offsetY+self.spec_ssc.hud.sections[self.spec_ssc.hud.midSection].height*1.1, 
				   0.013*g_gameSettings.uiScale, self.spec_ssc.isAutomaticMode and g_i18n:getText("SSC_AUTOMATIC_MODE") or g_i18n:getText("SSC_MANUAL_MODE"))
	end
end

function SprayerSectionControl:toggleAutomaticMode(active)
	if active ~= nil then
		self.spec_ssc.isAutomaticMode = active
	else
		self.spec_ssc.isAutomaticMode = not self.spec_ssc.isAutomaticMode
	end
	if self.spec_ssc.isAutomaticMode then
		self.spec_ssc.hud.autoModeButton:setColor(unpack(SprayerSectionControl.COLOR.GREEN))
	else
		self.spec_ssc.hud.autoModeButton:setColor(unpack(SprayerSectionControl.COLOR.RED))
	end
end

function SprayerSectionControl:changeSectionGroupState(groupId)
	for _,sectionId in ipairs(self.spec_ssc.groups[groupId]) do
		self:changeSectionState(self.spec_ssc.sections[tonumber(sectionId)])
	end
end

function SprayerSectionControl:changeSectionState(section, newState)
	if newState == nil then
		newState = not section.active
	end
	section.active = newState
	if newState then
		if self:getIsTurnedOn() then
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
			self.spec_ssc.hud.buttons[section.group]:setColor(unpack(SprayerSectionControl.COLOR.GREEN))
		else
			self.spec_ssc.hud.buttons[section.group]:setColor(unpack(SprayerSectionControl.COLOR.YELLOW))
		end
	else
		for k2,effectNodeId in pairs(section.effectNodes) do
			--g_effectManager:stopEffect(self.spec_sprayer.effects[tonumber(effectNodeId)])
			local sprayType = self:getActiveSprayType()
			if sprayType ~= nil then
				g_effectManager:stopEffect(sprayType.effects[tonumber(effectNodeId)])
			else
				g_effectManager:stopEffect(self.spec_sprayer.effects[tonumber(effectNodeId)])
			end
		end
		self.spec_ssc.hud.buttons[section.group]:setColor(unpack(SprayerSectionControl.COLOR.RED))
	end
end

function SprayerSectionControl:onTurnedOn()
	if self.spec_ssc.isSSCReady then
		for k,section in pairs(self.spec_ssc.sections) do
			if not section.active then
				for k2,effectNodeId in pairs(section.effectNodes) do
					--[[g_effectManager:stopEffect(self.spec_sprayer.effects[tonumber(effectNodeId)])
					for _, sprayType in ipairs(self.spec_sprayer.sprayTypes) do
						g_effectManager:stopEffect(sprayType.effects[tonumber(effectNodeId)])
					end]]
					local sprayType = self:getActiveSprayType()
					if sprayType ~= nil then
						g_effectManager:stopEffect(sprayType.effects[tonumber(effectNodeId)])
					else
						g_effectManager:stopEffect(self.spec_sprayer.effects[tonumber(effectNodeId)])
					end
				end
			else
				self.spec_ssc.hud.buttons[section.group]:setColor(unpack(SprayerSectionControl.COLOR.GREEN))
			end
		end
	end
end

function SprayerSectionControl:onTurnedOff()
	if self.spec_ssc.isSSCReady then
		for k,section in pairs(self.spec_ssc.sections) do
			if section.active then
				self.spec_ssc.hud.buttons[section.group]:setColor(unpack(SprayerSectionControl.COLOR.YELLOW))
			end
		end
	end
end

function SprayerSectionControl:doCheckSpeedLimit(superFunc)
	if self.spec_ssc ~= nil and self.spec_ssc.isSSCReady then
		if self:getActiveSprayerSectionsWidth() == 0 then
			return false
		end
	end
	return superFunc(self)
end

function SprayerSectionControl:getSprayerUsage(superFunc, fillType, dt)
	local origUsage = superFunc(self, fillType, dt)
	if self.spec_ssc.isSSCReady then
		return origUsage * (self:getLastSpeed() / self.speedLimit) * (self:getActiveSprayerSectionsWidth() / self:getSprayerFullWidth())
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

function SprayerSectionControl:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if attacherVehicle.spec_enterable ~= nil and attacherVehicle.spec_enterable.cameras ~= nil then
		for _, camera in pairs(attacherVehicle.spec_enterable.cameras) do
			camera.isRotatableBk = camera.isRotatable
		end
	end
end

function SprayerSectionControl:onPreDetach(attacherVehicle, implement)
	if attacherVehicle.spec_enterable ~= nil and attacherVehicle.spec_enterable.cameras ~= nil then
		for _, camera in pairs(attacherVehicle.spec_enterable.cameras) do
			camera.allowTranslation = camera.rotateNode ~= nil and camera.rotateNode ~= camera.cameraNode
			camera.isRotatable = Utils.getNoNil(camera.isRotatableBk, true)
		end
	end
end

function SprayerSectionControl:onLeaveRootVehicle()
	local attacherVehicle = self:getRootVehicle()
	if attacherVehicle.spec_enterable ~= nil and attacherVehicle.spec_enterable.cameras ~= nil then
		for _, camera in pairs(attacherVehicle.spec_enterable.cameras) do
			camera.allowTranslation = camera.rotateNode ~= nil and camera.rotateNode ~= camera.cameraNode
			camera.isRotatable = Utils.getNoNil(camera.isRotatableBk, true)
		end
	end
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

function SprayerSectionControl.processActionEvent(self, actionName, inputValue, callbackState, isAnalog)
	if actionName == "SHOW_SSC_HUD" then
		self.spec_ssc.hudActive = not self.spec_ssc.hudActive
		if not self.spec_ssc.hudActive and g_inputBinding:getShowMouseCursor() then
			g_inputBinding:setShowMouseCursor(false)
			local rootVehicle = self:getRootVehicle()
			if rootVehicle.spec_enterable ~= nil and rootVehicle.spec_enterable.cameras ~= nil then
				for _, camera in pairs(rootVehicle.spec_enterable.cameras) do
					camera.allowTranslation = camera.rotateNode ~= nil and camera.rotateNode ~= camera.cameraNode
					camera.isRotatable = Utils.getNoNil(camera.isRotatableBk, true)
				end
			end
		end
	end
	if actionName == "SHOW_SSC_MOUSE" then
		if self.spec_ssc.hudActive then
			local show = not g_inputBinding:getShowMouseCursor()
			g_inputBinding:setShowMouseCursor(show)
			local rootVehicle = self:getRootVehicle()
			if rootVehicle.spec_enterable ~= nil and rootVehicle.spec_enterable.cameras ~= nil then
				for _, camera in pairs(self:getRootVehicle().spec_enterable.cameras) do
					camera.isRotatable = Utils.getNoNil(camera.isRotatableBk, true) and not show
					camera.allowTranslation = (camera.rotateNode ~= nil and camera.rotateNode ~= camera.cameraNode) and not show
				end
			end
		end
	end
end

function SprayerSectionControl.getIsAreaOwned(farmId, sX, sZ, wX, wZ, hX, hZ)
    local centerX, centerZ = (sX + wX)*0.5, (sZ + wZ)*0.5
    if g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, centerX, centerZ) then
        return true
    end
    if g_missionManager:getIsMissionWorkAllowed(farmId, centerX, centerZ, nil) then
        return true
    end
    return false
end
