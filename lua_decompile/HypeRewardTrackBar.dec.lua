local HypeRewardTrackBar = {
  RewardBar = {},
  Touch = {}
}
function HypeRewardTrackBar:onInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgHypeGameRewards", "gotMsgHypeGameRewards")
  self.visibleOnIsland = 1
  self.isHypeGameBar = false
end
function HypeRewardTrackBar:onPostInit()
  self.RewardBar.isHypeBar = true
  self:reset()
  self:checkForClubboxEvent()
end
function HypeRewardTrackBar:reset()
  self.buttonState = game.BUTTON_IDLE
  self.tickTimer = 1
  self.touchCooldown = 0
  self.originalScale = self:templateVars().scale
  self.sfxEnabled = math.floor(self:templateVars().sfxEnabled) == 1
  self.isVisible = 1
  self.curClubboxAct = 0
  self.inPrestigeMode = false
  if self.RewardBar then
    self.RewardBar:reset()
    self.RewardBar.handleRollover = 0
    self.RewardBar.handlePrestige = 1
    if self.sfxEnabled then
      self.RewardBar.sfxStart = "audio/sfx/clubbox_hype_progressbar_fillstart.ogg"
      self.RewardBar.sfxTick = "audio/sfx/encore_progressbar_filltick.wav"
      self.RewardBar.sfxMilestone1 = "audio/sfx/clubbox_hype_progressbar_milestone01.ogg"
      self.RewardBar.sfxMilestone2 = "audio/sfx/clubbox_hype_progressbar_milestone02.ogg"
      self.RewardBar.sfxEndBar = "audio/sfx/clubbox_hype_progressbar_full.ogg"
      self.RewardBar.sfxRewards = "audio/sfx/clubbox_hype_reward_popup_lite.ogg"
    end
    self.RewardBar:E("RewardSprite" .. self.RewardBar.MAIN_REWARD_ELEMENT_INDEX):setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.VCENTER)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.MAIN_REWARD_ELEMENT_INDEX):setOrientationAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.MAIN_REWARD_ELEMENT_INDEX):GetVar("xOffset"):SetInt(-45 * self.originalScale)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.MAIN_REWARD_ELEMENT_INDEX):GetVar("yOffset"):SetInt(2 * self.originalScale)
    self.RewardBar:C("RewardText" .. self.RewardBar.MAIN_REWARD_ELEMENT_INDEX):GetVar("visible"):SetInt(0)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.SUB_REWARD_1_ELEMENT_INDEX):GetVar("yOffset"):SetInt(-10 * self.originalScale)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.SUB_REWARD_2_ELEMENT_INDEX):GetVar("yOffset"):SetInt(-20 * self.originalScale)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.SUB_REWARD_2_ELEMENT_INDEX):setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.MAIN_REWARD_ELEMENT_INDEX):setTargetSize(48 * self.originalScale)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.SUB_REWARD_1_ELEMENT_INDEX):setTargetSize(32 * self.originalScale)
    self.RewardBar:E("RewardSprite" .. self.RewardBar.SUB_REWARD_2_ELEMENT_INDEX):setTargetSize(32 * self.originalScale)
    self.RewardBar.Text:GetVar("xOffset"):SetInt(46 * self.originalScale)
    self.RewardBar.Text:GetVar("yOffset"):SetInt(32 * self.originalScale)
  end
end
function HypeRewardTrackBar:gotMsgHypeGameRewards(msg)
  if self.isVisible == 0 then
    return
  end
  local rewards = msg:rewards()
  if 0 < rewards:size() then
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
end
function HypeRewardTrackBar:checkForClubboxEvent()
  self.curClubboxAct = game.existingClubboxAct()
  if self.visibleOnIsland == 0 or self.curClubboxAct == 0 then
    self:DoStoredScript("hide")
    return
  end
  self:DoStoredScript("show")
  local rewardTrackId = game.clubboxActRewardTrackId(self.curClubboxAct)
  self.RewardBar.rewardTrackId = rewardTrackId
  self.RewardBar.handleRollover = 0
  self:refreshHypePoints()
  local rewardTrackData = game.getRewardTrackData(rewardTrackId)
  self.rewardTrackTotalPoints = rewardTrackData.totalPoints
  if self.rewardTrackTotalPoints < self.RewardBar.barEndPoints then
    self.inPrestigeMode = true
    self.RewardBar.BarBackingSprite("spriteName"):SetString("hype_meter_frame_prestige")
  end
  self:setTempScale(1)
end
function HypeRewardTrackBar:refreshHypePoints()
  self.RewardBar:SetCurrentPoints(game.clubboxCurHype(self.curClubboxAct))
end
function HypeRewardTrackBar:onTick(dt)
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
    if self.touchCooldown > 0 then
      self.touchCooldown = self.touchCooldown - dt
      if self.touchCooldown <= 0 then
        self.touchCooldown = 0
      end
    end
    if not self.isHypeGameBar and self.RewardBar and not self.inPrestigeMode and self.RewardBar.isVisible == 1 and self.RewardBar.currentPct ~= self.RewardBar.targetPct and self.rewardTrackTotalPoints < self.RewardBar.barEndPoints then
      self.inPrestigeMode = true
      self.RewardBar.BarBackingSprite("spriteName"):SetString("hype_meter_frame_prestige")
    end
  end
end
function HypeRewardTrackBar:setColorPercent(percent)
  self("colorPercent"):SetFloat(percent)
  if self.RewardBar then
    self.RewardBar:setColorPercent(percent)
  end
end
function HypeRewardTrackBar:setTempScale(scale)
  if self.RewardBar then
    self.RewardBar:setTempScale(scale)
  end
end
function HypeRewardTrackBar:getHighestLevel()
  if self.RewardBar and self.curClubboxAct then
    local topHype = game.player():curClubboxTopHype(self.curClubboxAct)
    local rewardTrackData = game.getRewardTrackData(self.RewardBar.rewardTrackId)
    local rewardTrackLevelData = game.getRewardTrackLevelData(self.RewardBar.rewardTrackId, topHype, true)
    local prestigeLevelOffset = math.floor(topHype / rewardTrackData.totalPoints) * rewardTrackData.totalLevels
    if rewardTrackLevelData:size() == 0 then
      print("Invalid Reward Track: " .. self.RewardBar.rewardTrackId)
      return 1
    end
    for i = 0, rewardTrackLevelData:size() - 1 do
      local data = rewardTrackLevelData[i]
      if data.sub_level == 0 then
        return data.level + prestigeLevelOffset
      end
    end
  end
  return 1
end
return HypeRewardTrackBar
