local TweenerPingPong = include("TweenerPingPong")
local GetItNowBreed = {transitionState = 1, transitionTime = 0}
function GetItNowBreed:onPostInit()
  self.touches = {
    self.FadedBG.Touch
  }
  self.perceptibles = {
    self.FadedBG.Sprite,
    self.bg.Sprite,
    self.bg.Flourish1,
    self.bg.Flourish2,
    self.ParentEggsImage.Plus.Sprite,
    self.ParentEggsImage.Parent1.Sprite,
    self.ParentEggsImage.Parent2.Sprite,
    self.Prefix.Text,
    self.Time.Text,
    self.Postfix.Text,
    self.Wait.Overlay,
    self.GetItNow.Overlay,
    self.GetItNow.Cost,
    self.SuperChargeStickers.Left,
    self.SuperChargeStickers.Right,
    self.SuperChargeStickers.BottomLeft,
    self.SuperChargeStickers.BottomRight,
    self.LeftFlame.Sprite,
    self.RightFlame.Sprite
  }
  self.perceptiblesAlpha = {}
  for _, perceptible in ipairs(self.perceptibles) do
    local alpha = perceptible("alpha"):GetFloat()
    self.perceptiblesAlpha[perceptible] = alpha
  end
  self.buttons = {
    self.Wait,
    self.GetItNow
  }
  self.transitionState = 0
  self.transitionTime = 1
  self:TickTransition()
  local pulseSize = self.LeftFlame.Sprite:GetVar("size"):GetFloat()
  self.pulser = TweenerPingPong:new({
    loopTime = 0.5,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(target, t)
      target:GetVar("size"):SetFloat(pulseSize * (1 + t * 0.25))
    end,
    targets = {
      self.LeftFlame.Sprite,
      self.RightFlame.Sprite
    }
  })
end
function GetItNowBreed:onTick(dt)
  if self.transitionState ~= 0 then
    self:TickTransition()
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    if 1 < self.transitionTime then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
    elseif 0 > self.transitionTime then
      self:root():popPopUp()
    end
  end
  if self.pulser then
    self.pulser:Tick(dt)
  end
end
function GetItNowBreed:TickTransition()
  self:E("bg")("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self:E("SuperChargeStickers")("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.FadedBG.Sprite("alpha"):SetFloat(self.transitionTime * 0.5)
end
function GetItNowBreed:queuePop()
  print("GetItNowBreed::queuePop()")
  self.transitionState = 2
end
function GetItNowBreed:SetEnabled(enabled)
  for _, touch in ipairs(self.touches) do
    touch:GetVar("enabled"):SetInt(enabled and 1 or 0)
  end
  for _, button in ipairs(self.buttons) do
    button.Touch:GetVar("enabled"):SetInt(enabled and 1 or 0)
  end
end
function GetItNowBreed:SetAlpha(alpha)
  for _, perceptible in ipairs(self.perceptibles) do
    local startingAlpha = self.perceptiblesAlpha[perceptible]
    perceptible("alpha"):SetFloat(alpha * startingAlpha)
  end
  for _, button in ipairs(self.buttons) do
    button:GetVar("alpha"):SetFloat(alpha)
    button:DoStoredScript("updateComponents")
  end
end
function GetItNowBreed:SetSuperCharged()
  self:E("GetItNow"):C("Overlay")("spriteName"):SetString("button_super_charged_diamond")
  local superChargeStickers = self:E("SuperChargeStickers")
  superChargeStickers:C("Left")("visible"):SetInt(1)
  superChargeStickers:C("Right")("visible"):SetInt(1)
  superChargeStickers:C("BottomLeft")("visible"):SetInt(1)
  superChargeStickers:C("BottomRight")("visible"):SetInt(1)
end
function GetItNowBreed:SetLucky()
  local palette = include("ColourPalette")
  local color = palette.LUCKY_BREED
  local spriteName = "torch_icon"
  if game.numPermaLitTorches() > 0 then
    color = palette.LUCKY_BREED_INFINITE
    spriteName = "torch_icon_infinite_small"
  end
  self.LeftFlame.Sprite:GetVar("spriteName"):SetString(spriteName)
  self.RightFlame.Sprite:GetVar("spriteName"):SetString(spriteName)
  self.Time.Text:setColor(palette:getRGBFloats(color))
  self.LeftFlame.Sprite:GetVar("visible"):SetInt(1)
  self.RightFlame.Sprite:GetVar("visible"):SetInt(1)
  self.Prefix.Text:GetVar("text"):SetString("BREEDING_GETNOW_LUCKY_PREFIX")
end
return GetItNowBreed
