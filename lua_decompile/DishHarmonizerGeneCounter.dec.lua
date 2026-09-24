local Tweener = include("Tweener")
local DishHarmonizerGeneCounter = {
  GeneSprite = {},
  Animation = {},
  Text = {},
  InfiniteSprite = {},
  UpArrow = {
    Sprite = {}
  },
  DownArrow = {
    Sprite = {}
  }
}
function DishHarmonizerGeneCounter:onInit()
  self.isInfinite = false
  self.TestUIEnabled = false
end
function DishHarmonizerGeneCounter:onPostInit()
  self:refreshSize()
end
function DishHarmonizerGeneCounter:enableTestUI()
  if game.isQABuild() and self.isInfinite == false then
    self.UpArrow.Sprite:V("visible"):SetInt(1)
    self.DownArrow.Sprite:V("visible"):SetInt(1)
    self:setAddGeneDisabled(false)
    self.TestUIEnabled = true
  end
end
function DishHarmonizerGeneCounter:refreshSize()
  local totalWidth = self.GeneSprite:absW() + self.Text:absW()
  if self.InfiniteSprite:C("Sprite"):V("visible"):GetInt() == 1 then
    totalWidth = totalWidth + self.InfiniteSprite:absW()
  end
  self:setSize(lua_sys.Vector2(totalWidth, self.GeneSprite:absH()))
  local animationScale = self.Animation:V("animationScale"):GetFloat()
  self.Animation("xOffset"):SetFloat(35 * self:templateVars().scale * animationScale)
  self.Animation("yOffset"):SetFloat(35 * self:templateVars().scale * animationScale)
  self.Text("xOffset"):SetInt(-6 * self:templateVars().scale)
  self.InfiniteSprite("xOffset"):SetInt(-2 * self:templateVars().scale)
end
function DishHarmonizerGeneCounter:setCounter(count)
  self:V("Count"):SetInt(count)
  self.Text:C("Text"):V("text"):SetString("x" .. count)
  if game.isQABuild() and self.isInfinite == false and self.TestUIEnabled then
    if count == 0 then
      self:setRemoveGeneDisabled(true)
    else
      self:setRemoveGeneDisabled(false)
    end
  end
end
function DishHarmonizerGeneCounter:setCounterColor(r, g, b)
  self.Text:C("Text"):setColor(r, g, b)
end
function DishHarmonizerGeneCounter:fadeInOutColor(colorR, colorG, colorB, delayIn, durationIn, delayOut, durationOut)
  local text = self.Text
  text.startR = 1
  text.startG = 1
  text.startB = 1
  text.targetR = colorR
  text.targetG = colorG
  text.targetB = colorB
  self.Text.ColorTween = Tweener:new({
    delay = delayIn,
    duration = durationIn,
    initialValue = 0,
    targetValue = 1,
    onUpdate = function(value)
      local r = text.startR + (text.targetR - text.startR) * value
      local g = text.startG + (text.targetG - text.startG) * value
      local b = text.startB + (text.targetB - text.startB) * value
      text.currentR = r
      text.currentG = g
      text.currentB = b
      text:C("Text"):setColor(r, g, b)
      local scale = 1 + 0.25 * (1 - value)
      text:C("Text"):setScale(Vector2(scale, scale))
    end,
    onDone = function()
      self:fadeColor(colorR, colorG, colorB, delayOut, durationOut)
    end
  })
  self.Text.ColorTween:activate()
end
function DishHarmonizerGeneCounter:fadeColor(startR, startG, startB, delay, duration)
  delay = delay or 0.5
  duration = duration or 0.5
  self.Text:C("Text"):setColor(startR, startG, startB)
  local text = self.Text
  text.startR = startR
  text.startG = startG
  text.startB = startB
  text.targetR = 1
  text.targetG = 1
  text.targetB = 1
  self.Text.ColorTween = Tweener:new({
    delay = delay,
    duration = duration,
    initialValue = 0,
    targetValue = 1,
    onUpdate = function(value)
      local r = text.startR + (text.targetR - text.startR) * value
      local g = text.startG + (text.targetG - text.startG) * value
      local b = text.startB + (text.targetB - text.startB) * value
      text.currentR = r
      text.currentG = g
      text.currentB = b
      text:C("Text"):setColor(r, g, b)
    end,
    onPostDelay = function()
    end
  })
  self.Text.ColorTween:activate()
end
function DishHarmonizerGeneCounter:setInfinite()
  self.isInfinite = true
  self.Text:C("Text"):V("text"):SetString("x")
  self.InfiniteSprite:C("Sprite"):V("visible"):SetInt(1)
  self:refreshSize()
  if game.isQABuild() and self.TestUIEnabled then
    self.UpArrow.Sprite:V("visible"):SetInt(0)
    self.DownArrow.Sprite:V("visible"):SetInt(0)
  end
end
function DishHarmonizerGeneCounter:playAnimation()
  self.Animation:C("Sprite"):V("visible"):SetInt(1)
  self.Animation:C("Sprite"):V("animation"):SetString("sigil_burst")
  self.Animation:C("Effect"):start()
end
function DishHarmonizerGeneCounter:onTick(dt)
  if self.Text.ColorTween ~= nil then
    self.Text.ColorTween:Tick(dt)
  end
end
function DishHarmonizerGeneCounter:setAddGeneDisabled(disabled)
  self.UpArrow.isDisabled = disabled
  if self.UpArrow.isDisabled then
    self.UpArrow.Sprite:setColor(0.5, 0.5, 0.5)
  else
    self.UpArrow.Sprite:setColor(1, 1, 1)
  end
end
function DishHarmonizerGeneCounter:setRemoveGeneDisabled(disabled)
  self.DownArrow.isDisabled = disabled
  if self.DownArrow.isDisabled then
    self.DownArrow.Sprite:setColor(0.5, 0.5, 0.5)
  else
    self.DownArrow.Sprite:setColor(1, 1, 1)
  end
end
return DishHarmonizerGeneCounter
