local Tweener = include("Tweener")
local ShaderHole = include("ShaderHole")
local ShaderScrollingPatternWithHole = include("ShaderScrollingPatternWithHole")
local BGHole = {
  BGGradient = {
    Sprite = {}
  },
  BGPattern = {
    Sprite = {}
  }
}
BGHole.State = {
  None = 0,
  Showing = 1,
  Hiding = 2
}
function BGHole:Setup(props)
  print("setup hole")
  props = props or {}
  self.layer = props.layer or "HUD"
  self.gradientImage = props.gradientImage or "gfx/menu/gradient_bg_map"
  self.patternImage = props.patternImage or "gfx/menu/bg_symbols_map"
  self.holeStartSize = props.holeStartSize or 2
  self.holeEndSize = props.holeEndSize or 0.3
  self.transitionDuration = props.transitionDuration or 0.5
  self.transitionEasing = props.transitionEasing or lua_sys.Quadratic_EaseIn
  self.holeX = props.holeX or 0.5
  self.holeY = props.holeY or 0.5
  self.onComplete = props.onComplete
  self.state = BGHole.State.None
  self.BGGradient.Sprite:GetVar("spriteName"):SetString(self.gradientImage)
  self.BGGradient.Sprite:setScale(lua_sys.Vector2(lua_sys.screenWidth() / 1024, lua_sys.screenHeight() / 4))
  self.BGGradient.Sprite:GetVar("layer"):SetString(self.layer)
  self.BGGradient.Sprite:setShader(ShaderHole)
  self.BGPattern.Sprite:GetVar("spriteName"):SetString(self.patternImage)
  self.BGPattern.Sprite:setScale(lua_sys.Vector2(lua_sys.screenWidth() / 128, lua_sys.screenHeight() / 128))
  self.BGPattern.Sprite:GetVar("layer"):SetString(self.layer)
  self.BGPattern.Sprite:GetVar("alpha"):SetFloat(1)
  self.BGPattern.Sprite:GetVar("repeating"):SetInt(1)
  self.BGPattern.Sprite:GetVar("additive"):SetInt(1)
  self.BGPattern.Sprite:setShader(ShaderScrollingPatternWithHole)
  self.Tweener = Tweener:new({
    duration = self.transitionDuration,
    initialValue = self.holeStartSize,
    targetValue = self.holeEndSize,
    ease = self.transitionEasing,
    onUpdate = function(value)
      if ShaderHole and ShaderHole:hasUniform("u_HoleRadius") then
        ShaderHole:getUniform("u_HoleRadius"):setFloat(value)
      end
      if ShaderScrollingPatternWithHole and ShaderScrollingPatternWithHole:hasUniform("u_HoleRadius") then
        ShaderScrollingPatternWithHole:getUniform("u_HoleRadius"):setFloat(value)
      end
    end,
    onDone = function()
      print("Hole Tweener onComplete", self.state)
      local lastState = self.state
      self.state = BGHole.State.None
      if lastState == BGHole.State.Hiding then
        self.BGGradient.Sprite:GetVar("visible"):SetInt(0)
        self.BGPattern.Sprite:GetVar("visible"):SetInt(0)
      end
      if self.onComplete then
        self.onComplete(lastState)
      end
    end
  })
  self:SetHolePosition(self.holeX, self.holeY)
end
function BGHole:SetHolePosition(x, y)
  self.holeX = x
  self.holeY = y
  local focusPoint = lua_sys.Vector2(x, y)
  if ShaderHole and ShaderHole:hasUniform("u_HolePos") then
    ShaderHole:getUniform("u_HolePos"):setVec2(focusPoint)
  end
  if ShaderScrollingPatternWithHole and ShaderScrollingPatternWithHole:hasUniform("u_HolePos") then
    ShaderScrollingPatternWithHole:getUniform("u_HolePos"):setVec2(focusPoint)
  end
end
function BGHole:Show(animate)
  animate = animate or true
  if not self.Tweener then
    return
  end
  self.state = BGHole.State.Showing
  self.BGGradient.Sprite:GetVar("visible"):SetInt(1)
  self.BGPattern.Sprite:GetVar("visible"):SetInt(1)
  self:SetHolePosition(self.holeX, self.holeY)
  if animate then
    self.Tweener.initialValue = self.holeStartSize
    self.Tweener.targetValue = self.holeEndSize
    self.Tweener:activate()
  else
    if ShaderHole and ShaderHole:hasUniform("u_HoleRadius") then
      ShaderHole:getUniform("u_HoleRadius"):setFloat(self.holeEndSize)
    end
    if ShaderScrollingPatternWithHole and ShaderScrollingPatternWithHole:hasUniform("u_HoleRadius") then
      ShaderScrollingPatternWithHole:getUniform("u_HoleRadius"):setFloat(self.holeEndSize)
    end
  end
end
function BGHole:Hide(animate)
  animate = animate or false
  print("Hiding hole...", animate)
  self.state = BGHole.State.Hiding
  if animate then
    self.Tweener.initialValue = self.holeEndSize
    self.Tweener.targetValue = self.holeStartSize
    self.Tweener:activate()
  else
    if self.holeStartSize then
      if ShaderHole and ShaderHole:hasUniform("u_HoleRadius") then
        ShaderHole:getUniform("u_HoleRadius"):setFloat(self.holeStartSize)
      end
      if ShaderScrollingPatternWithHole and ShaderScrollingPatternWithHole:hasUniform("u_HoleRadius") then
        ShaderScrollingPatternWithHole:getUniform("u_HoleRadius"):setFloat(self.holeStartSize)
      end
    end
    self.BGGradient.Sprite:GetVar("visible"):SetInt(0)
    self.BGPattern.Sprite:GetVar("visible"):SetInt(0)
  end
end
function BGHole:Tick(dt)
  if self.Tweener then
    self.Tweener:Tick(dt)
  end
end
return BGHole
