local RewardTrackBar = {
  TouchBlocker = {},
  BarBackingSprite = {},
  BarSprite = {},
  Text = {},
  RewardSprite1 = {},
  RewardCollectAnim1 = {
    Sprite = {}
  },
  RewardText1 = {},
  RewardSprite2 = {},
  RewardCollectAnim2 = {
    Sprite = {}
  },
  RewardSprite3 = {},
  RewardCollectAnim3 = {
    Sprite = {}
  },
  sfxStart = "",
  sfxTick = "",
  sfxMilestone1 = "",
  sfxMilestone2 = "",
  sfxEndBar = "",
  sfxRewards = "",
  originalLayer = nil
}
local BAR_PERCENT_ANIMATION_PER_SECOND_NORMAL = 1
local BAR_PERCENT_ANIMATION_PER_SECOND_FAST_MIN = 2
local BAR_PERCENT_ANIMATION_PER_SECOND_FAST_MAX = 9
local BAR_PERCENT_ANIMATION_PER_SECOND_FAST_TARGET_TIME = 2
local SHOW_REWARDS_DELAY = 0.5
local SFX_TICK_DELAY = 0.1
RewardTrackBar.BACKING_PIXEL_BUFFER = 1.1
RewardTrackBar.MAIN_REWARD_ELEMENT_INDEX = 1
RewardTrackBar.SUB_REWARD_1_ELEMENT_INDEX = 2
RewardTrackBar.SUB_REWARD_2_ELEMENT_INDEX = 3
function RewardTrackBar:onInit()
  self.isVisible = 1
  self.rewardVisiblity = {
    1,
    1,
    1
  }
  self.isHypeBar = false
  self:reset()
end
function RewardTrackBar:reset()
  self.pendingRewards = {}
  self.currentBarPercentAnimationPerSecond = BAR_PERCENT_ANIMATION_PER_SECOND_NORMAL
  self.rewardsDelay = 1000000
  self.targetTotalPoints = -1
  self.currentPct = -1
  self.targetPct = -1
  self.barStartPoints = 0
  self.barPoints = 0
  self.barEndPoints = 0
  self.barMilestone1Points = 0
  self.barMilestone2Points = 0
  self.rewardTrackId = 0
  self.handleRollover = 0
  self.handlePrestige = 0
  self.reachedMax = 0
  self.fillSfxTick = 0
  self.TouchBlocker("enabled"):SetInt(0)
  self.originalScale = self:templateVars().scale
end
function RewardTrackBar:onTick(dt)
  if self.isVisible == 1 then
    if self.reachedMax == 0 and self.currentPct ~= self.targetPct then
      local topPopup = game.getTopPopUpName()
      if topPopup ~= "" and topPopup ~= "MenuReduxElement_Root" and topPopup ~= "hype_game" then
        self.TouchBlocker("enabled"):SetInt(0)
        return
      end
      self.TouchBlocker("enabled"):SetInt(1)
      dt = math.min(dt, 0.033)
      self.currentPct = math.min(self.currentPct + self.currentBarPercentAnimationPerSecond * dt, self.targetPct + 0.001)
      if 1 <= self.currentPct and 1 <= self.targetPct then
        self.currentPct = -0.001
        if self.sfxEndBar ~= "" then
          lua_sys.playSoundFx(self.sfxEndBar)
        end
        self.RewardCollectAnim1.Sprite("visible"):SetInt(1)
        self.RewardCollectAnim1.Sprite:Play()
        local nextBarPoints = self.barEndPoints + 1
        self:RefreshCurrentRewardTrackData(nextBarPoints)
        if self.reachedMax == 1 then
          self.rewardsDelay = SHOW_REWARDS_DELAY
          return
        end
        if self.barEndPoints <= self.targetTotalPoints then
          self.targetPct = 1.1
        else
          self.targetPct = (self.targetTotalPoints - self.barStartPoints) / self.barPoints - 1.0E-4
          self.currentBarPercentAnimationPerSecond = BAR_PERCENT_ANIMATION_PER_SECOND_NORMAL
        end
      elseif self.currentPct > self.targetPct then
        self.currentPct = self.targetPct
        if 0 > self.targetPct then
          self.targetPct = 0
        end
        if self.pendingRewards and 1 <= #self.pendingRewards then
          self.rewardsDelay = SHOW_REWARDS_DELAY
        else
          self.TouchBlocker("enabled"):SetInt(0)
        end
      else
        self.fillSfxTick = self.fillSfxTick - dt
        if 0 > self.fillSfxTick then
          self.fillSfxTick = SFX_TICK_DELAY / self.currentBarPercentAnimationPerSecond
          if self.sfxTick ~= "" then
            lua_sys.playSoundFx(self.sfxTick)
          end
        end
        if 0 < self.barMilestone1Points or 0 < self.barMilestone2Points then
          local halfPointsPerTick = self.barPoints * self.currentBarPercentAnimationPerSecond * dt * 0.5
          local roughCurrentPoints = self.barPoints * self.currentPct
          if 0 < self.barMilestone1Points and halfPointsPerTick > math.abs(self.barMilestone1Points - roughCurrentPoints) then
            if self.sfxMilestone1 ~= "" then
              lua_sys.playSoundFx(self.sfxMilestone1)
            end
            self.RewardCollectAnim2.Sprite("visible"):SetInt(1)
            self.RewardCollectAnim2.Sprite:Play()
          end
          if 0 < self.barMilestone2Points and halfPointsPerTick > math.abs(self.barMilestone2Points - roughCurrentPoints) then
            if self.sfxMilestone2 ~= "" then
              lua_sys.playSoundFx(self.sfxMilestone2)
            end
            self.RewardCollectAnim3.Sprite("visible"):SetInt(1)
            self.RewardCollectAnim3.Sprite:Play()
          end
        end
      end
      self.BarSprite("maskWidth"):SetFloat(self.BarSprite("FullMaskW"):GetInt() * clamp(self.currentPct, 0, 1))
      local currentLevelPoints = math.max(math.floor(self.barPoints * (self.currentPct + 1.0E-4)), 0)
      self.Text("text"):SetString(game.localizeInt(currentLevelPoints) .. "/" .. game.localizeInt(self.barPoints))
      self.Text("size"):SetFloat(0.3 * self:templateVars().scale)
    else
      self.rewardsDelay = self.rewardsDelay - dt
      if 0 >= self.rewardsDelay then
        self.TouchBlocker("enabled"):SetInt(0)
        self:HandlePendingRewards()
      end
    end
  end
end
function RewardTrackBar:RefreshCurrentRewardTrackData(points)
  if self.rewardTrackId <= 0 then
    print("RewardTrackId Not Set? " .. self.rewardTrackId)
    return
  end
  local handleRollover = self.handleRollover == 1 or self.handlePrestige == 1
  local rewardTrackData = game.getRewardTrackData(self.rewardTrackId)
  local rewardTrackLevelData = game.getRewardTrackLevelData(self.rewardTrackId, points, handleRollover)
  if rewardTrackLevelData:size() == 0 then
    print("Invalid Reward Track: " .. self.rewardTrackId)
    return
  end
  local pointsOffset = math.floor(points / rewardTrackData.totalPoints) * rewardTrackData.totalPoints
  for i = 1, 3 do
    self:E("RewardSprite" .. i):Hide()
  end
  if not handleRollover and pointsOffset > 0 then
    self.reachedMax = 1
    self.BarSprite("maskWidth"):SetFloat(self.BarSprite("FullMaskW"):GetInt())
    self.Text("text"):SetString("CONTEXTBAR_COMPLETE_LABEL")
    self.Text("size"):SetFloat(0.3 * self:templateVars().scale)
    return
  end
  self.barMilestone1Points = 0
  self.barMilestone2Points = 0
  for i = 0, rewardTrackLevelData:size() - 1 do
    local data = rewardTrackLevelData[i]
    if data.sub_level == 0 then
      self.barStartPoints = pointsOffset + data.startPoints
      self.barPoints = data.points
      self.barEndPoints = pointsOffset + data.startPoints + data.points
    elseif data.sub_level == 1 then
      self.barMilestone1Points = data.points
    elseif data.sub_level == 2 then
      self.barMilestone2Points = data.points
    end
  end
  for i = 0, rewardTrackLevelData:size() - 1 do
    local data = rewardTrackLevelData[i]
    local rewards
    if self.handlePrestige == 1 and points >= rewardTrackData.totalPoints then
      rewards = data:prestigeRewards()
    else
      rewards = data:rewards(false)
    end
    local rewardSprite = self:E("RewardSprite" .. data.sub_level + 1)
    if rewards:empty() then
      rewardSprite:Hide()
    else
      local rewardData = rewards[0]
      rewardSprite:loadLootRewardData(rewardData)
      if self.isVisible == 1 and self.rewardVisiblity[data.sub_level + 1] == 1 then
        rewardSprite:Show()
      else
        rewardSprite:Hide()
      end
      if 1 <= data.sub_level then
        local pct = data.points / self.barPoints
        rewardSprite:GetVar("xOffset"):SetInt(pct * self.BarSprite:absW())
      else
        self:C("RewardText" .. data.sub_level + 1)("text"):SetString(game.localizeInt(rewardData.amount))
      end
    end
  end
end
function RewardTrackBar:SetCurrentPoints(points)
  local previousPoints = self.targetTotalPoints
  local currentPoints = points
  if previousPoints < 0 then
    previousPoints = currentPoints
    self:RefreshCurrentRewardTrackData(previousPoints)
  end
  self.targetTotalPoints = currentPoints
  if currentPoints > self.barEndPoints then
    self.targetPct = 1
    if self.isHypeBar then
      self.currentBarPercentAnimationPerSecond = BAR_PERCENT_ANIMATION_PER_SECOND_FAST_MIN
    else
      local roughCurrentPoints = self.barPoints * self.currentPct
      local currentRewardTrackLevelData = game.getRewardTrackLevelData(self.rewardTrackId, roughCurrentPoints, self.handleRollover == 1 or self.handlePrestige == 1)
      local targetRewardTrackLevelData = game.getRewardTrackLevelData(self.rewardTrackId, currentPoints, self.handleRollover == 1 or self.handlePrestige == 1)
      local levels = targetRewardTrackLevelData[0].level - currentRewardTrackLevelData[0].level
      if levels < 0 then
        levels = currentRewardTrackLevelData[0].level
      end
      self.currentBarPercentAnimationPerSecond = math.max(math.min(BAR_PERCENT_ANIMATION_PER_SECOND_FAST_MAX, levels / BAR_PERCENT_ANIMATION_PER_SECOND_FAST_TARGET_TIME), BAR_PERCENT_ANIMATION_PER_SECOND_FAST_MIN)
    end
  else
    self.targetPct = (currentPoints - self.barStartPoints) / self.barPoints
    self.currentBarPercentAnimationPerSecond = BAR_PERCENT_ANIMATION_PER_SECOND_NORMAL
  end
  self.fillSfxTick = SFX_TICK_DELAY / self.currentBarPercentAnimationPerSecond
  if 0 > self.currentPct then
    self.currentPct = self.targetPct - 0.01
    self.BarSprite("maskWidth"):SetFloat(self.BarSprite("FullMaskW"):GetInt() * clamp(self.currentPct, 0, 1))
  elseif self.currentPct ~= self.targetPct and self.sfxStart ~= "" then
    lua_sys.playSoundFx(self.sfxStart)
  end
end
function RewardTrackBar:HandlePendingRewards()
  if self.pendingRewards and #self.pendingRewards >= 1 then
    local topPopup = game.getTopPopUpName()
    if topPopup ~= "" and topPopup ~= "MenuReduxElement_Root" and topPopup ~= "hype_game" then
      self.rewardsDelay = 0.1
      return
    end
    if self.sfxRewards ~= "" then
      lua_sys.playSoundFx(self.sfxRewards)
    end
    local popup = game.pushPopUp("popup_store_bundle_rewards")
    popup:Setup(self.pendingRewards)
    if self.isHypeBar then
      popup.Rewards:SetBGSpites("gfx/menu/gradient_bg_clubbox", "gfx/menu/bg_symbols_clubbox")
    end
    self.pendingRewards = {}
  end
  self.rewardsDelay = 1000000
end
function RewardTrackBar:setColorPercent(percent)
  self.colorPercent = percent
  self.BarBackingSprite:setColor(percent, percent, percent)
  self.BarSprite:setColor(percent, percent, percent)
  self.Text:setColor(percent, percent, percent)
  self.RewardText1:setColor(percent, percent, percent)
  for i = 1, 3 do
    self:E("RewardSprite" .. i):SetColor(percent, percent, percent)
  end
end
function RewardTrackBar:setTempScale(scale)
  local scaleVector = lua_sys.Vector2(scale, scale)
  self.BarBackingSprite:setScale(scaleVector)
  self.BarSprite:setScale(scaleVector)
  self.Text:setScale(scaleVector)
  self.RewardText1:setScale(scaleVector)
  for i = 1, 3 do
    self:E("RewardSprite" .. i):setTempScale(scaleVector)
  end
end
function RewardTrackBar:setLayer(layer)
  self.BarBackingSprite("layer"):SetString(layer)
  self.BarSprite("layer"):SetString(layer)
  self.Text("layer"):SetString(layer)
  self.RewardText1("layer"):SetString(layer)
  self.RewardSprite1:SetLayer(layer)
  self.RewardSprite2:SetLayer(layer)
  self.RewardSprite3:SetLayer(layer)
end
function RewardTrackBar:startTutorialDisplay()
  self.originalLayer = self.BarBackingSprite:V("layer"):GetString()
  self:setLayer("Tutorial")
end
function RewardTrackBar:endTutorialDisplay()
  if self.originalLayer ~= nil then
    self:setLayer(self.originalLayer)
  end
end
return RewardTrackBar
