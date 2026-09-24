local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local FugueFailure = {
  Text = {
    Text = {}
  },
  Text2 = {
    Text = {}
  },
  ConfirmButton = {
    Touch = {}
  }
}
function FugueFailure:onInit()
  self.pauseBeforeFeedTimer = 0.5
  self.doPauseBeforeFeed = false
  lua_sys.playSoundFx("audio/sfx/structure_fugue_collect_failure.ogg")
end
function FugueFailure:onPostInit()
  local fugue = game.FindFugue()
  local monster = game.GetMultiMonster(fugue:fuguingMonster())
  self.monster = monster
  local monsterData = monster:data()
  local monsterType = monsterData:monsterId()
  local activeMode = 0
  if monster:isModeActivated(1) then
    activeMode = 1
  end
  local topText = game.getLocalizedText("FUGUING_FAILURE")
  local monsterText = game.getMonsterName(monster:uniqueId())
  topText = topText:gsub("%${MONSTER}", monsterText)
  self.Text:C("Text"):V("text"):SetString(topText)
  local oldMonsterAnim = self.OldMonsterAnim:C("Sprite")
  local animFile = game.getModalMonsterData(monsterData, activeMode):animationFile()
  oldMonsterAnim:V("animationName"):SetString("xml_bin/" .. animFile)
  oldMonsterAnim:V("animation"):SetString(game.getMonsterAnimationNameFromType(monsterType))
  local costumeId = monster:getEquippedCostume()
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(oldMonsterAnim, costumeId)
  end
  oldMonsterAnim:GetVar("offsetCenter"):SetInt(1)
  self.XpBar.LevelText:GetVar("text"):SetString(game.getLocalizedText("LEVEL") .. " " .. self.monster:level())
  if self.monster then
    self.targetXpPercentage = self.monster:timesFed() / 4
    self.targetLevel = self.monster:level()
    if self.feedCostElement then
      self.feedCostElement:GetComponent("Text"):GetVar("text"):SetString("-" .. game.commaizeNumber(self.monster:foodRequired()))
    end
  end
  self.currentXpPercentage = self.targetXpPercentage
  self.currentLevel = self.targetLevel
  self.targetXpAccumulated = self.currentLevel + self.currentXpPercentage - 1
  self.currentXpAccumulated = self.targetXpAccumulated
  self:updateXpBar()
  if monster:level() < game.maxMonsterLevel() then
    self.doPauseBeforeFeed = true
    self.Text2:C("Text"):V("visible"):SetInt(1)
  end
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 1,
    endY = -10 * game.menuScaleX(),
    duration = 0.33
  })
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
end
function FugueFailure:updateXpBar()
  local fullMaskW = self.XpBar.Sprite:GetVar("FullMaskW"):GetFloat()
  if self.XpBar.Sprite:GetVar("isSourceRotated"):GetInt() == 1 then
    self.XpBar.Sprite:GetVar("maskHeight"):SetInt(fullMaskW * self.currentXpPercentage)
  else
    self.XpBar.Sprite:GetVar("maskWidth"):SetInt(fullMaskW * self.currentXpPercentage)
  end
end
local XP_ANIMATION_SPEED = 1
function FugueFailure:onTick(dt)
  if self.doPauseBeforeFeed then
    self.pauseBeforeFeedTimer = self.pauseBeforeFeedTimer - dt
    if self.pauseBeforeFeedTimer <= 0 then
      self.targetXpAccumulated = self.targetXpAccumulated + 0.25
      self.doPauseBeforeFeed = false
      self.LevelUpEffect:start()
      lua_sys.playSoundFx("audio/sfx/feed_monster.wav")
    end
  end
  if self.currentXpAccumulated < self.targetXpAccumulated then
    local xpDelta = math.min(XP_ANIMATION_SPEED * dt, self.targetXpAccumulated - self.currentXpAccumulated)
    self.currentXpAccumulated = math.min(self.currentXpAccumulated + xpDelta, self.targetXpAccumulated)
    local newLevel = math.floor(self.currentXpAccumulated) + 1
    local newXpPercentage = self.currentXpAccumulated - math.floor(self.currentXpAccumulated)
    if newLevel > self.currentLevel then
      self.currentLevel = newLevel
      self.LevelUpEffect:start()
      self.XpBar.LevelText:GetVar("text"):SetString(game.getLocalizedText("LEVEL") .. " " .. self.currentLevel)
    end
    self.currentXpPercentage = newXpPercentage
    self:updateXpBar()
  end
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      game.deselectSelectedObject()
      manager:setContext(manager:getDefaultContext())
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
end
function FugueFailure:queuePop()
  self:root():popPopUp()
end
function FugueFailure.ConfirmButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element)
  MenuElementPositionOffsetTransition.Hide(element:parent():E("bg"))
end
return FugueFailure
