local ColourPalette = include("ColourPalette")
local MinigameTopPrizes = {
  Flag = {},
  Top = {
    WoodPlank = {},
    TimerBacking = {},
    Text = {}
  },
  TopPrizeText = {
    Text = {},
    InfoSprite = {}
  },
  Prize1 = {
    Anim = {},
    Text = {}
  },
  Prize2 = {
    Anim = {},
    Text = {}
  },
  Prize3 = {
    Anim = {},
    Text = {}
  },
  Touch = {}
}
function MinigameTopPrizes:onInit()
  self.startTime = game.serverTime()
  self.tickTimer = 0
  self.originalScale = self:templateVars().scale
  self.yellow_r, self.yellow_g, self.yellow_b = ColourPalette:getRGBFloats(ColourPalette.TITLE_YELLOW)
end
function MinigameTopPrizes:onPostInit()
end
function MinigameTopPrizes:onDestroy()
  if self.startTime ~= nil then
    game.logEvent("minigame_top_prize_hud", "time_spent_secs", tostring((game.serverTime() - self.startTime) / 1000))
    self.startTime = 0
  end
end
function MinigameTopPrizes:onTick(dt)
  if self.buttonState ~= game.BUTTON_IDLE then
    self.tickTimer = self.tickTimer + dt
    if self.buttonState == game.BUTTON_PRESSED then
      local size = lua_sys.smooth(self.originalScale, self.originalScale - 0.03, self.tickTimer * 15)
      local scalePercent = size / self.originalScale
      self:setTempScale(scalePercent)
      if size == self.originalScale - 0.03 then
        self.buttonState = game.BUTTON_IDLE
      end
    elseif self.buttonState == game.BUTTON_RELEASED then
      if self.tickTimer < 0.1 then
        local size = lua_sys.smooth(self.originalScale - 0.03, self.originalScale + 0.05, self.tickTimer * 20)
        local scalePercent = size / self.originalScale
        self:setTempScale(scalePercent)
      elseif self.tickTimer < 0.3 then
        local size = lua_sys.smooth(self.originalScale + 0.05, self.originalScale, (self.tickTimer - 0.1) * 20)
        local scalePercent = size / self.originalScale
        self:setTempScale(scalePercent)
        if size == self.originalScale then
          self.buttonState = game.BUTTON_IDLE
        end
      else
        self:setTempScale(1)
        self.buttonState = game.BUTTON_IDLE
      end
    end
  end
end
function MinigameTopPrizes:setColorPercent(percent)
  self.colorPercent = percent
  self.Flag:setColor(percent, percent, percent)
  self.Top.WoodPlank:setColor(percent, percent, percent)
  self.Top.Text:setColor(percent, percent, percent)
  self.TopPrizeText.Text:setColor(self.yellow_r * percent, self.yellow_g * percent, self.yellow_b * percent)
  self.TopPrizeText.InfoSprite:setColor(percent, percent, percent)
  self.Prize1.Anim:setColor(percent, percent, percent)
  self.Prize1.Text:setColor(percent, percent, percent)
  self.Prize2.Anim:setColor(percent, percent, percent)
  self.Prize2.Text:setColor(percent, percent, percent)
  self.Prize3.Anim:setColor(percent, percent, percent)
  self.Prize3.Text:setColor(percent, percent, percent)
end
function MinigameTopPrizes:setTempScale(scale)
  local scaleVector = lua_sys.Vector2(scale, scale)
  local scaleWithOriginal = scale * self.originalScale
  self.Flag:GetVar("width"):SetFloat(100 * scaleWithOriginal)
  self.Flag:GetVar("height"):SetFloat(230 * scaleWithOriginal)
  self.Top.WoodPlank:setScale(Vector2(0.18404907975460122 * scaleWithOriginal, 0.3488372093023256 * scaleWithOriginal))
  self.Top.TimerBacking:GetVar("width"):SetFloat(70 * scaleWithOriginal)
  self.Top.TimerBacking:GetVar("height"):SetFloat(16 * scaleWithOriginal)
  self.Top.Text:setScale(scaleVector)
  self.TopPrizeText.Text:setScale(scaleVector)
  self.TopPrizeText.InfoSprite:setScale(scaleVector)
  self.Prize1.Text:setScale(scaleVector)
  self.Prize2.Text:setScale(scaleVector)
  self.Prize3.Text:setScale(scaleVector)
  scaleVector = lua_sys.Vector2(0.45 * scaleWithOriginal, 0.45 * scaleWithOriginal)
  self.Prize1.Anim:setScale(scaleVector)
  self.Prize2.Anim:setScale(scaleVector)
  self.Prize3.Anim:setScale(scaleVector)
end
function MinigameTopPrizes:Hide()
  self.Flag("visible"):SetInt(0)
  self.Top.WoodPlank("visible"):SetInt(0)
  self.Top.TimerBacking("visible"):SetInt(0)
  self.Top.Text("visible"):SetInt(0)
  self.TopPrizeText.Text("visible"):SetInt(0)
  self.TopPrizeText.InfoSprite("visible"):SetInt(0)
  self.Prize1.Anim("visible"):SetInt(0)
  self.Prize1.Text("visible"):SetInt(0)
  self.Prize2.Anim("visible"):SetInt(0)
  self.Prize2.Text("visible"):SetInt(0)
  self.Prize3.Anim("visible"):SetInt(0)
  self.Prize3.Text("visible"):SetInt(0)
end
function MinigameTopPrizes:Show()
  self.Flag("visible"):SetInt(1)
  self.Top.WoodPlank("visible"):SetInt(1)
  self.Top.TimerBacking("visible"):SetInt(1)
  self.Top.Text("visible"):SetInt(1)
  self.TopPrizeText.Text("visible"):SetInt(1)
  self.TopPrizeText.InfoSprite("visible"):SetInt(1)
  self.Prize1.Anim("visible"):SetInt(1)
  self.Prize1.Text("visible"):SetInt(1)
  self.Prize2.Anim("visible"):SetInt(1)
  self.Prize2.Text("visible"):SetInt(1)
  self.Prize3.Anim("visible"):SetInt(1)
  self.Prize3.Text("visible"):SetInt(1)
end
return MinigameTopPrizes
