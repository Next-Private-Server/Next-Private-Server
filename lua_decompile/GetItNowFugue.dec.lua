local MonsterProperties = include("MonsterProperties")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local GetItNowFugue = {
  DiamondCounter = {},
  MonsterAnim = {
    Sprite = {}
  },
  Time = {
    Text = {}
  },
  Postfix = {
    Text = {}
  }
}
function GetItNowFugue:onInit()
  self.diamondsLeftToSpeedup = 0
  self.isReady = false
end
function GetItNowFugue:onPostInit()
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startX = lua_sys.screenWidth() * -1,
    endX = 0 * game.hudScale(),
    duration = 0.33
  })
  MenuElementPositionOffsetTransition.OnInit(self:E("DiamondCounter"), {
    startX = lua_sys.screenWidth() * -1,
    startY = 10 * game.hudScale(),
    endX = 10 * game.hudScale(),
    endY = 10 * game.hudScale(),
    duration = 0.33
  })
  self:Show()
end
function GetItNowFugue:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      self:root():popPopUp()
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
  local diamondCounterOptions = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("DiamondCounter"), dt, diamondCounterOptions)
  if self.isReady then
    self:updateTime()
  end
end
function GetItNowFugue:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  MenuElementPositionOffsetTransition.Show(self:E("DiamondCounter"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function GetItNowFugue:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  MenuElementPositionOffsetTransition.Hide(self:E("DiamondCounter"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function GetItNowFugue:update()
  local fugue = game.FindFugue()
  local monsterId = fugue:fuguingMonster()
  local monster = game.GetMonster(monsterId)
  local monsterData = monster:data()
  local currentMode = game.player():getActiveIsland():islandMode()
  local multiMonsterData = game.getModalMonsterData(monsterData, currentMode)
  local monsterType = multiMonsterData:monsterId()
  local animFile = multiMonsterData:animationFile()
  self.MonsterAnim.Sprite("animationName"):SetString("xml_bin/" .. animFile)
  self.MonsterAnim.Sprite("animation"):SetString(game.getMonsterAnimationNameFromType(monsterType))
  local costumeId = monster:getEquippedCostume()
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(self.MonsterAnim.Sprite, costumeId)
  end
  local facing = MonsterProperties.getFacing(monsterType)
  self.MonsterAnim.Sprite:GetVar("hFlip"):SetInt(facing)
  self.MonsterAnim.Sprite:GetVar("offsetCenter"):SetInt(1)
  self:updateTime()
  self.isReady = true
end
function GetItNowFugue:updateTime()
  local fugue = game.FindFugue()
  if fugue then
    local timeRemaining = fugue:secondsUntilActionDone()
    if timeRemaining > 0 then
      self.Time.Text("text"):SetString(game.timeToString(timeRemaining))
    else
      game.popPopUp()
      game.deselectSelectedObject()
      local contextBar = game.getContextBar()
      if contextBar then
        contextBar:setContext(contextBar:getDefaultContext())
      end
    end
    local newDiamond = fugue:diamondsRequiredToCompleteAction()
    if newDiamond ~= self.diamondsLeftToSpeedup then
      local text = game.getLocalizedText("GETNOW_POSTFIX")
      text = select(1, text:gsub("XXX", newDiamond))
      self.Postfix.Text("text"):SetString(text)
      self.diamondsLeftToSpeedup = newDiamond
    end
  end
end
return GetItNowFugue
