local EncoreRewardTrackBar = {
  RewardBar = {},
  EventType = {
    BackingSprite = {},
    Sprite = {}
  },
  FlagSprite = {},
  Timer = {
    Sprite = {},
    Text = {}
  }
}
function EncoreRewardTrackBar:onInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgEncoreEvent", "gotMsgEncoreEvent")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgEncoreRefresh", "gotMsgEncoreRefresh")
  if self.RewardBar then
    self.RewardBar.sfxStart = "audio/sfx/encore_progressbar_fillstart.ogg"
    self.RewardBar.sfxTick = "audio/sfx/encore_progressbar_filltick.wav"
    self.RewardBar.sfxEndBar = "audio/sfx/encore_progressbar_full.ogg"
    self.RewardBar.sfxRewards = "audio/sfx/encore_reward_popup.ogg"
    self.RewardBar.BarSprite:GetVar("yOffset"):SetInt(-2 * self:templateVars().scale)
    self.RewardBar.Text:GetVar("yOffset"):SetInt(-2 * self:templateVars().scale)
  end
  self.visibleOnIsland = 1
end
function EncoreRewardTrackBar:onPostInit()
  self:reset()
  self:checkForEncoreEvent()
  if self.RewardBar then
    self.RewardBar.rewardVisiblity = {
      1,
      0,
      0
    }
  end
end
function EncoreRewardTrackBar:reset()
  self.timeTick = 0
  self.buttonState = game.BUTTON_IDLE
  self.tickTimer = 1
  self.originalScale = self:templateVars().scale
  self.isVisible = 1
  self.doingEncoreTutorial = false
  self.refreshDelay = 10000000000
  self.encoreEvent = nil
  if self.RewardBar then
    self.RewardBar:reset()
  end
end
function EncoreRewardTrackBar:gotMsgEncoreEvent(msg)
  local rewards = msg:rewards()
  if rewards:size() > 0 then
    for i = 0, rewards:size() - 1 do
      do
        local reward = rewards[i]
        local mailId = 0
        if reward.getExtraLong then
          mailId = reward:getExtraLong("mail_id")
        end
        local isBoxFilled = false
        if reward.getExtraBool then
          isBoxFilled = reward:getExtraBool("box_filled")
        end
        local function getExtraBool(reward, key)
          if key == "box_filled" then
            return isBoxFilled
          end
          return false
        end
        local function getExtraLong(reward, key)
          if key == "mail_id" then
            return mailId
          end
          return 0
        end
        table.insert(self.RewardBar.pendingRewards, {
          id = reward.id,
          type = reward.type,
          amount = reward.amount,
          reward_anim = reward:getExtraString("reward_anim"),
          text_id = reward:getExtraString("text_id"),
          island_id = reward:getExtraString("island"),
          mail_id = reward:getExtraLong("mail_id"),
          box_filled = reward:getExtraBool("box_filled"),
          getExtraBool = getExtraBool,
          getExtraLong = getExtraLong
        })
      end
    end
  end
  self.refreshDelay = msg:delay()
  print("gotMsgEncoreEvent " .. self.refreshDelay)
end
function EncoreRewardTrackBar:gotMsgEncoreRefresh(msg)
  self:reset()
  self:checkForEncoreEvent()
end
function EncoreRewardTrackBar:checkForEncoreEvent()
  self.doingEncoreTutorial = game.isMemberOfGroup(70)
  if self.doingEncoreTutorial then
    self:handleEncoreTutorialSetup()
    return
  end
  self.encoreEvent = game.getCurrentEncoreEvent()
  if self.visibleOnIsland == 0 or not self.encoreEvent then
    self:DoStoredScript("hide")
    self.manualHide = 0
    return
  end
  self.RewardBar.rewardTrackId = self.encoreEvent:getRewardTrackId()
  self.RewardBar.handleRollover = self.encoreEvent:getRollsOver() and 1 or 0
  self:DoStoredScript("show")
  local encoreType = self.encoreEvent:getEncoreType()
  self.EventType.Sprite("size"):SetFloat(1)
  if encoreType == game.EncoreType_Baking then
    self.EventType.Sprite("spriteName"):SetString("encore_icon_bake")
    self.EventType.Sprite("sheetName"):SetString("xml_resources/hud03.xml")
  elseif encoreType == game.EncoreType_Breeding then
    self.EventType.Sprite("spriteName"):SetString("encore_icon_breed")
    self.EventType.Sprite("sheetName"):SetString("xml_resources/hud03.xml")
  elseif encoreType == game.EncoreType_Hatching then
    self.EventType.Sprite("spriteName"):SetString("encore_icon_hatch")
    self.EventType.Sprite("sheetName"):SetString("xml_resources/hud03.xml")
  elseif encoreType == game.EncoreType_All then
    self.EventType.Sprite("spriteName"):SetString("encore_icon_allevents")
    self.EventType.Sprite("sheetName"):SetString("xml_resources/hud03.xml")
  else
    print("unknown encoreType: " .. encoreType)
  end
  local scale = 0.7 * self.EventType.BackingSprite:absH() / self.EventType.Sprite:absH()
  self.EventType.Sprite("size"):SetFloat(scale)
  self:RefreshPlayerPoints()
  self:setTempScale(1)
  self.Timer.Sprite("visible"):SetInt(1)
  self.Timer.Text("visible"):SetInt(1)
end
function EncoreRewardTrackBar:handleEncoreTutorialSetup()
  if game.playerLevel() < 8 or game.tutorialActive() then
    self:DoStoredScript("hide")
    self.manualHide = 0
    return
  end
  self.RewardBar.rewardTrackId = 1
  self.RewardBar.handleRollover = 0
  self:DoStoredScript("show")
  self.EventType.Sprite("size"):SetFloat(1)
  self.EventType.Sprite("spriteName"):SetString("encore_icon_allevents")
  self.EventType.Sprite("sheetName"):SetString("xml_resources/hud03.xml")
  local scale = 0.7 * self.EventType.BackingSprite:absH() / self.EventType.Sprite:absH()
  self.EventType.Sprite("size"):SetFloat(scale)
  self:RefreshPlayerPoints()
  self:setTempScale(1)
  self.Timer.Sprite("visible"):SetInt(0)
  self.Timer.Text("visible"):SetInt(0)
end
function EncoreRewardTrackBar:onTick(dt)
  local timerTick = self.timeTick - dt
  if timerTick <= 0 then
    timerTick = 1
    if self.doingEncoreTutorial then
      if self.isVisible == 0 and self.manualHide == 0 and not game.tutorialActive() and game.playerLevel() >= 8 then
        self:handleEncoreTutorialSetup()
      end
      timerTick = 10
    elseif self.encoreEvent then
      local timeRemaing = self.encoreEvent:timeRemainingSec()
      if timeRemaing > 86400 then
        timerTick = 60
      elseif timeRemaing <= 0 then
        self:checkForEncoreEvent()
        return
      end
      self.Timer.Text("text"):SetString(game.timeToString(timeRemaing, true))
    else
      self:checkForEncoreEvent()
    end
  end
  self.timeTick = timerTick
  if self.isVisible == 1 then
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
    self.refreshDelay = self.refreshDelay - dt
    if 0 > self.refreshDelay then
      self.refreshDelay = 10000000000
      self:RefreshPlayerPoints()
    end
  end
end
function EncoreRewardTrackBar:RefreshPlayerPoints()
  local currentPlayerEncoreState = game.getCurrentPlayerEncoreState()
  if not self.doingEncoreTutorial and (not self.encoreEvent or currentPlayerEncoreState:eventId() ~= self.encoreEvent:eventId()) then
    self:DoStoredScript("hide")
    self.manualHide = 0
    game.refreshPlayerEncoreState()
    return
  end
  self.RewardBar:SetCurrentPoints(currentPlayerEncoreState:totalPoints())
end
function EncoreRewardTrackBar:setColorPercent(percent)
  self.colorPercent = percent
  if self.RewardBar then
    self.RewardBar:setColorPercent(percent)
  end
  self.EventType.BackingSprite:setColor(percent, percent, percent)
  self.EventType.Sprite:setColor(percent, percent, percent)
  self.FlagSprite:setColor(percent, percent, percent)
  self.Timer.Sprite:setColor(percent, percent, percent)
  self.Timer.Text:setColor(percent, percent, percent)
end
function EncoreRewardTrackBar:setTempScale(scale)
  local scaleVector = lua_sys.Vector2(scale, scale)
  if self.RewardBar then
    self.RewardBar:setTempScale(scale)
  end
  self.EventType.BackingSprite:setScale(scaleVector)
  self.EventType.Sprite:setScale(scaleVector)
  self.FlagSprite:setScale(scaleVector)
  self.Timer.Sprite:setScale(scaleVector)
  self.Timer.Text:setScale(scaleVector)
end
function EncoreRewardTrackBar:setLayer(layer)
  self.RewardBar:setLayer(layer)
  self.EventType.BackingSprite("layer"):SetString(layer)
  self.EventType.Sprite("layer"):SetString(layer)
  self.FlagSprite("layer"):SetString(layer)
  self.Timer.Sprite("layer"):SetString(layer)
  self.Timer.Text("layer"):SetString(layer)
end
function EncoreRewardTrackBar:startTutorialDisplay()
  self.originalLayer = self.EventType.BackingSprite:V("layer"):GetString()
  self:setLayer("Tutorial")
end
function EncoreRewardTrackBar:endTutorialDisplay()
  if self.originalLayer ~= nil then
    self:setLayer(self.originalLayer)
  end
end
return EncoreRewardTrackBar
