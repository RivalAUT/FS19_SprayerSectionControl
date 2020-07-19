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

function SprayerSectionControl.prerequisitesPresent(specializations)
    return true
end

function SprayerSectionControl.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", SprayerSectionControl)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", SprayerSectionControl)
	--SpecializationUtil.registerEventListener(vehicleType, "onDraw", SprayerSectionControl)
end

function SprayerSectionControl.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSprayerArea", SprayerSectionControl.processSprayerArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", SprayerSectionControl.getSprayerUsage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeActionEvents", SprayerSectionControl.removeActionEvents)
end

function SprayerSectionControl.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerFullWidth", SprayerSectionControl.getSprayerFullWidth)
	SpecializationUtil.registerFunction(vehicleType, "getActiveSprayerSectionsWidth", SprayerSectionControl.getActiveSprayerSectionsWidth)
	SpecializationUtil.registerFunction(vehicleType, "changeSectionState", SprayerSectionControl.changeSectionState)
	SpecializationUtil.registerFunction(vehicleType, "toggleAutomaticMode", SprayerSectionControl.toggleAutomaticMode)
	--SpecializationUtil.registerFunction(vehicleType, "createSSCHUDElement", SprayerSectionControl.createSSCHUDElement)
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

        if self:getIsActiveForInput(true, true) then
            g_sprayerSectionControlHUD:setVehicle(self)																-- ..., triggerUp, triggerDown, triggerAlways, startActive
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHOW_SSC_HUD, self, SprayerSectionControl.processActionEvent, false, true, false, true)
            local _, actionEventId2 = self:addActionEvent(spec.actionEvents, InputAction.SHOW_SSC_MOUSE, self, SprayerSectionControl.processActionEvent, false, true, false, true)
        end
    end
end

function SprayerSectionControl:removeActionEvents(superFunc, ...)
    local hud = g_sprayerSectionControlHUD
    if hud ~= nil and hud:isVehicleActive(self) then
        hud:setVehicle(nil)
    end

    return superFunc(self, ...)
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
				spec.sections[i] = {workAreaId=workAreaId, effectNodes=effectNodes, testAreaStart=testAreaStart, testAreaWidth=testAreaWidth, testAreaHeight=testAreaHeight, active=true, workingWidth = workingWidth, id=i}
				self.spec_workArea.workAreas[workAreaId].sscId = i
				spec.sections[i].sprayType = self.spec_workArea.workAreas[workAreaId].sprayType
			else
				print("Warning: Invalid sprayer section setup '"..key.."' in '" .. self.configFileName.."'")
			end
		end
		spec.isAutomaticMode = true
		spec.hudActive = true
		
		--sectioncount --> i
		--[[i = math.min(i, 13)
		local midSection = math.ceil(i/2)
		
		spec.hud = {}
		local image = SprayerSectionControl.modDirectory .. "sschud.dds"
		local uiScale = g_gameSettings.uiScale
		local hudScale = 0.5
		local w,h = getNormalizedScreenValues(i * 180 * uiScale * hudScale, 400 * uiScale * hudScale)
		local baseX = 1-g_safeFrameOffsetX-w
		local baseY = 0.6
		
		--spec.hud.buttonMid = self:createSSCHUDElement(image, baseX, baseY, w, h, SprayerSectionControl.HUDUVs.SECTION_MID_SPRAY, SprayerSectionControl.changeSectionState, midSection)
		
		spec.hud.sections = {}
		spec.hud.buttons = {}
		local lastW, lastH
		local offsetX = 0
		for j=1, i do
			if j < midSection then
				local jj = math.min(midSection-j,4)
				spec.hud.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs["SECTION_LEFT_"..tostring(jj)], Overlay.ALIGN_VERTICAL_BOTTOM)
				spec.hud.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs[(jj == 1 or jj == 4) and "SECTION_LEFT_SPRAY_1" or "SECTION_LEFT_SPRAY_2"], Overlay.ALIGN_VERTICAL_TOP, SprayerSectionControl.changeSectionState, j)
				offsetX = offsetX + lastW
			end
			if j == midSection then
				spec.hud.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs.SECTION_MID, Overlay.ALIGN_VERTICAL_BOTTOM)
				spec.hud.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs[(jj == 1 or jj == 4) and "SECTION_RIGHT_SPRAY_1" or "SECTION_RIGHT_SPRAY_2"], Overlay.ALIGN_VERTICAL_TOP, SprayerSectionControl.changeSectionState, j)
				offsetX = offsetX + lastW
			end
			if j > midSection then
				local jj = math.min(j-midSection,4)
				spec.hud.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs["SECTION_RIGHT_"..tostring(jj)], Overlay.ALIGN_VERTICAL_BOTTOM)
				spec.hud.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControl.HUDUVs[(jj == 1 or jj == 4) and "SECTION_RIGHT_SPRAY_1" or "SECTION_RIGHT_SPRAY_2"], Overlay.ALIGN_VERTICAL_TOP, SprayerSectionControl.changeSectionState, j)
				offsetX = offsetX + lastW
			end
		end
		spec.hud.bg = Overlay:new(image, 1-g_safeFrameOffsetX, baseY, w, h)
		spec.hud.bg:setUVs(getNormalizedUVs(SprayerSectionControl.HUDUVs.BACKGROUND, { 1024, 256 }))
		spec.hud.bg:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
		spec.hud.bg:setColor(0.015, 0.015, 0.015, 0.8)]]
	end
	
	self.spec_ssc = spec
end

function SprayerSectionControl:onPostLoad(savegame)
	if g_client.serverStreamId ~= 0 then --g_currentMission.connectedToDedicatedServer
		local spec = self.spec_ssc -- multiplayer --> adjust testAreas
		if spec.isSSCReady then
			print("adjusting section testAreas for online usage")
			for k,section in pairs(spec.sections) do
				local x, y, z = getTranslation(section.testAreaStart)
				setTranslation(section.testAreaStart, x, y, z+0.8)
				x, y, z = getTranslation(section.testAreaWidth)
				setTranslation(section.testAreaWidth, x, y, z+0.8)
			end
		end
	end
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
						local newState = area > 0 and self:getLastSpeed() > 1
						if section.active ~= newState then
							self:changeSectionState(section, newState)
						end
					end
				end
			end
		end
	end
end

--[[function SprayerSectionControl:mouseEventSSC(posX, posY, isDown, isUp, mousebutton)
	print("mouseEvent")
	if self.spec_ssc.isSSCReady then
		for i,button in self.spec_ssc.hud.buttons do
			if button:isActive() and button:getIsVisible() then
				local x, y = button:getPosition()
				local cursorInElement = GuiUtils.checkOverlayOverlap(posX, posY, x, y, button:getWidth(), button:getHeight())

				-- handle click/activate only if event has not been consumed, yet
				if not eventUsed then
					if cursorInElement then --and not FocusManager:isLocked() then
						if isDown and mousebutton == Input.MOUSE_BUTTON_LEFT then
							eventUsed = true
							button.mouseDown = true
						end

						if isUp and mousebutton == Input.MOUSE_BUTTON_LEFT and button.mouseDown then
							--g_gui.soundPlayer:playSample(self.clickSoundName)

							button.mouseDown = false
							button:raiseCallback("onClickCallback", button.section)
							--button:onClickCallback(button.section)

							eventUsed = true
						end
					end
				end
			end
		end
	end
end
]]
--FSBaseMission.mouseEvent = Utils.appendedFunction(FSBaseMission.mouseEvent, SprayerSectionControl.mouseEventSSC)

--[[function SprayerSectionControl:createSSCHUDElement(image, x, y, hudScale, uvs, alignment, onClickCallback, sectionId)
	local w,h = getNormalizedScreenValues(uvs[3]*hudScale, uvs[4]*hudScale)
	local overlay = Overlay:new(image, x, y, w, h)
	overlay:setUVs(getNormalizedUVs(uvs, { 1024, 256 }))
	overlay:setAlignment(alignment, Overlay.ALIGN_HORIZONTAL_CENTER)
	overlay:setIsVisible(true)
	if onClickCallback ~= nil then
		overlay.mouseDown = false
		overlay.onClickCallback = onClickCallback
		overlay.sectionId = sectionId
	end
	return overlay, w, h
end]]

function SprayerSectionControl:toggleAutomaticMode(active)
	if active ~= nil then
		self.spec_ssc.isAutomaticMode = active
	else
		self.spec_ssc.isAutomaticMode = not self.spec_ssc.isAutomaticMode
	end
	if self.spec_ssc.isAutomaticMode then
		g_sprayerSectionControlHUD.autoModeButton:setColor(unpack(g_sprayerSectionControlHUD.COLOR.GREEN))
	else
		g_sprayerSectionControlHUD.autoModeButton:setColor(unpack(g_sprayerSectionControlHUD.COLOR.RED))
	end
end

function SprayerSectionControl:changeSectionState(section, newState)
	if newState == nil then
		newState = not section.active
	end
	--print(string.format("Changed section %d state to %s", section.workAreaId, newState and "true" or "false"))
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
			g_sprayerSectionControlHUD.buttons[section.id]:setColor(unpack(g_sprayerSectionControlHUD.COLOR.GREEN))
		else
			g_sprayerSectionControlHUD.buttons[section.id]:setColor(unpack(g_sprayerSectionControlHUD.COLOR.YELLOW))
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
		g_sprayerSectionControlHUD.buttons[section.id]:setColor(unpack(g_sprayerSectionControlHUD.COLOR.RED))
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
			else
				g_sprayerSectionControlHUD.buttons[section.id]:setColor(unpack(g_sprayerSectionControlHUD.COLOR.GREEN))
			end
		end
	end
end

function SprayerSectionControl:onTurnedOff()
	if self.spec_ssc.isSSCReady then
		for k,section in pairs(self.spec_ssc.sections) do
			if section.active then
				g_sprayerSectionControlHUD.buttons[section.id]:setColor(unpack(g_sprayerSectionControlHUD.COLOR.YELLOW))
			end
		end
	end
end

--[[function SprayerSectionControl:onDraw()
	if self.spec_ssc.isSSCReady then
		local spec = self.spec_ssc
		spec.hud.bg:render()
		for k,hud in pairs(spec.hud.sections) do
			hud:render()
		end
		for k,hud in pairs(spec.hud.buttons) do
			hud:render()
		end
	end
end]]

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

function SprayerSectionControl.processActionEvent(self, actionName, inputValue, callbackState, isAnalog)
	if actionName == "SHOW_SSC_HUD" then
		g_sprayerSectionControlHUD.hudActive = not g_sprayerSectionControlHUD.hudActive
	end
	if actionName == "SHOW_SSC_MOUSE" then
		if g_sprayerSectionControlHUD.hudActive then
			g_sprayerSectionControlHUD:toggleMouseCursor()
		end
	end
end
