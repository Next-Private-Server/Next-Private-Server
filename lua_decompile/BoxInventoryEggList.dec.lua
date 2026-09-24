local BoxInventoryEggList = {
  allReqDefs = {},
  origXOffset = 0,
  eggIdsRequired = nil,
  eggIdsPossessed = nil,
  defaultTemplateToUse = ""
}
function BoxInventoryEggList:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  self.allReqDefs = {}
  return obj
end
function BoxInventoryEggList:populateEggsRequired(boxMonsterId)
  self.eggIdsRequired = game.getRequiredBoxMonsterEggs(boxMonsterId)
end
function BoxInventoryEggList:populateEggsPossessed(boxMonsterId)
  self.eggIdsPossessed = game.getEggsInInactiveBoxMonster(boxMonsterId)
end
function BoxInventoryEggList:updateAllIds(boxMonsterId)
  self:populateEggsPossessed(boxMonsterId)
  for i = 0, self.numDistinctEggs - 1 do
    self.allReqDefs[i].possessed = 0
  end
  for i = 0, self.numDistinctEggs - 1 do
    for requirementInd = 0, self.eggIdsRequired:size() - 1 do
      if self.allReqDefs[i] and self.allReqDefs[i].def:isEquiv(self.eggIdsRequired[requirementInd]) then
        self.allReqDefs[i].possessed = self.allReqDefs[i].possessed + self.eggIdsPossessed[requirementInd]
      end
    end
  end
end
function BoxInventoryEggList:buildAllIds(boxMonsterId)
  self:populateEggsPossessed(boxMonsterId)
  self.allReqDefs = {}
  local numDistinctEggs = 0
  for requirementInd = 0, self.eggIdsRequired:size() - 1 do
    local found = false
    for uiInd = 0, numDistinctEggs - 1 do
      if self.allReqDefs[uiInd] and self.allReqDefs[uiInd].def:isEquiv(self.eggIdsRequired[requirementInd]) then
        found = true
        break
      end
    end
    if not found then
      self.allReqDefs[numDistinctEggs] = {
        def = self.eggIdsRequired[requirementInd],
        required = 0,
        possessed = 0
      }
      numDistinctEggs = numDistinctEggs + 1
    end
  end
  for i = 0, numDistinctEggs - 1 do
    for requirementInd = 0, self.eggIdsRequired:size() - 1 do
      if self.allReqDefs[i] and self.allReqDefs[i].def:isEquiv(self.eggIdsRequired[requirementInd]) then
        self.allReqDefs[i].required = self.allReqDefs[i].required + 1
        self.allReqDefs[i].possessed = self.allReqDefs[i].possessed + self.eggIdsPossessed[requirementInd]
      end
    end
  end
  return numDistinctEggs
end
function BoxInventoryEggList:onInit()
  local isEggLayout = false
  if game.selectedMonsterIsZapMonster() or game.isSeasonal(game.selectedMonsterTypeId()) then
    isEggLayout = true
    self:V("isUnderling"):SetInt(1)
    defaultTemplateToUse = "template_underlinginventoryentry"
  else
    isEggLayout = false
    self:V("isUnderling"):SetInt(0)
    defaultTemplateToUse = "template_boxinventoryentry"
  end
  self:buildEntries(game.selectedMonsterId(), defaultTemplateToUse, isEggLayout)
end
function BoxInventoryEggList:buildEntries(boxMonsterId, templateToUse, isEggLayout)
  self.origXOffset = self:V("xOffset"):GetInt()
  local parentElementWidth = 0
  local parentElementHeight = 0
  local portraitWidth = 100 * game.windowScaleX()
  local portraitHeight = 85 * game.windowScaleY()
  local numPossessed = 0
  if boxMonsterId ~= 0 then
    self:populateEggsRequired(boxMonsterId)
    self.numDistinctEggs = self:buildAllIds(boxMonsterId)
    local nextRowInd = math.ceil(self.numDistinctEggs / 2)
    for i = 0, self.numDistinctEggs - 1 do
      local monsterEntry
      if not isEggLayout and self.allReqDefs[i].def:graphicIsZapMonsterSized() then
        monsterEntry = menu:addTemplateElement("template_boxinventoryentry-underling", "monsterEntry" .. i, self)
        monsterEntry:V("actualWidth"):SetInt(108 * game.windowScaleX())
      else
        monsterEntry = menu:addTemplateElement(templateToUse, "monsterEntry" .. i, self)
        monsterEntry:V("actualWidth"):SetInt(portraitWidth)
      end
      monsterEntry.flexEggDef = self.allReqDefs[i].def
      monsterEntry:V("possessed"):SetInt(self.allReqDefs[i].possessed)
      monsterEntry:V("required"):SetInt(self.allReqDefs[i].required)
      monsterEntry:V("actualHeight"):SetInt(portraitHeight)
      if i ~= 0 and i % nextRowInd == 0 then
        parentElementHeight = parentElementHeight + portraitHeight
      elseif i < nextRowInd then
        if i == 0 then
          parentElementHeight = parentElementHeight + portraitHeight
        end
        parentElementWidth = parentElementWidth + portraitWidth
      end
      local xPos = math.floor(i % nextRowInd) * portraitWidth
      local yPos = math.floor(i / nextRowInd) * portraitHeight
      monsterEntry:setParent(self)
      monsterEntry:relativeTo(self)
      monsterEntry:setOrientation(lua_sys.MenuOrientation(xPos, yPos, -1, lua_sys.HCENTER, lua_sys.VCENTER))
      monsterEntry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      monsterEntry:setOrientationPosition(lua_sys.Vector2(xPos, yPos))
      monsterEntry:setPositionBroadcast(false)
      monsterEntry:init()
      if monsterEntry:V("possessed"):GetInt() < monsterEntry:V("required"):GetInt() then
        monsterEntry:deselect()
      else
        monsterEntry:select()
        numPossessed = numPossessed + 1
      end
      i = i + 1
    end
    self:setSize(lua_sys.Vector2(parentElementWidth, parentElementHeight))
    self:setPositionBroadcast(true)
  end
  self:V("NumDistinctMonsters"):SetInt(self.numDistinctEggs)
  self.NumPossessed = numPossessed
end
function BoxInventoryEggList:updateContextBar()
  local boxMonsterId = game.selectedMonsterId()
  if boxMonsterId ~= 0 and manager and manager:getContext() == "BOX_INVENTORY_MENU" then
    if game.numEggsInInventory() < game.minNumEggsRequiredInUnderling() then
      if game.selectedMonsterIsZapMonster() then
        manager:setButtonImg("btn_powerup", "button_fill_wild")
      else
        manager:setButtonImg("btn_powerup", "button_buy_all")
      end
      manager:setButtonLabel("btn_powerup", "CONTEXTBAR_PURCHASE_BOX_FILL_LABEL")
      manager:setButtonFunction("btn_powerup", "purchase_fill_box")
      local button = manager:getButton("btn_powerup")
      if button ~= nil and button:E("attachedTemplate") ~= nil then
        button:E("attachedTemplate"):SetVisible()
      end
    elseif game.isInactiveBoxMonster(boxMonsterId) then
      if game.selectedMonsterIsZapMonster() then
        if game.isCelestialIsland() then
          manager:setButtonImg("btn_powerup", "button_revive")
          manager:setButtonLabel("btn_powerup", "WAKE_UP_CELESTIAL")
        elseif game.isAmberIsland() then
          manager:setButtonImg("btn_powerup", "button_to_nursery")
          manager:setButtonLabel("btn_powerup", "CONTEXTBAR_INCUBATE_LABEL")
        else
          manager:setButtonImg("btn_powerup", "button_wakeup")
          manager:setButtonLabel("btn_powerup", "WAKE_UP_UNDERLING")
        end
      else
        manager:setButtonImg("btn_powerup", "button_power_up")
        manager:setButtonLabel("btn_powerup", "CONTEXTBAR_POWERUP_LABEL")
      end
      manager:setButtonFunction("btn_powerup", "powerup_box")
      local button = manager:getButton("btn_powerup")
      if button ~= nil and button:E("attachedTemplate") ~= nil then
        button:E("attachedTemplate"):SetInvisible()
      end
    elseif game.selectedIsEvolvableMonsterType() then
      if game.isCelestialIsland() then
        manager:setButtonImg("btn_powerup", "button_ascension")
        manager:changeAttachedTemplate("btn_powerup", "template_lockedPowerupIndicator")
        if game.celestialEvoPowerupUnlocked() then
          manager:setButtonLabel("btn_powerup", "CONTEXTBAR_AWAKEN_LABEL")
          manager:setButtonFunction("btn_powerup", "powerup_box")
          local button = manager:getButton("btn_powerup")
          if button ~= nil and button:E("attachedTemplate") ~= nil then
            button:E("attachedTemplate"):SetInvisible()
          end
        else
          manager:setButtonLabel("btn_powerup", "UNLOCK_UNDERLING_EVOLUTION")
          manager:setButtonFunction("btn_powerup", "unlockCelestialPowerup")
          if game.selectedMonsterEarlyAwakenEnabled() then
            manager:rightShiftFrom("early_waken", true)
          end
        end
      elseif game.onGoldIsland() then
        manager:setButtonImg("btn_powerup", "button_power_up")
        manager:setButtonLabel("btn_powerup", "CONTEXTBAR_POWERUP_LABEL")
        manager:setButtonFunction("btn_powerup", "powerup_box")
        local button = manager:getButton("btn_powerup")
        if button ~= nil and button:E("attachedTemplate") ~= nil then
          button:E("attachedTemplate"):SetInvisible()
        end
      else
        local rarity = game.monsterRarity(game.selectedMonsterId())
        if rarity == game.MonsterRarity_Common then
          manager:setButtonImg("btn_powerup", "button_evolve")
        elseif rarity == game.MonsterRarity_Rare then
          manager:setButtonImg("btn_powerup", "button_evolve_rare_epic")
        end
        manager:setButtonLabel("btn_powerup", "EVOLVE_WUBLIN")
        manager:setButtonFunction("btn_powerup", "powerup_box")
        local button = manager:getButton("btn_powerup")
        if button ~= nil and button:E("attachedTemplate") ~= nil then
          button:E("attachedTemplate"):SetInvisible()
        end
      end
    end
  end
end
return BoxInventoryEggList
