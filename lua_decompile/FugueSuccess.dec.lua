local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local FugueSuccess = {
  Text = {
    Text = {}
  },
  ConfirmButton = {
    Touch = {}
  }
}
function FugueSuccess:onInit()
  self.monsterId = 0
  lua_sys.playSoundFx("audio/sfx/structure_fugue_collect_success.ogg")
end
function FugueSuccess:onPostInit()
  local fugue = game.FindFugue()
  self.monsterId = fugue:fuguingMonster()
  local monster = game.GetMultiMonster(self.monsterId)
  local monsterData = monster:data()
  local monsterType = monsterData:monsterId()
  local activatedMode = fugue:fuguingMonsterModeActivated()
  local formText = game.getLocalizedText("MINOR")
  if activatedMode == 0 then
    formText = game.getLocalizedText("MAJOR")
  end
  local successText = game.getLocalizedText("FUGUING_SUCCESS")
  local monsterText = game.getMonsterName(monster:uniqueId())
  successText = successText:gsub("%${MONSTER}", monsterText)
  successText = successText:gsub("%${FORM}", formText)
  print("successText " .. successText)
  self.Text:C("Text"):V("text"):SetString(successText)
  local otherMode = 1 - activatedMode
  local oldMonsterAnim = self.OldMonsterAnim:C("Sprite")
  local animFile = game.getModalMonsterData(monsterData, otherMode):animationFile()
  oldMonsterAnim:V("animationName"):SetString("xml_bin/" .. animFile)
  oldMonsterAnim:V("animation"):SetString(game.getMonsterAnimationNameFromType(monsterType))
  local costumeId = monster:getEquippedCostume()
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(oldMonsterAnim, costumeId)
  end
  oldMonsterAnim:GetVar("offsetCenter"):SetInt(1)
  local otherAnimFile = game.getModalMonsterData(monsterData, activatedMode):animationFile()
  local newMonsterAnim = self.NewMonsterAnim:C("Sprite")
  newMonsterAnim:V("animationName"):SetString("xml_bin/" .. otherAnimFile)
  newMonsterAnim:V("animation"):SetString(game.getMonsterAnimationNameFromType(monsterType))
  local costumeId = monster:getEquippedCostume()
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(newMonsterAnim, costumeId)
  end
  newMonsterAnim:GetVar("offsetCenter"):SetInt(1)
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 1,
    endY = -20 * game.menuScaleX(),
    duration = 0.33
  })
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
end
function FugueSuccess:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      game.deselectSelectedObject()
      manager:setContext(manager:getDefaultContext())
      local monster = game.GetMultiMonster(self.monsterId)
      game.worldContext():zoomCameraToObject(monster, 0.8, 0.75)
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
end
function FugueSuccess:queuePop()
  self:root():popPopUp()
end
function FugueSuccess.ConfirmButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element)
  MenuElementPositionOffsetTransition.Hide(element:parent():E("bg"))
end
return FugueSuccess
