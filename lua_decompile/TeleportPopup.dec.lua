local TeleportPopup = {
  FadedBG = {
    Sprite = {},
    Touch = {}
  },
  bg = {
    Sprite = {}
  },
  Notification = {
    Text = {}
  },
  TeleportBattleIslandButton = {},
  TeleportHomeIslandButton = {},
  transitionState = 1,
  transitionTime = 0,
  uniqueMonsterId = 0
}
function TeleportPopup:onPostInit()
  self.transitionTime = 0
  self.transitionState = 1
  self.uniqueMonsterId = game.selectedMonsterId()
  local isEthereal = game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_ETHEREAL) and game.currentIslandType()
  local isSeasonal = game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_SEASONAL)
  local isMythic = game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_MYTHICAL)
  local isPlasmaEtherealIslet = game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_PLASMA_ETHEREAL_ISLET)
  local isMechEtherealIslet = game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_MECH_ETHEREAL_ISLET)
  local isShadowEtherealIslet = game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_SHADOW_ETHEREAL_ISLET)
  local isCrystalEtherealIslet = game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_CRYSTAL_ETHEREAL_ISLET)
  local isEtherealIslet = isPlasmaEtherealIslet or isMechEtherealIslet or isShadowEtherealIslet or isCrystalEtherealIslet
  local isShuga = game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_SHUGGA)
  local buttonsVisible = 0
  if isEthereal and not game.isEtherealIsland() then
    local id = game.etherealIslandId()
    self.TeleportHomeIslandButton.Overlay("spriteName"):SetString(game.islandIconSpriteForId(id))
    self.TeleportHomeIslandButton.Overlay("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(id))
    self.TeleportHomeIslandButton.Text("text"):SetString(game.islandName(id))
    buttonsVisible = buttonsVisible + 1
    local neededLevel = game.goldMonsterLevel()
    if neededLevel > game.monsterLevel(self.uniqueMonsterId) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local unlockText = game.getLocalizedText("UNLOCKED_AT_LEVEL")
      unlockText = select(1, unlockText:gsub("XXX", neededLevel))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(unlockText)
    end
  elseif not game.isEtherealIsland() and game.isTeleportableTo(self.uniqueMonsterId, game.IslandType_MAGICAL_SANCTUM) then
    local id = game.magicalEtherealIslandId()
    self.TeleportHomeIslandButton.Overlay("spriteName"):SetString(game.islandIconSpriteForId(id))
    self.TeleportHomeIslandButton.Overlay("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(id))
    self.TeleportHomeIslandButton.Text("text"):SetString(game.islandName(id))
    buttonsVisible = buttonsVisible + 1
    local neededLevel = game.goldMonsterLevel()
    if neededLevel > game.monsterLevel(self.uniqueMonsterId) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local unlockText = game.getLocalizedText("UNLOCKED_AT_LEVEL")
      unlockText = select(1, unlockText:gsub("XXX", neededLevel))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(unlockText)
    end
  elseif isShuga and not game.isLegendaryShuggaIsland() then
    local id = game.shugaIslandId()
    self.TeleportHomeIslandButton.Overlay("spriteName"):SetString(game.islandIconSpriteForId(id))
    self.TeleportHomeIslandButton.Overlay("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(id))
    self.TeleportHomeIslandButton.Text("text"):SetString(game.islandName(id))
    buttonsVisible = buttonsVisible + 1
    local neededLevel = game.goldMonsterLevel()
    if neededLevel > game.monsterLevel(self.uniqueMonsterId) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local unlockText = game.getLocalizedText("UNLOCKED_AT_LEVEL")
      unlockText = select(1, unlockText:gsub("XXX", neededLevel))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(unlockText)
    elseif not game.isIslandOwned(game.islandLockIsland(id)) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local requirementText = game.getLocalizedText("NOTIFICATION_REQUIRES_ITEM")
      requirementText = select(1, requirementText:gsub("XXX", game.getLocalizedText(game.islandName(game.islandLockIsland(id)))))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(requirementText)
    end
  elseif isSeasonal and not game.isSeasonalIsland() then
    local id = game.seasonalIslandId()
    self.TeleportHomeIslandButton.Overlay("spriteName"):SetString(game.islandIconSpriteForId(id))
    self.TeleportHomeIslandButton.Overlay("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(id))
    self.TeleportHomeIslandButton.Text("text"):SetString(game.islandName(id))
    buttonsVisible = buttonsVisible + 1
    local neededLevel = game.goldMonsterLevel()
    if neededLevel > game.monsterLevel(self.uniqueMonsterId) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local unlockText = game.getLocalizedText("UNLOCKED_AT_LEVEL")
      unlockText = select(1, unlockText:gsub("XXX", neededLevel))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(unlockText)
    elseif not game.isIslandOwned(game.islandLockIsland(id)) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local requirementText = game.getLocalizedText("NOTIFICATION_REQUIRES_ITEM")
      requirementText = select(1, requirementText:gsub("XXX", game.getLocalizedText(game.islandName(game.islandLockIsland(id)))))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(requirementText)
    end
  elseif isMythic and not game.isMythicalIsland() then
    local id = game.mythicalIslandId()
    self.TeleportHomeIslandButton.Overlay("spriteName"):SetString(game.islandIconSpriteForId(id))
    self.TeleportHomeIslandButton.Overlay("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(id))
    self.TeleportHomeIslandButton.Text("text"):SetString(game.islandName(id))
    buttonsVisible = buttonsVisible + 1
    local neededLevel = game.goldMonsterLevel()
    if neededLevel > game.monsterLevel(self.uniqueMonsterId) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local unlockText = game.getLocalizedText("UNLOCKED_AT_LEVEL")
      unlockText = select(1, unlockText:gsub("XXX", neededLevel))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(unlockText)
    elseif not game.isIslandOwned(game.islandLockIsland(id)) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local requirementText = game.getLocalizedText("NOTIFICATION_REQUIRES_ITEM")
      requirementText = select(1, requirementText:gsub("XXX", game.getLocalizedText(game.islandName(game.islandLockIsland(id)))))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(requirementText)
    end
  elseif isEtherealIslet then
    local id = game.IslandType_PLASMA_ETHEREAL_ISLET
    if isMechEtherealIslet then
      id = game.IslandType_MECH_ETHEREAL_ISLET
    elseif isShadowEtherealIslet then
      id = game.IslandType_SHADOW_ETHEREAL_ISLET
    elseif isCrystalEtherealIslet then
      id = game.IslandType_CRYSTAL_ETHEREAL_ISLET
    end
    self.TeleportHomeIslandButton.Overlay("spriteName"):SetString(game.islandIconSpriteForId(id))
    self.TeleportHomeIslandButton.Overlay("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(id))
    self.TeleportHomeIslandButton.Text("text"):SetString(game.islandName(id))
    buttonsVisible = buttonsVisible + 1
    local neededLevel = game.etherealIsletMonsterTeleportLevel()
    if neededLevel > game.monsterLevel(self.uniqueMonsterId) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local unlockText = game.getLocalizedText("UNLOCKED_AT_LEVEL")
      unlockText = select(1, unlockText:gsub("XXX", neededLevel))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(unlockText)
    elseif not game.isIslandOwned(game.islandLockIsland(id)) then
      self.TeleportHomeIslandButton:DoStoredScript("setLocked")
      local requirementText = game.getLocalizedText("NOTIFICATION_REQUIRES_ITEM")
      requirementText = select(1, requirementText:gsub("XXX", game.getLocalizedText(game.islandName(game.islandLockIsland(id)))))
      self.TeleportHomeIslandButton.LockedText("text"):SetString(requirementText)
    end
  else
    self.TeleportHomeIslandButton:DoStoredScript("setInvisible")
  end
  local canSendToBattleIsland = game.canEventuallySendToBattleIsland(self.uniqueMonsterId)
  if not canSendToBattleIsland then
    self.TeleportBattleIslandButton:DoStoredScript("setInvisible")
  else
    buttonsVisible = buttonsVisible + 1
    local neededLevel = game.battleMonsterLevel()
    if neededLevel > game.monsterLevel(self.uniqueMonsterId) then
      self.TeleportBattleIslandButton:DoStoredScript("setLocked")
      local unlockText = game.getLocalizedText("UNLOCKED_AT_LEVEL")
      unlockText = select(1, unlockText:gsub("XXX", neededLevel))
      self.TeleportBattleIslandButton.LockedText("text"):SetString(unlockText)
    end
  end
  if buttonsVisible == 1 then
    local yOffset = 75 * game.windowScaleY()
    self:GetElement("TeleportBattleIslandButton"):setOrientationPosition(Vector2(0, yOffset))
    self:GetElement("TeleportHomeIslandButton"):setOrientationPosition(Vector2(0, yOffset))
  end
end
function TeleportPopup:onTick(dt)
  local transitionState = self.transitionState
  if transitionState ~= 0 then
    local transitionTime = self.transitionTime
    self:DoStoredScript("TickTransition")
    if transitionState == 1 then
      transitionTime = transitionTime + dt * 3
    elseif transitionState == 2 then
      transitionTime = transitionTime - dt * 3
    end
    transitionTime = clamp(transitionTime, 0, 1)
    self.transitionTime = transitionTime
    if transitionTime >= 1 then
      self.transitionState = 0
      self.transitionTime = 1
      self:DoStoredScript("TickTransition")
    elseif transitionTime <= 0 then
      self:root():popPopUp()
    end
  end
end
function TeleportPopup:TickTransition()
  local transitionTime = self.transitionTime
  local frame = self:GetElement("bg")
  frame("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / transitionTime))
  self.FadedBG.Sprite("alpha"):SetFloat(transitionTime * 0.5)
end
function TeleportPopup:queuePop()
  self.transitionState = 2
end
function TeleportPopup.TeleportBattleIslandButton:teleport()
  if game.monsterLevel(self:parent().uniqueMonsterId) >= game.battleMonsterLevel() then
    self.Overlay:setColor(1, 1, 1)
    self:root():popPopUp()
    game.sendToBattleIsland(game.selectedMonsterId())
  else
    local unlockText = game.getLocalizedText("UNLOCKED_AT_LEVEL")
    unlockText = select(1, unlockText:gsub("XXX", game.battleMonsterLevel()))
    game.displayNotification(unlockText)
  end
end
function TeleportPopup.TeleportHomeIslandButton:teleport()
  local isTeleportable = game.isTeleportableMonster(self:parent().uniqueMonsterId)
  local isEthereal = game.isTeleportableTo(self:parent().uniqueMonsterId, game.IslandType_ETHEREAL)
  local isEtherealIslet = game.isTeleportableTo(self:parent().uniqueMonsterId, game.IslandType_PLASMA_ETHEREAL_ISLET) or game.isTeleportableTo(self:parent().uniqueMonsterId, game.IslandType_MECH_ETHEREAL_ISLET) or game.isTeleportableTo(self:parent().uniqueMonsterId, game.IslandType_SHADOW_ETHEREAL_ISLET) or game.isTeleportableTo(self:parent().uniqueMonsterId, game.IslandType_CRYSTAL_ETHEREAL_ISLET)
  local isShuga = game.isTeleportableTo(self:parent().uniqueMonsterId, game.IslandType_SHUGGA)
  if isEthereal then
    if game.monsterLevel(self:parent().uniqueMonsterId) >= game.goldMonsterLevel() then
      self.Overlay:setColor(1, 1, 1)
      self:root():popPopUp()
      game.sendToHomeIsland(self:parent().uniqueMonsterId)
    else
      game.displayNotification("TELEPORT_MONSTER_LEVEL_NOTIFICATION")
    end
  elseif isShuga then
    if not game.isIslandOwned(3) then
      game.displayNotification("SHUGA_ISLAND_LOCKED_MESSAGE")
    elseif game.monsterLevel(self:parent().uniqueMonsterId) >= game.goldMonsterLevel() then
      self.Overlay:setColor(1, 1, 1)
      self:root():popPopUp()
      game.sendToHomeIsland(self:parent().uniqueMonsterId)
    else
      game.displayNotification("TELEPORT_MONSTER_LEVEL_NOTIFICATION")
    end
  elseif isEtherealIslet then
    if game.monsterLevel(self:parent().uniqueMonsterId) >= game.etherealIsletMonsterTeleportLevel() then
      self.Overlay:setColor(1, 1, 1)
      self:root():popPopUp()
      game.sendToEtherealIslet(self:parent().uniqueMonsterId)
    else
      game.displayNotification("ISLET_TELEPORT_MONSTER_LEVEL_NOTIFICATION")
    end
  elseif isTeleportable then
    self.Overlay:setColor(1, 1, 1)
    self:root():popPopUp()
    game.sendToHomeIsland(self:parent().uniqueMonsterId)
  end
end
return TeleportPopup
