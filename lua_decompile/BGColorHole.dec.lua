local Tweener = include("Tweener")
local ShaderColorHole = include("ShaderColorHole")
local BGColorHole = {
  BGColorSprite = {
    Sprite = {}
  }
}
function BGColorHole:Setup()
  local layer = self.layer or "HUD"
  local backgroundImage = self.backgroundImage or "__BUILTIN__WHITE_TEXTURE"
  local holeStartSize = self.holeStartSize or 2
  local holeEndSize = self.holeEndSize or 0.3
  local transitionDuration = self.transitionDuration or 0.5
  local transitionEasing = self.transitionEasing or lua_sys.Quadratic_EaseIn
  local x = self.holeX or lua_sys.screenWidth() / 2
  local y = self.holeY or lua_sys.screenHeight() / 2
  local w = self.spriteW or lua_sys.screenWidth()
  local h = self.spriteH or lua_sys.screenHeight()
  local alpha = self.alpha or 1
  self.BGColorSprite.Sprite:GetVar("spriteName"):SetString(backgroundImage)
  self.BGColorSprite.Sprite:setScale(lua_sys.Vector2(w, h))
  self.BGColorSprite.Sprite:GetVar("layer"):SetString(layer)
  self.BGColorSprite.Sprite:GetVar("alpha"):SetFloat(alpha)
  self.BGColorSprite.Sprite:setShader(ShaderColorHole)
  self.TweenerIn = Tweener:new({
    duration = transitionDuration,
    initialValue = holeStartSize,
    targetValue = holeEndSize,
    ease = transitionEasing,
    onUpdate = function(value)
      if ShaderColorHole then
        ShaderColorHole:getUniform("u_HoleRadius"):setFloat(value)
      end
    end,
    onDone = function()
      if self.onCompleteShow then
        self.onCompleteShow()
      end
    end
  })
  self.TweenerOut = Tweener:new({
    duration = transitionDuration,
    initialValue = holeEndSize,
    targetValue = holeStartSize,
    ease = transitionEasing,
    onUpdate = function(value)
      if ShaderColorHole then
        ShaderColorHole:getUniform("u_HoleRadius"):setFloat(value)
      end
    end,
    onDone = function()
      if self.onCompleteHide then
        self.onCompleteHide()
        self.BGColorSprite.Sprite:GetVar("visible"):SetInt(0)
      end
    end
  })
  self:SetHolePosition(x, y)
end
function BGColorHole:SetHolePosition(x, y)
  self.holeX = x
  self.holeY = y
  local focusPoint = lua_sys.Vector2(x, y)
  if ShaderColorHole then
    ShaderColorHole:getUniform("u_HolePos"):setVec2(focusPoint)
  end
end
function BGColorHole:Show(animate)
  if not self.TweenerIn then
    animate = false
  end
  self.BGColorSprite.Sprite:GetVar("visible"):SetInt(1)
  local x = self.holeX or lua_sys.screenWidth() / 2
  local y = self.holeY or lua_sys.screenHeight() / 2
  self:SetHolePosition(x, y)
  if animate then
    local holeStartSize = self.holeStartSize or 2
    if ShaderColorHole then
      ShaderColorHole:getUniform("u_HoleRadius"):setFloat(holeStartSize)
    end
    self.TweenerIn:activate()
  else
    local holeEndSize = self.holeEndSize or 0.3
    if ShaderColorHole then
      ShaderColorHole:getUniform("u_HoleRadius"):setFloat(holeEndSize)
    end
  end
end
function BGColorHole:Hide(animate)
  if animate and self.TweenerOut then
    self.TweenerOut:activate()
  else
    self.BGColorSprite.Sprite:GetVar("visible"):SetInt(0)
  end
end
function BGColorHole:Tick(dt)
  if self.TweenerIn then
    self.TweenerIn:Tick(dt)
  end
  if self.TweenerOut then
    self.TweenerOut:Tick(dt)
  end
end
return BGColorHole
