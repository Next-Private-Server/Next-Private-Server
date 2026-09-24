local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local DishHarmonzierEggs = {
  bg = {
    Touch = {}
  },
  EggLeft = {
    Sprite = {},
    Touch = {}
  },
  EggRight = {
    Sprite = {},
    Touch = {}
  },
  MonsterNameLeft = {},
  MonsterNameRight = {}
}
function DishHarmonzierEggs:onInit()
  self.incubateMonster = 0
  self.incubateMonsterResultId = -1
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = -30 * game.menuScaleY(),
    duration = 0.66
  })
  self:Show()
end
function DishHarmonzierEggs:onPostInit()
  local dishHarmonizer = game.SelectedObject()
  local monsters = dishHarmonizer:monsterResults()
  local monsterResult = monsters[0]
  local monsterData = game.getMonsterData(monsterResult.monsterId)
  self.EggLeft:V("monster"):SetInt(monsterResult.monsterId)
  self.EggLeft:V("monsterResultId"):SetInt(monsterResult.id)
  local sheetName = "xml_resources/" .. monsterData:spore() .. ".xml"
  self.EggLeft.Sprite:V("spriteName"):SetString(monsterData:spore())
  self.EggLeft.Sprite:V("sheetName"):SetString(sheetName)
  self.MonsterNameLeft:C("Text"):V("text"):SetString(monsterData:name())
  if monsters:size() > 1 then
    local monsterResult2 = monsters[1]
    local monsterData2 = game.getMonsterData(monsterResult2.monsterId)
    self.EggRight:V("monster"):SetInt(monsterResult2.monsterId)
    self.EggRight:V("monsterResultId"):SetInt(monsterResult2.id)
    local sheetName = "xml_resources/" .. monsterData2:spore() .. ".xml"
    self.EggRight.Sprite:V("spriteName"):SetString(monsterData2:spore())
    self.EggRight.Sprite:V("sheetName"):SetString(sheetName)
    self.MonsterNameRight:C("Text"):V("text"):SetString(monsterData2:name())
  else
    self.EggRight.Sprite:V("visible"):SetInt(0)
  end
end
function DishHarmonzierEggs:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      game.pushPopUp("popup_dish_harmonizer_incubate_egg")
      game.topPopUp():V("monster"):SetInt(self.incubateMonster)
      game.topPopUp():V("monsterResultId"):SetInt(self.incubateMonsterResultId)
      game.topPopUp():DoStoredScript("update")
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
end
function DishHarmonzierEggs:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_menu_open.ogg")
end
function DishHarmonzierEggs:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function DishHarmonzierEggs:queuePop()
  self:Hide()
end
function DishHarmonzierEggs:ShowIncubateEgg(monster, monsterResultId)
  self.incubateMonster = monster
  self.incubateMonsterResultId = monsterResultId
  self:Hide()
end
function DishHarmonzierEggs.EggLeft.Touch:onTouchUp(element, component)
  element:parent():ShowIncubateEgg(element:V("monster"):GetInt(), element:V("monsterResultId"):GetInt())
end
function DishHarmonzierEggs.EggRight.Touch:onTouchUp(element, component)
  element:parent():ShowIncubateEgg(element:V("monster"):GetInt(), element:V("monsterResultId"):GetInt())
end
return DishHarmonzierEggs
