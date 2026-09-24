local MenuHelpers = include("MenuHelpers")
local Genes = include("Genes")
local MonsterProperties = include("MonsterProperties")
local PopupBreedWarning = {
  MainPanel = {},
  Notification = {},
  MonsterA = {},
  Plus = {},
  MonsterB = {},
  Equals = {},
  MonsterResult = {}
}
function PopupBreedWarning:setup(warning, monsterA, monsterB, overlappingGenes)
  self.choice = false
  self.Notification.Text:GetVar("text"):SetString(warning)
  local overlapGeneInfos = {}
  if overlappingGenes then
    for i, gene in ipairs(overlappingGenes) do
      overlapGeneInfos[i] = Genes.GetSingleGeneInfo(gene)
    end
  end
  local function checkOverlap(geneSpriteName)
    for i, overlapGene in ipairs(overlapGeneInfos) do
      if geneSpriteName == overlapGene.sprite then
        return true
      end
    end
    return false
  end
  local function setGenes(e, monsterId)
    local items = Genes.InitForMonsterId(monsterId, e, {
      layer = "FrontPopUps",
      spacing = -2 * game.hudScale(),
      prefix = "geneItem",
      priority = -1,
      size = 0.5 * game.hudScale(),
      vAnchor = lua_sys.BOTTOM,
      offsetY = -8 * game.menuScaleX()
    })
    for i, item in ipairs(items) do
      if type(item) ~= "table" then
        local itemSpriteName = item.Sprite:GetVar("spriteName"):GetString()
        if checkOverlap(itemSpriteName) then
          local attachedTemplate = menu:addTemplateElement("template_spritesheet", "attachedTemplate", item)
          attachedTemplate:setParent(item)
          attachedTemplate:setOrientation(MenuOrientation(0, 0, -1, HCENTER, VCENTER))
          attachedTemplate:setRelativeObjectAnchors(HCENTER, VCENTER)
          attachedTemplate:init()
          attachedTemplate.Sprite:GetVar("spriteName"):SetString("guide_no")
          attachedTemplate.Sprite:GetVar("sheetName"):SetString("xml_resources/guides.xml")
          attachedTemplate.Sprite:GetVar("layer"):SetString("FrontPopUps")
          attachedTemplate.Sprite:GetVar("size"):SetFloat(0.5 * game.hudScale())
          attachedTemplate:postInit()
          attachedTemplate:setPositionBroadcast(true)
        end
      end
    end
  end
  local function setupMonster(e, monster, flipped)
    e.Sprite:GetVar("visible"):SetInt(1)
    local monsterAnimElement = e.Anim
    local animComponent = monsterAnimElement.Sprite
    animComponent:GetVar("animationName"):SetString("xml_bin/" .. monster:animationFile())
    animComponent:GetVar("animation"):SetString("Store")
    animComponent:GetVar("visible"):SetInt(1)
    local facing = MonsterProperties.getFacing(monster:monsterId())
    local hFlip = flipped and 1 - facing or facing
    animComponent:GetVar("hFlip"):SetInt(hFlip)
    monsterAnimElement:setOrientationPosition(Vector2(animComponent:size().x * 0.5, animComponent:size().y * 0.5 + 20 * game.hudScale()))
    monsterAnimElement:setPositionBroadcast(true)
    setGenes(e, monster:monsterId())
  end
  setupMonster(self.MonsterA, monsterA, false)
  setupMonster(self.MonsterB, monsterB, true)
  local elementList = {
    self.MonsterA,
    self.Plus,
    self.MonsterB
  }
  if overlappingGenes == nil then
    local possibleResults = game.getPossibleBreedResults(monsterA:monsterId(), monsterB:monsterId())
    if possibleResults:size() > 0 then
      local bestResult
      for i = 0, possibleResults:size() - 1 do
        local resultMonster = game.getMonsterData(possibleResults[i])
        if bestResult == nil or #resultMonster:unsortedGenes() > #bestResult:unsortedGenes() then
          bestResult = resultMonster
        end
      end
      if bestResult then
        self.Equals.Sprite:GetVar("visible"):SetInt(1)
        table.insert(elementList, self.Equals)
        setupMonster(self.MonsterResult, bestResult)
        table.insert(elementList, self.MonsterResult)
      end
    end
  end
  MenuHelpers.CenterHorizontally(elementList)
  local panelSizeY = 320 * game.menuScaleX()
  self.bg:setSize(lua_sys.Vector2(self.bg:absW(), panelSizeY))
  function self.bg.onDoneHide()
    local textID = self.Notification.Text:GetVar("text"):GetString()
    if string.match(textID, " ") then
      textID = ""
    end
    self:root():removePopUp(self:name())
    game.submitConfirmation("BREED_WARNING", self.choice, textID)
    if self.resetContextBar and game.isQABuild() then
      manager:setContext("BREED_MENU")
    end
  end
  self.resetContextBar = false
  self:updateClipping()
end
function PopupBreedWarning:updateClipping()
  local clipX = self.bg:absX() + 8 * game.hudScale()
  local clipY = self.bg:absY() + 24 * game.hudScale()
  local clipW = self.bg:absW() - 16 * game.hudScale()
  local clipH = self.bg:absH() - 48 * game.hudScale()
  self.MonsterA.Sprite:setClipRect(clipX, clipY, clipW, clipH)
  self.MonsterB.Sprite:setClipRect(clipX, clipY, clipW, clipH)
  self.MonsterResult.Sprite:setClipRect(clipX, clipY, clipW, clipH)
end
function PopupBreedWarning:onTick(dt)
  self:updateClipping()
end
function PopupBreedWarning:queuePop()
  if game.topPopUp() == self then
    self.bg:Hide()
    self.FadedBG:Hide()
    self.resetContextBar = true
  end
end
return PopupBreedWarning
