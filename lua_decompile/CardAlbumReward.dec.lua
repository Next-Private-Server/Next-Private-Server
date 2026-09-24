local RewardProperties = include("RewardProperties")
local CardAlbumReward = {}
function CardAlbumReward:Init(rewardData, idx, options)
  self.idx = idx
  local appearance = RewardProperties:getRewardAppearance(rewardData, options)
  self.appearance = appearance
  if not appearance then
    print("Couldn't find appearance for reward type = ", rewardData.type)
  end
  self.ItemTitle = appearance.name or ""
  self.AnimationFile = appearance.animFile or ""
  self.AnimationName = appearance.animName or ""
  self.CostumeId = appearance.costumeId or 0
  self.BgAnimationFile = appearance.bgAnimFile or ""
  self.BgAnimationName = appearance.bgAnimName or ""
  self.ForceSpriteName = appearance.forceSpriteName or ""
  self.ForceSpriteSheetName = appearance.forceSpriteSheetName or ""
  self.ForceText = appearance.forceText or ""
  self.SoundFile = appearance.soundFile or ""
  if not appearance.tint then
    local tint = {
      r = 1,
      g = 1,
      b = 1
    }
  end
  self.TintR = tint.r
  self.TintG = tint.g
  self.TintB = tint.b
  self.appearance = appearance
  self.customSetupFunc = appearance.customSetupFunc
  if 0 < string.len(self.AnimationFile) then
    self.Anim.Sprite:V("animationName"):SetString("xml_bin/" .. self.AnimationFile)
    self.Anim.Sprite:V("animation"):SetString(self.AnimationName)
    local costumeId = self.CostumeId
    if costumeId > 0 then
      game.applyCostumeToAnimComponent(self.Anim.Sprite, costumeId)
    end
    local scale = 0.75 * self.Anim:templateVars().scale
    self.Anim.Sprite:setScale(Vector2(scale, scale))
    self.Anim.Sprite:V("layer"):SetString(self.Anim:templateVars().layer)
  else
    self.Anim.Sprite:V("visible"):SetInt(0)
  end
  if 0 < string.len(self.BgAnimationFile) then
    self.Anim.SpriteBG:V("animationName"):SetString("xml_bin/" .. self.BgAnimationFile)
    self.Anim.SpriteBG:V("animation"):SetString(self.BgAnimationName)
    local scale = 0.75 * self.Anim:templateVars().scale
    self.Anim.SpriteBG:setScale(Vector2(scale, scale))
    self.Anim.SpriteBG:V("layer"):SetString(self.Anim:templateVars().layer)
    self.hasSpriteBG = true
  else
    self.Anim.SpriteBG:V("visible"):SetInt(0)
  end
  if 0 < string.len(self.ForceSpriteName) then
    if 0 < string.len(self.ForceSpriteSheetName) then
      self.Anim.ForcedSpriteSheet:V("size"):SetFloat(1)
      self.Anim.ForcedSpriteSheet:V("spriteName"):SetString(self.ForceSpriteName)
      self.Anim.ForcedSpriteSheet:V("sheetName"):SetString(self.ForceSpriteSheetName)
      local hScale = self:absH() / self.Anim.ForcedSpriteSheet:absH()
      local wScale = self:absW() / self.Anim.ForcedSpriteSheet:absW()
      self.Anim.ForcedSpriteSheet:V("size"):SetFloat(0.9 * math.min(hScale, wScale))
      self.hasForcedSpriteSheet = true
      self.Anim.ForcedSpriteSheet:V("visible"):SetInt(1)
      self.Anim.ForcedSprite:V("visible"):SetInt(0)
    else
      self.Anim.ForcedSprite:V("size"):SetFloat(1)
      self.Anim.ForcedSprite:V("spriteName"):SetString(self.ForceSpriteName)
      local hScale = self:absH() / self.Anim.ForcedSprite:absH()
      local wScale = self:absW() / self.Anim.ForcedSprite:absW()
      self.Anim.ForcedSprite:V("size"):SetFloat(0.9 * math.min(hScale, wScale))
      self.hasForcedSprite = true
      self.Anim.ForcedSprite:V("visible"):SetInt(1)
      self.Anim.ForcedSpriteSheet:V("visible"):SetInt(0)
    end
  else
    self.Anim.ForcedSprite:V("visible"):SetInt(0)
    self.Anim.ForcedSpriteSheet:V("visible"):SetInt(0)
  end
  self.Anim.ForcedText:V("size"):SetFloat(1)
  self.Anim.ForcedText:V("text"):SetString(self.ForceText)
  self.Anim.ForcedText:V("size"):SetFloat(0.8 * self:absW() / self.Anim.ForcedText:absW())
  self.NameFrame.Text:V("text"):SetString(self.ItemTitle)
  self.NameFrame.Text:setColor(tint.r, tint.g, tint.b)
  self.NameFrame.Sprite:V("visible"):SetInt(1)
  if self.appearance.spore then
    local anim = self.Anim.Sprite
    anim:AddRemap("SPORE", self.appearance.spore)
    anim:calculatePosition()
  end
  if self.appearance.dipster_door and self.appearance.dipster_door_frame then
    local anim = self.Anim.Sprite
    anim:AddRemap("egg_dipster_do.png", self.appearance.dipster_door, "", false)
    anim:AddRemap("frame", "dipster_door_sheet.xml", self.appearance.dipster_door_frame, false)
    anim:AddRemap("door_back", "dipster_door_sheet.xml", self.appearance.dipster_door_back, false)
    anim:AddRemap("door_shade", "dipster_door_sheet.xml", self.appearance.dipster_door_shade, true)
    anim:calculatePosition()
  end
  local offsetY = self.appearance.animOffsetY or 0
  self.Anim.Sprite:setOrientationPosition(lua_sys.Vector2(0, offsetY))
  if self.customSetupFunc then
    self:customSetupFunc()
  end
  self.refresh = true
end
function CardAlbumReward:onPostInit()
  self.tickables = {}
  self.refresh = false
end
function CardAlbumReward:onTick(dt)
  for _, tickable in ipairs(self.tickables) do
    tickable:Tick(dt)
  end
  if self.refresh then
    local targetW = self.NameFrame.Text:absW() + 32 * self.NameFrame:templateVars().scale
    local targetH = self.NameFrame.Text:absH() + 16 * self.NameFrame:templateVars().scale
    local scaleX = targetW / 150
    local scaleY = targetH / 110
    self.NameFrame.Sprite:setScale(Vector2(scaleX, scaleY))
  end
end
function CardAlbumReward:updateAlpha(alpha)
  self.Anim.Sprite:GetVar("alpha"):SetFloat(alpha)
  self.Anim.Sprite:setColor(alpha, alpha, alpha)
  self.Anim.SpriteBG:GetVar("alpha"):SetFloat(alpha)
  self.Anim.SpriteBG:setColor(alpha, alpha, alpha)
  self.Anim.ForcedSpriteSheet:GetVar("alpha"):SetFloat(alpha)
  self.Anim.ForcedSprite:GetVar("alpha"):SetFloat(alpha)
  self.Anim.ForcedText:GetVar("alpha"):SetFloat(alpha)
  self.NameFrame.Text:GetVar("alpha"):SetFloat(alpha)
  self.NameFrame.Sprite:GetVar("alpha"):SetFloat(0.8 * alpha)
end
function CardAlbumReward:setVisible(visible)
  self.Anim.Sprite:GetVar("visible"):SetInt(visible)
  if self.hasSpriteBG then
    self.Anim.SpriteBG:GetVar("visible"):SetInt(visible)
  end
  if self.hasForcedSpriteSheet then
    self.Anim.ForcedSpriteSheet:GetVar("visible"):SetInt(visible)
  end
  if self.hasForcedSprite then
    self.Anim.ForcedSprite:GetVar("visible"):SetInt(visible)
  end
  self.Anim.ForcedText:GetVar("visible"):SetInt(visible)
  self.NameFrame.Sprite:GetVar("visible"):SetInt(visible)
  self.NameFrame.Text:GetVar("visible"):SetInt(visible)
end
return CardAlbumReward
