local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local PolarityAmplifier = {
  Description = {
    Text = {}
  }
}
function PolarityAmplifier:onPostInit()
  self:initLevels()
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = -6 * game.hudScale(),
    duration = 0.66
  })
  self:Show()
end
function PolarityAmplifier:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
end
function PolarityAmplifier:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function PolarityAmplifier:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function PolarityAmplifier:queuePop()
  self:Hide()
end
function PolarityAmplifier:initLevels()
  local levelDatas = game.getPolarityAmplifierLevelData()
  local numUniqueMonsters = game.player():getActiveIsland():numUniqueMonstersCollectedOnIsland()
  for i = 1, levelDatas:size() - 1 do
    local levelData = levelDatas[i]
    local previousLevelData = levelDatas[i - 1]
    local levelMonsters = numUniqueMonsters - previousLevelData.numMonsters
    local requiredMonsters = levelData.numMonsters - previousLevelData.numMonsters
    local percentage = levelMonsters / requiredMonsters
    percentage = lua_sys.clamp(percentage, 0, 1)
    local meter = self:E("Meter_" .. i)
    meter:setFill(percentage)
    local level = self:E("Level_" .. i)
    if percentage == 1 then
      level:DoStoredScript("unlock")
    end
  end
end
return PolarityAmplifier
