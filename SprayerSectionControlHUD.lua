--
-- SprayerSectionControlHUD
--
-- # author:	Rival
-- # date:		19.07.2020
-- # version:	0.2.0.0


SprayerSectionControlHUD = {}
SprayerSectionControlHUD.modDirectory = g_currentModDirectory

local SprayerSectionControlHUD_mt = Class(SprayerSectionControlHUD)

SprayerSectionControlHUD.UVs = {
    BACKGROUND = { 992, 100, 32, 32 },
    SECTION_MID = { 712, 0, 162, 165 },
    SECTION_LEFT_1 = { 520, 105, 179, 60 },
    SECTION_LEFT_2 = { 362, 105, 153, 60 },
    SECTION_LEFT_3 = { 202, 105, 154, 60 },
    SECTION_LEFT_4 = { 12, 105, 185, 60 },
    SECTION_RIGHT_1 = { 520, 34, 179, 60 },
    SECTION_RIGHT_2 = { 362, 34, 153, 60 },
    SECTION_RIGHT_3 = { 202, 34, 154, 60 },
    SECTION_RIGHT_4 = { 12, 34, 185, 60 },
    SECTION_LEFT_SPRAY_1 = { 0, 165, 218, 90 },
    SECTION_LEFT_SPRAY_2 = { 218, 165, 190, 90 },
    SECTION_MID_SPRAY = { 410, 165, 155, 90 },
    SECTION_RIGHT_SPRAY_2 = { 566, 165, 190, 90 },
    SECTION_RIGHT_SPRAY_1 = { 756, 165, 218, 90 },
    SECTION_ONOFF = { 936, 0, 88, 88 }
}
SprayerSectionControlHUD.COLOR = {
    RED = { 0.7, 0, 0, 1 },
    YELLOW = { 0.8, 0.5, 0, 1 },
    GREEN = { 0, 0.7, 0, 1 },
}

function SprayerSectionControlHUD:new(mission, i18n, inputBinding, gui, modDirectory, uiFilename)
    local self = setmetatable({}, SprayerSectionControlHUD_mt)
    self.mission = mission
    self.gui = gui
    self.inputBinding = inputBinding
    self.i18n = i18n
    self.modDirectory = modDirectory
    self.uiFilename = uiFilename
    self.atlasRefSize = { 1024, 128 }

    self.speedMeterDisplay = mission.hud.speedMeter
	
    self.vehicle = nil
	
	self.hudActive = true
	return self
end

function SprayerSectionControlHUD:setVehicle(vehicle)
    self.vehicle = vehicle
	if vehicle ~= nil and vehicle.spec_ssc.isSSCReady then
		local sections = math.min(#vehicle.spec_ssc.sections, 13)
		local midSection = math.ceil(sections/2)
		local image = SprayerSectionControlHUD.modDirectory .. "sschud.dds"
		local uiScale = g_gameSettings.uiScale
		local hudScale = 0.33
		local wpx = SprayerSectionControlHUD.UVs.SECTION_LEFT_4[3]
		if midSection > 2 then
			wpx = wpx + SprayerSectionControlHUD.UVs.SECTION_LEFT_3[3]
		end
		if midSection > 3 then
			wpx = wpx + SprayerSectionControlHUD.UVs.SECTION_LEFT_2[3]
		end
		if midSection > 4 then
			wpx = wpx + ((midSection-4) * SprayerSectionControlHUD.UVs.SECTION_LEFT_1[3])
		end
		wpx = SprayerSectionControlHUD.UVs.SECTION_MID[3] + 2 * wpx
			
			
		local w,h = getNormalizedScreenValues(wpx * uiScale * hudScale, 350 * uiScale * hudScale)
		local w2,h2 = getNormalizedScreenValues((wpx+80) * uiScale * hudScale, 350 * uiScale * hudScale)
		local baseX = 1-g_safeFrameOffsetX-w
		local baseY = 0.6
		
		self.midSection = midSection
		self.sections = {}
		self.buttons = {}
		local lastW, lastH
		local offsetX = 0
		for j=1, sections do
			if j < midSection then
				local jj = math.min(midSection-j,4)
				self.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControlHUD.UVs["SECTION_LEFT_"..tostring(jj)], Overlay.ALIGN_VERTICAL_BOTTOM)
				self.sections[j]:setPosition(baseX+offsetX+lastW/2)
				self.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX+lastW/2, baseY, hudScale*uiScale, SprayerSectionControlHUD.UVs[(jj == 1 or jj == 4) and "SECTION_LEFT_SPRAY_1" or "SECTION_LEFT_SPRAY_2"], Overlay.ALIGN_VERTICAL_TOP, self.changeSectionStateHUD, j)
				offsetX = offsetX + lastW
			end
			if j == midSection then
				self.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControlHUD.UVs.SECTION_MID, Overlay.ALIGN_VERTICAL_BOTTOM)
				self.sections[j]:setPosition(baseX+offsetX+lastW/2)
				self.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX+lastW/2, baseY, hudScale*uiScale, SprayerSectionControlHUD.UVs[(jj == 1 or jj == 4) and "SECTION_RIGHT_SPRAY_1" or "SECTION_RIGHT_SPRAY_2"], Overlay.ALIGN_VERTICAL_TOP, self.changeSectionStateHUD, j)
				offsetX = offsetX + lastW
			end
			if j > midSection then
				local jj = math.min(j-midSection,4)
				self.sections[j], lastW, lastH = self:createSSCHUDElement(image, baseX+offsetX, baseY, hudScale*uiScale, SprayerSectionControlHUD.UVs["SECTION_RIGHT_"..tostring(jj)], Overlay.ALIGN_VERTICAL_BOTTOM)
				self.sections[j]:setPosition(baseX+offsetX+lastW/2)
				self.buttons[j],_,_ = self:createSSCHUDElement(image, baseX+offsetX+lastW/2, baseY, hudScale*uiScale, SprayerSectionControlHUD.UVs[(jj == 1 or jj == 4) and "SECTION_RIGHT_SPRAY_1" or "SECTION_RIGHT_SPRAY_2"], Overlay.ALIGN_VERTICAL_TOP, self.changeSectionStateHUD, j)
				offsetX = offsetX + lastW
			end
		end
		self.autoModeButton,_,_ = self:createSSCHUDElement(image, baseX+lastW/2, baseY+lastH, hudScale*uiScale*1.75, SprayerSectionControlHUD.UVs.SECTION_ONOFF, Overlay.ALIGN_VERTICAL_BOTTOM, self.toggleAutomaticModeHUD)
		self.bg = Overlay:new(image, self.sections[midSection].x, baseY+h/5, w2, h)
		self.bg:setUVs(getNormalizedUVs(SprayerSectionControlHUD.UVs.BACKGROUND, { 1024, 256 }))
		self.bg:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
		self.bg:setColor(0.015, 0.015, 0.015, 0.9)
	end
end

function SprayerSectionControlHUD:isVehicleActive(vehicle)
    return vehicle == self.vehicle
end

function SprayerSectionControlHUD:delete()
	
end

function SprayerSectionControlHUD:changeSectionStateHUD(sectionId)
	--print("change section state "..tostring(sectionId))
	if self.vehicle ~= nil then
		self.vehicle:changeSectionState(self.vehicle.spec_ssc.sections[sectionId])
	end
end

function SprayerSectionControlHUD:toggleAutomaticModeHUD()
	if self.vehicle ~= nil then
		self.vehicle:toggleAutomaticMode()
	end
end

function SprayerSectionControlHUD:mouseEvent(posX, posY, isDown, isUp, mousebutton)
	if self.hudActive and self.vehicle ~= nil and self.vehicle.spec_ssc.isSSCReady and self.inputBinding:getShowMouseCursor() then
		local eventUsed = false
		if not self.vehicle.spec_ssc.isAutomaticMode then
			for i,button in ipairs(self.buttons) do
				if button.visible then
					local x, y = button:getPosition()
					local cursorInElement = GuiUtils.checkOverlayOverlap(posX, posY, x+button.offsetX, y+button.offsetY, button.width, button.height)
					-- handle click/activate only if event has not been consumed, yet
					if not eventUsed then
						if cursorInElement then
							if isDown and mousebutton == Input.MOUSE_BUTTON_LEFT then
								eventUsed = true
								button.mouseDown = true
							end
							if isUp and mousebutton == Input.MOUSE_BUTTON_LEFT and button.mouseDown then
								button.mouseDown = false
								button.onClickCallback(self, button.sectionId)
								eventUsed = true
							end
						end
					end
				end
			end
		end
		if not eventUsed then
			local cursorInElement = GuiUtils.checkOverlayOverlap(posX, posY, self.autoModeButton.x+self.autoModeButton.offsetX, self.autoModeButton.y+self.autoModeButton.offsetY, self.autoModeButton.width, self.autoModeButton.height)
			if cursorInElement then
				if isDown and mousebutton == Input.MOUSE_BUTTON_LEFT then
					eventUsed = true
					self.autoModeButton.mouseDown = true
				end
				if isUp and mousebutton == Input.MOUSE_BUTTON_LEFT and self.autoModeButton.mouseDown then
					self.autoModeButton.mouseDown = false
					self.autoModeButton.onClickCallback(self)
					eventUsed = true
				end
			end
		end
	end
end

function SprayerSectionControlHUD:createSSCHUDElement(image, x, y, hudScale, uvs, alignment, onClickCallback, sectionId)
	local w,h = getNormalizedScreenValues(uvs[3]*hudScale, uvs[4]*hudScale)
	local overlay = Overlay:new(image, x, y, w, h)
	overlay:setUVs(getNormalizedUVs(uvs, { 1024, 256 }))
	overlay:setAlignment(alignment, Overlay.ALIGN_HORIZONTAL_CENTER)
	overlay:setIsVisible(true)
	if onClickCallback ~= nil then
		overlay.mouseDown = false
		overlay.onClickCallback = onClickCallback
		if sectionId ~= nil then
			overlay.sectionId = sectionId
			if self.vehicle.spec_ssc.sections[sectionId].active then
				if self.vehicle:getIsTurnedOn() then
					overlay:setColor(unpack(SprayerSectionControlHUD.COLOR.GREEN))
				else
					overlay:setColor(unpack(SprayerSectionControlHUD.COLOR.YELLOW))
				end
			else
				overlay:setColor(unpack(SprayerSectionControlHUD.COLOR.RED))
			end
		else
			overlay:setColor(unpack(SprayerSectionControlHUD.COLOR.GREEN))
		end
	end
	return overlay, w, h
end

function SprayerSectionControlHUD:draw()
	if self.hudActive and self.vehicle ~= nil and self.vehicle.spec_ssc.isSSCReady then
		self.bg:render()
		for k,hud in pairs(self.sections) do
			hud:render()
		end
		for k,hud in pairs(self.buttons) do
			hud:render()
		end
		self.autoModeButton:render()
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(self.sections[self.midSection].x, self.sections[self.midSection].y+self.sections[self.midSection].offsetY+self.sections[self.midSection].height*1.1, 0.013*g_gameSettings.uiScale, 
				   self.vehicle.spec_ssc.isAutomaticMode and g_i18n:getText("SSC_AUTOMATIC_MODE") or g_i18n:getText("SSC_MANUAL_MODE"))
	end
end

function SprayerSectionControlHUD:toggleMouseCursor()
    local isActive = not self.inputBinding:getShowMouseCursor()
    if not self.isCustomInputActive and self.inputBinding:getShowMouseCursor() then
        self.inputBinding:setShowMouseCursor(false)-- always reset
        isActive = false
    end

    self.inputBinding:setShowMouseCursor(isActive)

    if not self.isCustomInputActive and isActive then
        self.inputBinding:setContext("SSC_HUD", true, false)

        local _, eventId = self.inputBinding:registerActionEvent(InputAction.SHOW_SSC_MOUSE, self, self.toggleMouseCursor, false, true, false, true)
        self.inputBinding:setActionEventTextVisibility(eventId, false)

        self.isCustomInputActive = true
    elseif self.isCustomInputActive and not isActive then
        self.inputBinding:removeActionEventsByTarget(self)
        self.inputBinding:revertContext(true) -- revert and clear message context
        self.isCustomInputActive = false
    end

    --Make compatible with IC.
    if self.vehicle ~= nil then
        self.vehicle.isMouseActive = isActive
        local rootVehicle = self.vehicle:getRootVehicle()
        rootVehicle.isMouseActive = isActive
    end
end
