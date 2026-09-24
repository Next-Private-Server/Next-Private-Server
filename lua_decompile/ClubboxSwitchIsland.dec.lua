local ClubboxSwitchIsland = {
  FadedBG = {},
  DJDialog = {},
  IslandSelect = {
    IslandCarousel = {
      SelectIslandButton = {
        Touch = {}
      },
      SwitchCost = {},
      RightButton = {},
      LeftButton = {}
    },
    selectedIslandId = 1
  },
  ConfirmationView = {
    ConfirmAllButton = {
      Touch = {}
    }
  },
  BackButton = {
    Overlay = {},
    Touch = {}
  },
  viewMode = 1
}
function ClubboxSwitchIsland:onInit()
  self("transitionState"):SetInt(1)
  self("transitionTime"):SetFloat(0)
  playSoundFx("audio/sfx/menu_slide.wav")
  manager:setContext("BLANK")
end
function ClubboxSwitchIsland:onPostInit()
  local clubbox = game.player():currentyActiveClubbox()
  local currentIsland = clubbox:currentIsland()
  local currentIslandId = currentIsland and currentIsland:id() or 0
  if currentIslandId > 0 then
    self.IslandSelect.selectedIslandId = currentIslandId
  end
  self:refreshView()
  function self.IslandSelect.IslandCarousel.OnIslandUpdated(carousel, lastIsland, newIsland)
    if lastIsland ~= newIsland then
      print(" == Island Updated:", lastIsland, "->", newIsland)
      self:updateSelectIslandButton()
      self:updateSwitchCost()
    end
  end
end
function ClubboxSwitchIsland:setToLocationSelectView()
  self.IslandSelect:enable()
  self.ConfirmationView:disable()
  self.DJDialog:SetAvatar("gfx/clubbox/T-Pain_Arms_Crossed")
  self.DJDialog:SetText("CLUBBOX_RELOCATE_SELECT", true)
  self.BackButton.Overlay("spriteName"):SetString("button_back")
  self.BackButton.Overlay("sheetName"):SetString("xml_resources/context_buttons.xml")
  self.BackButton.Text("text"):SetString("BACK")
end
function ClubboxSwitchIsland:advanceToConfirmation()
  local clubbox = game.player():currentyActiveClubbox()
  local currentIsland = clubbox:currentIsland()
  local currentIslandId = currentIsland and currentIsland:id() or 0
  if self.IslandSelect.selectedIslandId == currentIslandId then
    manager:setContext(manager:reserveState())
    game.popPopUp()
  else
    self.viewMode = 2
  end
  self:refreshView()
end
function ClubboxSwitchIsland:setToConfirmationView()
  self.IslandSelect:disable()
  self.ConfirmationView:enable()
  self.DJDialog:SetAvatar("gfx/clubbox/T-Pain_Big_Welcome")
  local currentIslandText = LOC(game.islandName(game.currentIsland()))
  local islandText = LOC(game.islandName(self.IslandSelect.selectedIslandId))
  local str = LOC("CLUBBOX_RELOCATE_CONFIRM")
  str = str:gsub("%${ISLAND}", islandText)
  str = str:gsub("%${CURRENT_ISLAND}", currentIslandText)
  self.DJDialog:SetText(str, true)
  self.BackButton.Overlay("spriteName"):SetString("button_back")
  self.BackButton.Overlay("sheetName"):SetString("xml_resources/context_buttons.xml")
  self.BackButton.Text("text"):SetString("BACK")
end
function ClubboxSwitchIsland:updateSelectIslandButton()
  local clubbox = game.player():currentyActiveClubbox()
  local currentIsland = clubbox:currentIsland()
  local currentIslandId = currentIsland and currentIsland:id() or 0
  local selectedIslandId = self.IslandSelect.selectedIslandId
  local str = "CLUBBOX_RELOCATE"
  if currentIslandId == selectedIslandId then
    str = "CLUBBOX_STAY"
  end
  self.IslandSelect.IslandCarousel.SelectIslandButton.Text("text"):SetString(str)
end
function ClubboxSwitchIsland:getSwitchCost(islandId)
  local clubbox = game.player():currentyActiveClubbox()
  local currentIsland = clubbox:currentIsland()
  local currentIslandId = currentIsland and currentIsland:id() or 0
  local switchCost = math.floor(clubbox:curHype() / 1000)
  if currentIslandId == islandId then
    switchCost = 0
  end
  return switchCost
end
function ClubboxSwitchIsland:updateSwitchCost()
  local clubbox = game.player():currentyActiveClubbox()
  local currentIsland = clubbox:currentIsland()
  local currentIslandId = currentIsland and currentIsland:id() or 0
  local selectedIslandId = self.IslandSelect.selectedIslandId
  local switchCost = math.floor(clubbox:curHype() / 1000)
  if currentIslandId == selectedIslandId then
    switchCost = 0
  end
  self.IslandSelect.IslandCarousel.SwitchCost.Text("text"):SetString("-" .. tostring(switchCost))
  if switchCost > 0 then
    self.IslandSelect.IslandCarousel.SwitchCost:setVisible()
  else
    self.IslandSelect.IslandCarousel.SwitchCost:setInvisible()
  end
end
function ClubboxSwitchIsland:refreshView()
  self:updateSelectIslandButton()
  self:updateSwitchCost()
  if self.viewMode == 1 then
    self:setToLocationSelectView()
  else
    self:setToConfirmationView()
  end
end
function ClubboxSwitchIsland:queuePop()
  manager:setContext(manager:reserveState())
  self:root():popPopUp()
end
function ClubboxSwitchIsland.IslandSelect:onInit()
end
function ClubboxSwitchIsland.IslandSelect:enable()
  print("Enable Island Select")
  self.IslandCarousel:setVisible()
end
function ClubboxSwitchIsland.IslandSelect:disable()
  print("Disable Island Select")
  self.IslandCarousel:setInvisible()
end
function ClubboxSwitchIsland.ConfirmationView:refreshIslandSprite()
  local selectedIslandId = self:parent().IslandSelect.selectedIslandId
  self.IslandSprite.Sprite("spriteName"):SetString(game.islandIconSpriteForId(selectedIslandId))
  self.IslandSprite.Sprite("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(selectedIslandId))
end
function ClubboxSwitchIsland.ConfirmationView:enable()
  self:refreshIslandSprite()
  self.IslandSprite.Sprite:setVisible()
  self.ConfirmAllButton:setVisible()
end
function ClubboxSwitchIsland.ConfirmationView:disable()
  self.IslandSprite.Sprite:setInvisible()
  self.ConfirmAllButton:setInvisible()
end
function ClubboxSwitchIsland.ConfirmationView.ConfirmAllButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  local top = element:parent():parent()
  local selectedIslandId = top.IslandSelect.selectedIslandId
  if selectedIslandId ~= 0 then
    local cost = top:getSwitchCost(selectedIslandId)
    if cost == 0 or game.clearPurchase(game.CurrencyType_Diamonds, cost, game.PurchaseType_RELOCATE_CLUBBOX, selectedIslandId) then
      manager:setContext(manager:reserveState())
      self:root():popPopUp()
      print("== Moving Clubbox to", selectedIslandId)
      game.moveClubbox(selectedIslandId)
    end
  end
end
function ClubboxSwitchIsland.BackButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Overlay:setColor(1, 1, 1)
  if element:parent().viewMode == 1 then
    manager:setContext(manager:reserveState())
    game.popPopUp()
  else
    element:parent().viewMode = element:parent().viewMode - 1
    element:parent():refreshView()
  end
end
return ClubboxSwitchIsland
