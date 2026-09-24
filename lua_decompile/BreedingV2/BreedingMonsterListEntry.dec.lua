local MONSTER_BREEDING_LEVEL = 4
local BreedingMonsterListEntry = {
  Bg = {},
  CharacterImage = {},
  MonsterSpecies = {},
  MonsterName = {},
  LevelSprite = {},
  Genes = {},
  Touch = {}
}
function BreedingMonsterListEntry:Setup(monster, idx, controller, list)
  self.monster = monster
  self.idx = idx
  self.controller = controller
  self.list = list
  self.flipped = list.flipped or false
end
function BreedingMonsterListEntry:onInit()
  self.enabled = true
  self.touchEnabled = true
  self.dragging = 0
  self.touchStart = 0
  self.touchStartY = 0
  self:setSearchChildren(false)
end
function BreedingMonsterListEntry:updateLevel()
  if self.monster then
    local spriteString = "monster_level_numbers_"
    local monsterLevel = self.monster:level()
    if monsterLevel < 10 then
      spriteString = spriteString .. "0"
    end
    self.LevelSprite.Sprite:GetVar("spriteName"):SetString(spriteString .. monsterLevel)
  end
end
function BreedingMonsterListEntry:onPostInit()
  if self.postInitCalled then
    return
  end
  self.postInitCalled = true
  local monsterData = self.monster:data()
  local portraitSpriteName = "gfx/breeding/" .. monsterData:portrait()
  if monsterData:isModal() then
    local currentMode = game.player():getActiveIsland():islandMode()
    local modalMonsterData = game.getModalMonsterData(monsterData, currentMode)
    portraitSpriteName = "gfx/breeding/" .. modalMonsterData:portrait()
  end
  self.CharacterImage.Sprite:GetVar("spriteName"):SetString(portraitSpriteName)
  self.CharacterImage.Sprite:GetVar("hFlip"):SetInt(1)
  local species = LOC(monsterData:name())
  if #species > 20 then
    species = species:sub(1, 18) .. ".."
  end
  self.MonsterSpecies.Text:GetVar("text"):SetString(species)
  local name = self.monster:monsterName()
  if #name > 14 then
    name = name:sub(1, 12) .. ".."
  end
  self.MonsterName.Text:GetVar("text"):SetString(name)
  self:updateLevel()
  self.Genes("MonsterId"):SetInt(monsterData:monsterId())
  if self.monster:level() < MONSTER_BREEDING_LEVEL then
    self:SetEnabled(false)
    local attachedTemplate = menu:addTemplateElement("template_breeding_monsterlist_feedoverlay", "feed_overlay", self)
    attachedTemplate:relativeTo(self)
    attachedTemplate:makeSizeDependent(self)
    attachedTemplate:setOrientation(lua_sys.MenuOrientation(0, 0, -3, lua_sys.HCENTER, lua_sys.VCENTER))
    attachedTemplate:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    attachedTemplate:init()
    attachedTemplate:postInit()
    function attachedTemplate.handleTouchUp()
      if self.controller then
        self.controller:ShowFeedPopup(self)
      end
    end
    self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgMonsterLevelUp", "gotMsgMonsterLevelUp")
    self.feedOverlay = attachedTemplate
  end
end
function BreedingMonsterListEntry:gotMsgMonsterLevelUp(msg)
  if self.monster and msg.id == self.monster:uniqueId() then
    self:updateLevel()
    if self.monster:level() >= MONSTER_BREEDING_LEVEL then
      if self.feedOverlay then
        self:RemoveElement(self.feedOverlay)
        self.feedOverlay = nil
      end
      self:SetEnabled(true)
    end
  end
end
function BreedingMonsterListEntry:SetSelected(selected)
  if selected then
    self.Bg.Sprite:GetVar("spriteName"):SetString("gfx/menu/selectable_bar_yellow_9s")
  else
    self.Bg.Sprite:GetVar("spriteName"):SetString("gfx/menu/selectable_bar_grey_9s")
  end
end
function BreedingMonsterListEntry:SetVisible(visible)
  if visible then
    self.Bg.Sprite:GetVar("visible"):SetInt(1)
    self.CharacterImage.Sprite:GetVar("visible"):SetInt(1)
    self.MonsterSpecies.Text:GetVar("visible"):SetInt(1)
    self.MonsterName.Text:GetVar("visible"):SetInt(1)
    self.LevelSprite.Sprite:GetVar("visible"):SetInt(1)
    self.Genes:setVisible()
    self.Touch:GetVar("enabled"):SetInt(self.touchEnabled and 1 or 0)
    if self.feedOverlay then
      self.feedOverlay:setVisible()
    end
  else
    self.Bg.Sprite:GetVar("visible"):SetInt(0)
    self.CharacterImage.Sprite:GetVar("visible"):SetInt(0)
    self.MonsterSpecies.Text:GetVar("visible"):SetInt(0)
    self.MonsterName.Text:GetVar("visible"):SetInt(0)
    self.LevelSprite.Sprite:GetVar("visible"):SetInt(0)
    self.Genes:setInvisible()
    self.Touch:GetVar("enabled"):SetInt(0)
    if self.feedOverlay then
      self.feedOverlay:setInvisible()
    end
  end
end
function BreedingMonsterListEntry:SetEnabled(enabled)
  if enabled then
    self.Bg.Sprite:setColor(1, 1, 1)
    self.CharacterImage.Sprite:setColor(1, 1, 1)
    self.MonsterSpecies.Text:setColor(1, 1, 1)
    self.MonsterName.Text:setColor(0.6, 0.6, 0.6)
    self.LevelSprite.Sprite:setColor(1, 1, 1)
    self.enabled = true
    self.Genes:DoStoredScript("enable")
  else
    self.Bg.Sprite:setColor(0.5, 0.5, 0.5)
    self.CharacterImage.Sprite:setColor(0.5, 0.5, 0.5)
    self.MonsterSpecies.Text:setColor(0.5, 0.5, 0.5)
    self.MonsterName.Text:setColor(0.3, 0.3, 0.3)
    self.LevelSprite.Sprite:setColor(0.5, 0.5, 0.5)
    self.enabled = false
    self.Genes:DoStoredScript("disable")
  end
end
function BreedingMonsterListEntry:SetClipping(x, y, w, h)
  self.Bg.Sprite:setClipRect(x, y, w, h)
  self.CharacterImage.Sprite:setClipRect(x, y, w, h)
  self.MonsterSpecies.Text:setClipRect(x, y, w, h)
  self.MonsterName.Text:setClipRect(x, y, w, h)
  self.LevelSprite.Sprite:setClipRect(x, y, w, h)
  self.Genes:setClipping(x, y, w, h)
  self.Touch:setClipRect(x, y, w, h)
  if self.feedOverlay then
    self.feedOverlay:setClipping(x, y, w, h)
  end
end
function BreedingMonsterListEntry.Touch:onTouchDown(element, x, y)
  element.dragging = 0
  element.touchStartY = y
  element.controller:OnListSelected(element.list)
end
function BreedingMonsterListEntry.Touch:onTouchDrag(element, x, y, dx, dy)
  element.dragging = math.abs(element.touchStartY - y)
end
function BreedingMonsterListEntry.Touch:onTouchUp(element)
  if element.touchEnabled and element.dragging < 4 * BreedingMenuScaleX() and element.OnEntryTouched then
    element:OnEntryTouched()
  end
end
return BreedingMonsterListEntry
