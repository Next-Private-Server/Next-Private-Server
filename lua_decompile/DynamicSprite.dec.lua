local MonsterProperties = include("MonsterProperties")
local DynamicSprite = {
  SpriteSheet = nil,
  Sprite = nil,
  Anim = nil
}
function DynamicSprite:onInit()
  self.isVisible = true
  self.targetSize = self:templateVars().targetSize
  self.sizeMode = self:templateVars().sizeMode
  self.spriteName = self:templateVars().spriteName
  self.sheetName = self:templateVars().sheetName
  self.monsterId = -1
  self.currentScale = 1
  self.scaleMod = 1
  self.origXOffset = -1
  self.origYOffset = -1
end
function DynamicSprite:setTargetSize(targetSize)
  self.targetSize = targetSize
  self:refresh()
end
function DynamicSprite:setScaleMod(targetSize)
  self.scaleMod = targetSize
  self:refresh()
end
function DynamicSprite:setSprite(spriteName, sheetName)
  self.spriteName = spriteName
  self.sheetName = sheetName
  self.monsterId = -1
  self:refresh()
end
function DynamicSprite:loadLootRewardData(rewardData)
  if rewardData.type == game.LootType_Monster then
    local monsterData = game.getMonsterByEntityId(rewardData.id)
    self:loadMonsterIdle(monsterData:monsterId())
    return
  end
  self.sheetName = rewardData:getSpriteSheet()
  self.spriteName = rewardData:getSprite()
  self.scaleMod = rewardData:getSpriteScale()
  self.monsterId = -1
  self:refresh()
end
function DynamicSprite:loadMonsterIdle(monsterId)
  self.monsterId = monsterId
  self.sheetName = "xml_bin/" .. game.monsterTypeGfxName(self.monsterId)
  self.spriteName = "Idle"
  self:refresh()
end
function DynamicSprite:SetLayer(layer)
  local mode = self:getMode()
  if mode == "sprite" and self.Sprite then
    self.Sprite("layer"):SetString(layer)
  elseif mode == "anim" and self.Anim then
    self.Anim("layer"):SetString(layer)
  elseif mode == "spritesheet" and self.SpriteSheet then
    self.SpriteSheet("layer"):SetString(layer)
  end
end
function DynamicSprite:SetColor(r_percent, g_percent, b_percent)
  local mode = self:getMode()
  if mode == "sprite" and self.Sprite then
    self.Sprite:setColor(r_percent, g_percent, b_percent)
  elseif mode == "anim" and self.Anim then
    self.Anim:setColor(r_percent, g_percent, b_percent)
  elseif mode == "spritesheet" and self.SpriteSheet then
    self.SpriteSheet:setColor(r_percent, g_percent, b_percent)
  end
end
function DynamicSprite:SetAlpha(value)
  local mode = self:getMode()
  if mode == "sprite" and self.Sprite then
    self.Sprite("alpha"):SetFloat(value)
  elseif mode == "anim" and self.Anim then
    self.Anim("alpha"):SetFloat(value)
  elseif mode == "spritesheet" and self.SpriteSheet then
    self.SpriteSheet("alpha"):SetFloat(value)
  end
end
function DynamicSprite:setTempScale(scaleVector)
  self:setScale(scaleVector)
  local mode = self:getMode()
  if mode == "sprite" and self.Sprite then
    self.Sprite:setScale(scaleVector)
  elseif mode == "anim" and self.Anim then
    local scaledScaleVector = lua_sys.Vector2(scaleVector.x * self.currentScale, scaleVector.y * self.currentScale)
    self.Anim:setScale(scaledScaleVector)
  elseif mode == "spritesheet" and self.SpriteSheet then
    self.SpriteSheet:setScale(scaleVector)
  end
end
function DynamicSprite:Show()
  self.isVisible = true
  self:refresh()
end
function DynamicSprite:Hide()
  self.isVisible = false
  if self.Sprite then
    self.Sprite("visible"):SetInt(0)
  end
  if self.Anim then
    self.Anim("visible"):SetInt(0)
  end
  if self.SpriteSheet then
    self.SpriteSheet("visible"):SetInt(0)
  end
end
function DynamicSprite:getMode()
  if self.sheetName == "" then
    return "sprite"
  elseif self.monsterId > -1 or startswith(self.sheetName, "xml_bin") then
    return "anim"
  else
    return "spritesheet"
  end
end
function DynamicSprite:handleComponents()
  if self.Sprite then
    self.Sprite("visible"):SetInt(0)
  end
  if self.Anim then
    self.Anim("visible"):SetInt(0)
  end
  if self.SpriteSheet then
    self.SpriteSheet("visible"):SetInt(0)
  end
  local mode = self:getMode()
  local element
  if mode == "sprite" then
    element = menu:addTemplateElement("template_instancesprite", "iSprite", self)
    element("SpriteName"):SetString("gfx/empty")
    self.Sprite = element:C("Sprite")
  elseif mode == "anim" then
    element = menu:addTemplateElement("template_instanceaecomponent", "iAnim", self)
    element("AnimationName"):SetString("xml_bin/battle_buttons_anim.bin")
    element("Animation"):SetString("clubbox epic pomily")
    self.Anim = element:C("Anim")
  elseif mode == "spritesheet" then
    element = menu:addTemplateElement("template_instancespritesheet", "iSpriteSheet", self)
    element("SpriteName"):SetString("empty")
    element("SheetName"):SetString("xml_resources/empty.xml")
    self.SpriteSheet = element:C("Sprite")
  end
  if element then
    element("Size"):SetFloat(1)
    element("Layer"):SetString(self:templateVars().layer)
    element:setParent(self)
    element:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.VCENTER))
    element:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    element:init()
    element:setPositionBroadcast(true)
  end
end
function DynamicSprite:refresh()
  if not self.isVisible then
    return
  end
  self:handleComponents()
  if self.origXOffset == -1 then
    self.origXOffset = self("xOffset"):GetInt()
  end
  self("xOffset"):SetInt(self.origXOffset)
  if self.origYOffset == -1 then
    self.origYOffset = self("yOffset"):GetInt()
  end
  self("yOffset"):SetInt(self.origYOffset)
  local mode = self:getMode()
  if mode == "sprite" then
    self.Sprite("visible"):SetInt(1)
    self.Sprite("size"):SetInt(1)
    self.Sprite("spriteName"):SetString(self.spriteName)
    local metric = 1
    if self.sizeMode == "width" then
      metric = self.Sprite:absW()
    elseif self.sizeMode == "height" then
      metric = self.Sprite:absH()
    elseif self.sizeMode == "min" then
      metric = math.min(self.Sprite:absW(), self.Sprite:absH())
    elseif self.sizeMode == "max" then
      metric = math.max(self.Sprite:absW(), self.Sprite:absH())
    end
    self.currentScale = self.targetSize / metric * self.scaleMod
    self.Sprite("size"):SetFloat(self.currentScale)
    self:setSize(Vector2(self.Sprite:absW(), self.Sprite:absH()))
  elseif mode == "anim" then
    self.Anim("visible"):SetInt(1)
    self.Anim:setScale(Vector2(1, 1))
    self.Anim("animation"):SetString(self.spriteName)
    self.Anim("animationName"):SetString(self.sheetName)
    if -1 < self.monsterId then
      local viewBounds = MonsterProperties.getIdleViewBounds(self.monsterId, self.Anim:absW(), self.Anim:absH(), self.targetSize, self.targetSize)
      self.currentScale = viewBounds.scale
      self.Anim:setScale(Vector2(self.currentScale, self.currentScale))
      self:setSize(Vector2(self.Anim:absW(), self.Anim:absH()))
      self("xOffset"):SetInt(self.origXOffset + viewBounds.xOffset)
      self("yOffset"):SetInt(self.origYOffset + viewBounds.yOffset)
      local facing = MonsterProperties.getFacing(self.monsterId)
      self.Anim:GetVar("hFlip"):SetInt(facing)
    else
      local metric = 1
      if self.sizeMode == "width" then
        metric = self.Anim:absW()
      elseif self.sizeMode == "height" then
        metric = self.Anim:absH()
      elseif self.sizeMode == "min" then
        metric = math.min(self.Anim:absW(), self.Anim:absH())
      elseif self.sizeMode == "max" then
        metric = math.max(self.Anim:absW(), self.Anim:absH())
      end
      self.currentScale = self.targetSize / metric * self.scaleMod
      self.Anim:setScale(Vector2(self.currentScale, self.currentScale))
      self:setSize(Vector2(self.Anim:absW(), self.Anim:absH()))
    end
  elseif mode == "spritesheet" then
    self.SpriteSheet("visible"):SetInt(1)
    self.SpriteSheet("size"):SetInt(1)
    self.SpriteSheet("spriteName"):SetString(self.spriteName)
    self.SpriteSheet("sheetName"):SetString(self.sheetName)
    local metric = 1
    if self.sizeMode == "width" then
      metric = self.SpriteSheet:absW()
    elseif self.sizeMode == "height" then
      metric = self.SpriteSheet:absH()
    elseif self.sizeMode == "min" then
      metric = math.min(self.SpriteSheet:absW(), self.SpriteSheet:absH())
    elseif self.sizeMode == "max" then
      metric = math.max(self.SpriteSheet:absW(), self.SpriteSheet:absH())
    end
    self.currentScale = self.targetSize / metric * self.scaleMod
    self.SpriteSheet("size"):SetFloat(self.currentScale)
    self:setSize(Vector2(self.SpriteSheet:absW(), self.SpriteSheet:absH()))
  end
end
return DynamicSprite
