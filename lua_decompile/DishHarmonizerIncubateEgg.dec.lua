local MenuHelpers = include("MenuHelpers")
local DishHarmonzierIncubateEgg = {
  EggImage = {
    Sprite = {},
    RareAnim = {}
  },
  MonsterName = {
    Text = {}
  },
  Time = {
    Text = {}
  },
  Postfix = {
    Text = {}
  },
  Wait = {
    Touch = {}
  },
  GetItNow = {
    Touch = {}
  }
}
function DishHarmonzierIncubateEgg:onInit()
end
function DishHarmonzierIncubateEgg:onPostInit()
end
function DishHarmonzierIncubateEgg:Update()
  local monsterType = self:V("monster"):GetInt()
  local monsterData = game.getMonsterData(monsterType)
  local sheetName = "xml_resources/" .. monsterData:spore() .. ".xml"
  self.EggImage.Sprite:V("spriteName"):SetString(monsterData:spore())
  self.EggImage.Sprite:V("sheetName"):SetString(sheetName)
  self.EggImage:setPositionBroadcast(true)
  self.EggImage.Sprite:DoStoredScript("reposition")
  self.MonsterName.Text:V("text"):SetString(monsterData:name())
  if monsterData:isRareMonster() then
    local rareAnim = self.EggImage.RareAnim
    rareAnim:V("animationName"):SetString("xml_bin/rare_egg.bin")
    rareAnim:V("animation"):SetString("rare_egg")
    rareAnim:V("visible"):SetInt(1)
  elseif monsterData:isEpicMonster() then
    local rareAnim = self.EggImage.RareAnim
    rareAnim:V("animationName"):SetString("xml_bin/epic_egg.bin")
    rareAnim:V("animation"):SetString("epic_egg")
    rareAnim:V("visible"):SetInt(1)
  end
  local time = game.worldContext():getTheoreticalNurseryTime(monsterType)
  self.Time.Text:V("text"):SetString(game.timeToString(time))
  if game.hasNurseryModifier() then
    local palette = include("ColourPalette")
    self.Time.Text:setColor(palette:getRGBFloats(palette.MODIFIER_APPLIED_COLOUR))
  else
    self.Time.Text:setColor(1, 1, 1)
  end
  local message = LOC("GETNOW_POSTFIX")
  message = message:gsub("XXX", game.diamondsRequiredToComplete(time))
  self.Postfix.Text:V("text"):SetString(message)
end
function DishHarmonzierIncubateEgg:StartIncubating(speedUp)
  self:root():popPopUp()
  if game.player():getActiveIsland():hasRoomForEgg() then
    local dishHarmonizer = game.SelectedObject()
    dishHarmonizer:incubateEgg(self:V("monsterResultId"):GetInt(), speedUp)
    lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_nursery_addegg.ogg")
  else
    game.displayNotification("NOTIFICATION_NOT_ENOUGH_ROOM_IN_EGG_CUPS")
  end
  game.deselectSelectedObject()
  manager:setContext(manager:getDefaultContext())
end
function DishHarmonzierIncubateEgg.Wait.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Overlay:setColor(1, 1, 1)
  element:parent():StartIncubating(false)
end
function DishHarmonzierIncubateEgg.GetItNow.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Overlay:setColor(1, 1, 1)
  element:parent():StartIncubating(true)
end
return DishHarmonzierIncubateEgg
