local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local Attuner = {
  selectedStartGene = nil,
  selectedEndGene = nil,
  executeStartGene = nil,
  executeEndGene = nil,
  selectedCritter = nil,
  selectedIsland = nil,
  newSelectedIsland = nil,
  isShowingAttuneAnim = false,
  attunedIsland = 0
}
function Attuner:populateIslands()
  local genes = game.attunerGeneDatas(true)
  self.numIslands = genes:size()
  for i = 0, genes:size() - 1 do
    local island = self:E("Island" .. i + 1):E("Island")
    local geneData = genes[i]
    island.attunerGeneData = geneData
    local sheet = game.islandIconSheetForId(geneData.islandId)
    local sprite = game.islandIconSpriteForId(geneData.islandId)
    island:C("Sprite"):V("sheetName"):SetString("xml_resources/" .. sheet)
    island:C("Sprite"):V("spriteName"):SetString(sprite)
    island:C("SelectedSprite"):V("sheetName"):SetString("xml_resources/" .. sheet)
    island:C("SelectedSprite"):V("spriteName"):SetString(sprite)
    island:C("Gene"):V("spriteName"):SetString(game.geneFilename(geneData.geneLetter))
    island:hideText()
  end
end
function Attuner:GridPosX(entryWidth, parentWidth, spacingWidth, entriesPerRow, index)
  local borderWidth = (parentWidth - entriesPerRow * entryWidth - (entriesPerRow - 1) * spacingWidth) / 2
  local column = math.floor(index % entriesPerRow)
  local xPos = borderWidth + column * (entryWidth + spacingWidth)
  return xPos
end
function Attuner:gridPosYByRow(entryHeight, parentHeight, spacingHeight, entriesPerCol, entriesPerRow, index)
  local borderHeight = (parentHeight - entriesPerCol * entryHeight - (entriesPerCol - 1) * spacingHeight) / 2
  local row = math.floor(index / entriesPerRow)
  local yPos = borderHeight + row * (entryHeight + spacingHeight)
  return yPos
end
function Attuner:selectNewIsland()
  if self.selectedIsland ~= self.newSelectedIsland then
    self:setSelectedIsland(self.newSelectedIsland)
    lua_sys.playSoundFx("audio/sfx/structure_attunement_selectisland.wav")
  end
end
function Attuner:setSelectedIsland(island)
  self.selectedIsland = island
  local geneData = self.selectedIsland.attunerGeneData
  self.selectedEndGene = geneData.geneLetter
  local sheet = game.islandIconSheetForId(geneData.islandId)
  local sprite = game.islandIconSpriteForId(geneData.islandId)
  self.SelectedIsland.Island:C("Sprite"):V("sheetName"):SetString("xml_resources/" .. sheet)
  self.SelectedIsland.Island:C("Sprite"):V("spriteName"):SetString(sprite)
  self.SelectedIsland.Island:C("Sprite"):V("visible"):SetInt(1)
  self.SelectedIsland.Island:C("Gene"):V("visible"):SetInt(1)
  self.SelectedIsland.Island:C("Gene"):V("spriteName"):SetString(game.geneFilename(self.selectedEndGene))
  if game.Attuner_canReattuneRare(geneData.geneLetter) then
    self.SelectedIsland.Island.ReattunementSprites.Rare.Sprite:V("visible"):SetInt(1)
  else
    self.SelectedIsland.Island.ReattunementSprites.Rare.Sprite:V("visible"):SetInt(0)
  end
  self:updateAvailableCritters()
  self:updateAvailableIslands()
  self:updateAttuneAnimation()
  self.Cost:C("Text"):V("text"):SetString(game.commaizeNumber(game.attuningCost(self.selectedEndGene)))
end
function Attuner:populateCritters()
  local attunerGenes = game.attunerGenes()
  local critterHolder = self.CritterList
  local entriesPerRow = 3
  local entriesPerCol = 2
  local critterEntry
  local xPos = 0
  local yPos = 0
  local spacingWidth = 15 * game.menuScaleX()
  local spacingHeight = 10 * game.menuScaleX()
  local parentHeight = critterHolder:absH()
  local parentWidth = critterHolder:absW()
  local index = 0
  if game.isQABuild() then
    spacingWidth = 25 * game.menuScaleX()
  end
  if 0 < game.numUnattunedCritters() or game.isQABuild() then
    critterEntry = self:makeCritter(critterHolder, 0, "", game.numUnattunedCritters(), xPos, yPos)
    local entryHeight = critterEntry:absH()
    local entryWidth = critterEntry:absW()
    xPos = self:GridPosX(entryWidth, parentWidth, spacingWidth, entriesPerRow, index)
    yPos = self:gridPosYByRow(entryHeight, parentHeight, spacingHeight, entriesPerCol, entriesPerRow, index)
    critterEntry:setOrientation(lua_sys.MenuOrientation(xPos, yPos, -1, lua_sys.LEFT, lua_sys.TOP))
    index = index + 1
  end
  for i = 0, attunerGenes:size() - 1 do
    if 0 < game.numCrittersWithGene(attunerGenes[i]) or game.isQABuild() then
      critterEntry = self:makeCritter(critterHolder, index, attunerGenes[i], game.numCrittersWithGene(attunerGenes[i]), xPos, yPos)
      local entryHeight = critterEntry:absH()
      local entryWidth = critterEntry:absW()
      xPos = self:GridPosX(entryWidth, parentWidth, spacingWidth, entriesPerRow, index)
      yPos = self:gridPosYByRow(entryHeight, parentHeight, spacingHeight, entriesPerCol, entriesPerRow, index)
      critterEntry:setOrientation(lua_sys.MenuOrientation(xPos, yPos, -1, lua_sys.LEFT, lua_sys.TOP))
      index = index + 1
    end
  end
  self.numCritters = index
end
function Attuner:makeCritter(parent, index, gene, num, xPos, yPos)
  local critterEntry = menu:addTemplateElement("template_critter_entry", "critterEntry" .. index, parent)
  critterEntry.gene = gene
  critterEntry.num = num
  critterEntry:setParent(parent)
  critterEntry:relativeTo(parent)
  critterEntry:setOrientation(lua_sys.MenuOrientation(xPos, yPos, -1, lua_sys.LEFT, lua_sys.TOP))
  critterEntry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  critterEntry:setOrientationPosition(lua_sys.Vector2(xPos, yPos))
  critterEntry:V("Layer"):SetString("MidPopUps")
  critterEntry:setPositionBroadcast(false)
  critterEntry:init()
  parent:setPositionBroadcast(true)
  if num == 0 then
    critterEntry:setDisabled(true)
  end
  return critterEntry
end
function Attuner:CritterSelected(newSelection)
  if self.selectedCritter ~= newSelection then
    self:setCritterSelected(newSelection)
    lua_sys.playSoundFx("audio/sfx/structure_attunement_selectcritter.wav")
  end
end
function Attuner:setCritterSelected(newSelection)
  newSelection:setDisabled()
  self.selectedCritter = newSelection
  self.selectedStartGene = newSelection.gene
  self.SelectedCritter:C("Sprite"):V("spriteName"):SetString(game.critterSprite(newSelection.gene))
  self.SelectedCritter:C("Sprite"):V("visible"):SetInt(1)
  self.SelectedCritter:C("SpriteBg"):V("visible"):SetInt(1)
  self:updateAvailableIslands()
  self:updateAvailableCritters()
  self:updateAttuneAnimation()
end
function Attuner:updateAvailableIslands()
  for i = 1, self.numIslands do
    local entry = self:E("Island" .. i):E("Island")
    entry:setSelected(self.selectedEndGene and entry.attunerGeneData.geneLetter == self.selectedEndGene)
    entry:setDisabled(self.selectedCritter and entry.attunerGeneData.geneLetter == self.selectedCritter.gene and self:canReattuneToSameGene(entry.attunerGeneData.geneLetter) == false)
  end
end
function Attuner:updateAvailableCritters()
  for i = 0, self.numCritters - 1 do
    local entry = self.CritterList:E("critterEntry" .. i)
    entry:setSelected(self.selectedStartGene and entry.gene == self.selectedStartGene)
    entry:setDisabled(self.selectedEndGene and entry.gene == self.selectedEndGene and self:canReattuneToSameGene(entry.gene) == false or entry.num == 0)
  end
end
function Attuner:canReattuneToSameGene(gene)
  if self.reattuningMonsterId ~= 0 then
    local monster = game.GetMonster(self.reattuningMonsterId)
    local genes = monster:data():unsortedGenes()
    local unReattunedGenes = genes
    if monster:reattunedGenes() ~= "" then
      unReattunedGenes = genes:gsub("[" .. monster:reattunedGenes() .. "]", "")
    end
    if unReattunedGenes:find(gene) and game.Attuner_canReattuneRare(gene) then
      return true
    end
  end
  return false
end
function Attuner:updateAttuneAnimation()
  if self.isShowingAttuneAnim == false and self.selectedStartGene and self.selectedEndGene then
    self.isShowingAttuneAnim = true
    self.AttuneAnimation.Sprite:show(true)
    self.AttuneAnimationBottom.Sprite:show(true)
    self.AttuneAnimation.Sprite:Play()
    self.AttuneAnimationBottom.Sprite:Play()
  elseif self.isShowingAttuneAnim == true and (self.selectedStartGene == nil or self.selectedEndGene == nil) then
    self.AttuneAnimation.Sprite:Stop()
    self.AttuneAnimationBottom.Sprite:Stop()
    self.AttuneAnimation.Sprite:show(false)
    self.AttuneAnimationBottom.Sprite:show(false)
    self.isShowingAttuneAnim = false
  end
end
function Attuner:onInit()
  self.selectedStartGene = nil
  self.selectedEndGene = nil
  self.executeStartGene = nil
  self.executeEndGene = nil
  self.selectedCritter = nil
  self.selectedIsland = nil
  self.newSelectedIsland = nil
  self.isShowingAttuneAnim = false
  self.showReattune = false
  self.reattuningMonsterId = 0
  self.attunedIsland = game.attunedIslandId()
  self:populateCritters()
  self:populateIslands()
  self:updateQABuildUI()
  MenuElementPositionOffsetTransition.OnInit(self.TransitionNode, {
    startY = lua_sys.screenHeight() * 2,
    endY = 0,
    duration = 0.66
  })
  self:showMenu()
end
function Attuner:onPostInit()
  if game.numUnattunedCritters() > 0 then
    self:setCritterSelected(self.CritterList.critterEntry0)
  end
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCritterCountUpdated", "updateQABuildUI")
  local gene = game.getAttunerDefaultEndGene()
  if gene ~= "" then
    local island = self:findIslandWithGene(gene)
    if island ~= nil then
      self:setSelectedIsland(island)
    end
    game.setAttunerDefaultEndGene(game.selectedStructureId(), "")
  end
  local attuner = game.FindAttuner()
  self.reattuningMonsterId = attuner:reattuningMonster()
  if self.reattuningMonsterId ~= 0 then
    self.MonsterSelect.Bg:V("visible"):SetInt(0)
    self.MonsterSelect.Sprite:V("visible"):SetInt(0)
    self.MonsterSelect.MonsterImage:V("visible"):SetInt(1)
    self.MonsterSelect.MonsterImage:V("spriteName"):SetString("gfx/breeding/" .. game.getPortraitName(self.reattuningMonsterId))
    self.MonsterSelect.Genes("UserMonsterId"):SetInt(self.reattuningMonsterId)
    self.MonsterSelect.Genes:populate()
  end
  if attuner:maxReattuneMonsterRarity() == game.MonsterRarity_Undefined then
    self.MonsterSelect.Bg:V("visible"):SetInt(0)
    self.MonsterSelect.Sprite:V("visible"):SetInt(0)
    self.MonsterSelect.MonsterImage:V("visible"):SetInt(0)
    self.MonsterSelect:V("touchDisabled"):SetInt(1)
    self.CenterArrow.Sprite:V("visible"):SetInt(1)
  end
end
function Attuner:updateQABuildUI()
  if game.isQABuild() then
    local attunerGenes = game.attunerGenes()
    local attunedCritters = 0
    for i = 0, attunerGenes:size() - 1 do
      attunedCritters = attunedCritters + game.numCrittersWithGene(attunerGenes[i])
    end
    local hasMaxCritters = attunedCritters == game.numCritters()
    for i = 0, self.numCritters - 1 do
      local entry = self.CritterList:E("critterEntry" .. i)
      local num = game.numUnattunedCritters()
      if entry.gene ~= "" then
        num = game.numCrittersWithGene(entry.gene)
        entry:setAddCritterDisabled(hasMaxCritters)
        entry:setRemoveCritterDisabled(num == 0)
      else
        entry:setAddCritterDisabled(true)
        entry:setRemoveCritterDisabled(true)
      end
      entry:setNum(num)
    end
  end
end
function Attuner:findIslandWithGene(gene)
  for i = 1, self.numIslands do
    local entry = self:E("Island" .. i):E("Island")
    if entry.attunerGeneData.geneLetter == gene then
      return entry
    end
  end
  return nil
end
function Attuner:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      if self.executeStartGene ~= nil and self.executeEndGene ~= nil then
        game.startAttuning(self.executeStartGene, self.executeEndGene)
      end
      e:root():popPopUp()
      if self.showReattune and game.getContextBar() then
        game.getContextBar():setContext("REATTUNE_MENU")
      end
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self.TransitionNode, dt, options)
  if self.attunedIsland ~= game.attunedIslandId() then
    self.attunedIsland = game.attunedIslandId()
    self:reset()
  end
end
function Attuner:showMenu()
  MenuElementPositionOffsetTransition.Show(self.TransitionNode)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Attuner:hideMenu()
  MenuElementPositionOffsetTransition.Hide(self.TransitionNode)
  self.Fade:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Attuner:queuePop()
  self:hideMenu()
end
function Attuner:reset()
  self:clearSelectedCritter()
  for i = 0, self.numCritters - 1 do
    local entry = self.CritterList:E("critterEntry" .. i)
    if entry.num ~= 0 then
      entry:setDisabled(false)
      entry:setSelected(false)
    end
  end
  self:clearSelectedIsland()
  self:populateIslands()
  self.Cost:C("Text"):V("text"):SetString("0")
end
function Attuner:clearSelectedCritter()
  self.selectedStartGene = nil
  self.selectedCritter = nil
  self:updateAvailableIslands()
  self:updateAvailableCritters()
  self:updateAttuneAnimation()
  self.SelectedCritter:C("Sprite"):V("visible"):SetInt(0)
  self.SelectedCritter:C("SpriteBg"):V("visible"):SetInt(0)
end
function Attuner:clearSelectedIsland()
  self.selectedEndGene = nil
  self.selectedIsland = nil
  self.newSelectedIsland = nil
  self:updateAvailableIslands()
  self:updateAvailableCritters()
  self:updateAttuneAnimation()
  self.SelectedIsland.Island:setInvisible()
end
function Attuner:startAttuning()
  if self.selectedStartGene ~= nil and self.selectedEndGene ~= nil then
    local cost = game.attuningCost(self.selectedEndGene)
    if game.clearPurchase(game.CurrencyType_Shards, cost, game.PurchaseType_ATTUNING, 0) then
      self.executeStartGene = self.selectedStartGene
      self.executeEndGene = self.selectedEndGene
      self:queuePop()
      if game.getContextBar() then
        game.getContextBar():setContext("ATTUNER_ATTUNING")
      end
    end
  else
    game.displayNotification("ATTUNING_ERROR_SELECT_GENES")
  end
end
function Attuner:ShowReattune()
  if game.worldContext():availableReattuneMonsters(game.MonsterRarity_Common):size() == 0 and game.worldContext():availableReattuneMonsters(game.MonsterRarity_Rare):size() == 0 then
    game.displayNotification("NOTIFICATION_NO_REATTUBALE_MONSTERS")
  else
    self.showReattune = true
    if game.getContextBar() then
      game.getContextBar():setContext("BLANK")
    end
    self:hideMenu()
  end
end
return Attuner
