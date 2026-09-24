local MenuHelpers = include("MenuHelpers")
local OffsetTransition = include("OffsetTransition")
local TweenerPingPong = include("TweenerPingPong")
local RewardProperties = include("RewardProperties")
local DCLReward = {
  ParticleSplash = {
    Sprite = {}
  }
}
function DCLReward:Init(rewardData, idx, options)
  self.data = rewardData
  self.idx = idx
  local appearance = RewardProperties:getRewardAppearance(rewardData, options)
  if not appearance then
    print("Couldn't find appearance for reward type = ", rewardData.type)
    return
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
end
function DCLReward:onInit()
  self.onPostInitRun = false
end
function DCLReward:onPostInit()
  if self.onPostInitRun then
    return
  end
  self.onPostInitRun = true
  self.tickables = {}
  self.gfxList = {
    self.Anim.Sprite,
    self.Anim.SpriteBG,
    self.Anim.ForcedSpriteSheet,
    self.Anim.ForcedSprite,
    self.Anim.ForcedText,
    self.NameFrame.Text,
    self.NameFrame.Sprite
  }
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
  self:updateAlpha(0)
end
function DCLReward:onTick(dt)
  dt = math.min(dt, 0.033)
  for _, tickable in ipairs(self.tickables) do
    tickable:Tick(dt)
  end
end
function DCLReward:updateClippingEx(clipX, clipY, clipW, clipH)
  for _, v in ipairs(self.gfxList) do
    v:setClipRect(clipX, clipY, clipW, clipH)
  end
end
function DCLReward:updateClipping()
  self:updateClippingEx(self("clipX"):GetFloat(), self("clipY"):GetFloat(), self("clipW"):GetFloat(), self("clipH"):GetFloat())
end
function DCLReward:updateAlpha(alpha)
  for _, v in ipairs(self.gfxList) do
    v:GetVar("alpha"):SetFloat(alpha)
  end
  self.Anim.Sprite:setColor(alpha, alpha, alpha)
  self.Anim.SpriteBG:setColor(alpha, alpha, alpha)
  self.NameFrame.Sprite:GetVar("alpha"):SetFloat(0.8 * alpha)
end
function DCLReward:SetVisible(visible)
  local visInt = visible and 1 or 0
  for _, v in ipairs(self.gfxList) do
    v:GetVar("visible"):SetInt(visInt)
  end
end
return DCLReward
