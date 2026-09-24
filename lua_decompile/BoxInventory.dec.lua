local BoxInventory = {
  EggList = {},
  EggListBg = {
    Sprite = {}
  },
  ScrollBar = {
    Sprite = {}
  },
  ScrollMarker = {
    Marker = {}
  },
  EvolutionProgress = {}
}
function BoxInventory:onPostInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgShowUpdatedBoxedMonsters", "gotMsgShowUpdatedBoxedMonsters")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerUpdated", "gotMsgPlayerUpdated")
  local numItems = self.EggList:V("NumDistinctMonsters"):GetInt()
  if numItems > 0 then
    local firstEntry = self:E("monsterEntry0")
    if firstEntry ~= nil then
      local itemHeight = firstEntry:absH()
      if numItems * itemHeight <= self.EggList:absH() then
        self.ScrollBar.Sprite:V("visible"):SetInt(0)
        self.ScrollMarker.Marker:V("visible"):SetInt(0)
      end
    end
  end
  if self.EvolutionProgress.IsVisible then
    local panelWidth = 400 * game.windowScaleX()
    local panelHeight = 280 * game.windowScaleY()
    self.EggListBg.Sprite:setSize(lua_sys.Vector2(panelWidth, panelHeight))
    self.EggListBg:V("xOffset"):SetFloat(30 * game.windowScaleX())
    self.EggListBg:updateClipping()
  end
  if game.isQABuild() and game.isCelestialIsland() and game.selectedIsEvolvableMonsterType() then
    local percent = menu:addTemplateElement("template_qaPercentFillComplete", "qaComplete", self)
    percent:setParent(self:E("EggListBg"))
    percent:setOrientation(lua_sys.MenuOrientation(0, -4 * game.menuScaleY(), 0, lua_sys.HCENTER, lua_sys.VCENTER))
    percent:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
    percent:init()
    percent:setPositionBroadcast(true)
  end
end
function BoxInventory:gotMsgShowUpdatedBoxedMonsters()
  self.EggList:updateAllIds(game.selectedMonsterId())
  local numPossessed = 0
  local numItems = self.EggList:V("NumDistinctMonsters"):GetInt() - 1
  for i = 0, numItems do
    local monsterEntry = self.EggList:E("monsterEntry" .. i)
    if monsterEntry then
      monsterEntry:V("possessed"):SetInt(self.EggList.allReqDefs[i].possessed)
      monsterEntry:V("required"):SetInt(self.EggList.allReqDefs[i].required)
      if monsterEntry:E("PossessedNum") ~= nil then
        monsterEntry:E("PossessedNum"):C("Text"):V("text"):SetString("" .. monsterEntry:V("possessed"):GetInt())
      end
      if monsterEntry:E("RequiredNum") ~= nil then
        monsterEntry:E("RequiredNum"):C("Text"):V("text"):SetString("" .. monsterEntry:V("required"):GetInt())
      end
      if self.EggList.allReqDefs[i].possessed < self.EggList.allReqDefs[i].required then
        monsterEntry:deselect()
      else
        monsterEntry:select()
        numPossessed = numPossessed + 1
      end
    end
  end
  self.EggList.NumPossessed = numPossessed
  if self.EggsRequired.Text:V("visible"):GetInt() ~= 0 then
    self.EggsRequired.Text:V("text"):SetString(game.numEggsInInventory() .. "/" .. game.minNumEggsRequiredInUnderling())
  end
  self.EggList:updateContextBar()
end
function BoxInventory:gotMsgPlayerUpdated()
  self:E("WildcardCounter"):C("Text"):V("text"):SetString(game.commaizeNumber(game.playerEggWildcards()))
end
function BoxInventory:queuePop()
  self:root():popPopUp()
end
function BoxInventory.EggListBg:updateClipping()
  local scrollerX = (self:absX() + 20 * game.menuScaleX()) * lua_sys.deviceScaleX()
  local scrollerY = self:absY() * lua_sys.deviceScaleY()
  local scrollerWidth = (self:absW() - 20 * game.menuScaleX() * 2) * lua_sys.deviceScaleX()
  local scrollerHeight = 360 * game.menuScaleY() * lua_sys.deviceScaleY()
  game.setClipping("Clipping", scrollerX, scrollerY, scrollerWidth, scrollerHeight)
end
return BoxInventory
