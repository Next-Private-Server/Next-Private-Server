local CurrencyCounterAvatarXP = {
  ProfilePic = {},
  XpBarBacking = {
    Sprite = {}
  },
  XpBar = {
    Sprite = {}
  }
}
local FADE_OUT_DELAY = 1.5
local FADE_OUT_TIME = 0.5
local FADE_IN_TIME = 0.1
function CurrencyCounterAvatarXP:onPostInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgFlyingIconLanded", "gotMsgFlyingIconLanded")
  local profileScale = self.ProfilePic:templateVars().scale
  self.ProfilePic.Level.Icon("spriteName"):SetString("PlayerLevel_Star_HUD")
  self.ProfilePic.Level.Icon("size"):SetFloat(0.28 * profileScale)
  self.ProfilePic.Level("xOffset"):SetFloat(-12 * profileScale)
  self.ProfilePic.Level("yOffset"):SetFloat(-10 * profileScale)
  self.ProfilePic("textScale"):SetFloat(1.6 * profileScale / game.hudScale())
  local profile = game.playerProfile()
  self.ProfilePic:SetAvatarData(profile:getPlayerAvatar())
  local level = game.playerLevel()
  self.ProfilePic:SetLevel(level)
  self.XpBar:updateXpBar()
  self.doInitTick = true
  self.originalXOffset = self:GetVar("xOffset"):GetFloat()
  self.currentAlpha = 0
  self.targetAlpha = 0
  self.fadeOutDelay = 0
  self:setAlpha(self.currentAlpha)
  self:GetVar("xOffset"):SetFloat(self.originalXOffset - self.XpBarBacking:absW())
end
function CurrencyCounterAvatarXP:onTick(dt)
  if self.doInitTick then
    self.doInitTick = false
    self.XpBar:updateClipping()
  end
  if self.currentAlpha ~= self.targetAlpha then
    if self.targetAlpha < self.currentAlpha then
      self.currentAlpha = math.max(0, self.currentAlpha - dt / FADE_OUT_TIME)
    else
      self.currentAlpha = math.min(1, self.currentAlpha + dt / FADE_IN_TIME)
    end
    self:setAlpha(self.currentAlpha)
    local targetPosX = self.originalXOffset - (self.XpBarBacking:absW() - math.min(1, self.currentAlpha) * self.XpBarBacking:absW())
    local currentPosX = self:GetVar("xOffset"):GetFloat()
    if targetPosX ~= currentPosX then
      local diff = currentPosX - targetPosX
      if math.abs(diff) > 20 then
        diff = diff * 0.333
      end
      self:GetVar("xOffset"):SetFloat(currentPosX - diff)
      self.XpBar:updateClipping()
    end
    if self.currentAlpha == 1 then
      self.XpBar:updateXpBar()
      self.fadeOutDelay = FADE_OUT_DELAY
    end
  end
  if 0 < self.fadeOutDelay then
    self.fadeOutDelay = self.fadeOutDelay - dt
    if 0 >= self.fadeOutDelay then
      self.targetAlpha = 0
    end
  end
end
function CurrencyCounterAvatarXP:setAlpha(value)
  self.ProfilePic:setAlpha(value)
  self.XpBar.Sprite("alpha"):SetFloat(value)
  self.XpBarBacking.Sprite("alpha"):SetFloat(value)
end
function CurrencyCounterAvatarXP:gotMsgFlyingIconLanded(msg)
  local currencyType = game.Currencies_LootTypeToCurrencyType(msg.type)
  if currencyType == game.CurrencyType_Xp then
    self.targetAlpha = 1
  end
end
function CurrencyCounterAvatarXP.XpBar:updateClipping()
  local xpBarBacking = self:parent().XpBarBacking
  local halfHeight = xpBarBacking:absH() * 0.5
  local clipX = xpBarBacking:absX()
  local clipY = xpBarBacking:absY() + halfHeight + 4 * self:parent().ProfilePic:templateVars().scale
  local clipW = xpBarBacking:absW()
  local clipH = halfHeight
  self.Sprite:setClipRect(clipX, clipY, clipW, clipH)
end
function CurrencyCounterAvatarXP.XpBar:updateXpBar()
  local currentXp = game.playerCurrentXp()
  local totalXp = game.playerXpForLevel()
  local percent = math.max(0, math.min(1, currentXp / totalXp))
  print("updateXpBar")
  print("currentXp: " .. currentXp)
  print("totalXp: " .. totalXp)
  print("percent: " .. percent)
  local angle = self.totalAngle - self.totalAngle * percent
  self.originalAngle = self.targetAngle
  self.targetAngle = angle
  self.actualTargetAngle = angle
  local level = game.playerLevel()
  self.levelDiff = level - self.currentLevel
  if self.originalAngle == -1 then
    self:updateClipping()
    self.transitionTime = 0
  elseif 0 < self.levelDiff then
    self.targetAngle = 0
    self.transitionTime = 0.25
    self:parent().ProfilePic:SetLevel(self.currentLevel)
  elseif self.targetAngle == self.originalAngle then
    self.transitionTime = 0
  else
    self.transitionTime = 0.25
  end
  self.isAnimating = true
end
function CurrencyCounterAvatarXP.XpBar:onTick(dt)
  if self.isAnimating then
    dt = math.min(dt, 0.033)
    self.transitionTime = math.max(0, self.transitionTime - dt)
    local easedTime = 1 - lua_sys.Quadratic_EaseIn(self.transitionTime, 0, 1, 0.25)
    local angle = lerp(self.originalAngle, self.targetAngle, easedTime)
    if angle <= 0 then
      angle = angle + self.totalAngle
      self.levelDiff = self.levelDiff - 1
      if 0 < self.levelDiff then
        self.targetAngle = 0
      else
        self.targetAngle = self.actualTargetAngle
      end
      self.originalAngle = self.totalAngle
      self.transitionTime = 0.25
      self.currentLevel = self.currentLevel + 1
      self:parent().ProfilePic:SetLevel(self.currentLevel)
    end
    self.Sprite:V("rotation"):SetFloat(angle)
    if self.transitionTime <= 0 then
      self.isAnimating = false
      local level = 0
      level = game.playerLevel()
      self.currentLevel = level
      self:parent().ProfilePic:SetLevel(level)
    end
  end
end
return CurrencyCounterAvatarXP
