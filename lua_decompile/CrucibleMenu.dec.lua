local CrucibleMenu = {}
CrucibleMenu.e_MonsterList = nil
CrucibleMenu.e_Thermometer = nil
CrucibleMenu.e_IncrHeat = nil
CrucibleMenu.e_DecrHeat = nil
CrucibleMenu.e_EvolveButton = nil
function CrucibleMenu:updateTemperature()
  self.e_Thermometer:updateMask()
  self.e_IncrHeat:update()
  self.e_DecrHeat:update()
  self:updatePrice()
  self:updateSuccess()
end
function CrucibleMenu:updatePrice()
  local regularPrice = game.crucibleHeatRelicCost(self:V("heatLevel"):GetInt(), false)
  self:E("Price"):C("RelicCostText"):V("text"):SetString("" .. regularPrice)
  if regularPrice ~= 0 and game.isCrucibleHeatSaleActive() then
    self:E("Price"):E("RelicSalePrice"):C("Text"):V("text"):SetString("" .. game.crucibleHeatRelicCost(self:V("heatLevel"):GetInt(), true))
    self:E("Price"):setRelicSaleVisible()
  else
    self:E("Price"):setRelicSaleInvisible()
  end
  if self.e_MonsterList:V("SelectedEntryID"):GetInt() ~= 0 then
    self:E("Price"):C("KeyCostText"):V("text"):SetString("" .. game.crucibleEvolveKeyCost(self.e_MonsterList:V("SelectedEntryID"):GetInt(), self:V("heatLevel"):GetInt()))
  else
    self:E("Price"):C("KeyCostText"):V("text"):SetString("0")
  end
end
function CrucibleMenu:updateSuccess()
  local numMonsters = self.e_MonsterList:V("NumEntries"):GetInt()
  for i = 0, numMonsters do
    local entry = self:parent():E("crucibleEntry" .. i)
    if entry then
      if not game.guaranteedEvolve(entry:V("MonsterID"):GetInt(), self:V("heatLevel"):GetInt()) then
        entry:disableGuaranteed()
      else
        entry:enableGuaranteed()
      end
    end
  end
end
function CrucibleMenu:onInit()
  self.e_MonsterList = self:E("LeftMonsterList")
  self.e_Thermometer = self:E("Thermometer")
  self.e_IncrHeat = self:E("IncrHeat")
  self.e_DecrHeat = self:E("DecrHeat")
  self.e_EvolveButton = self:E("EvolveButton")
  self:V("heatLevel"):SetInt(math.max(game.crucHeatLevel(), 1))
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function CrucibleMenu:onPostInit()
  self:updateTemperature()
end
function CrucibleMenu:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "EVOLVE_CONFIRMATION" and msg.choice == true and game.startCrucEvolve(self.e_MonsterList:V("SelectedEntryID"):GetInt(), self:V("heatLevel"):GetInt()) then
    game.popPopUp()
  end
end
local LeftMonsterList = {}
function LeftMonsterList:onInit()
  self:V("SelectedEntry"):SetString("")
  self:V("SelectedEntryID"):SetInt(0)
  self:V("NewSelectedEntry"):SetString("")
  self:V("NewSelectedEntryID"):SetInt(0)
  local monsterIds = game.crucibleMonsterVector()
  local numMonsters = monsterIds:size() - 1
  local previous
  for i = 0, numMonsters do
    local entry = menu:addTemplateElement("template_crucibleentry", "crucibleEntry" .. i, self)
    entry:V("List"):SetString(self:name())
    entry:V("MonsterID"):SetInt(monsterIds[i])
    entry:V("EntryNum"):SetInt(i)
    if previous == nil then
      entry:setParent(self)
      entry:setOrientation(lua_sys.MenuOrientation(26.25 * game.menuScaleX(), 0, 4, lua_sys.LEFT, lua_sys.TOP))
      entry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
    else
      entry:setParent(previous)
      entry:setOrientation(lua_sys.MenuOrientation(0, 14, 0, lua_sys.HCENTER, lua_sys.TOP))
      entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
    end
    previous = entry
    entry:init()
    entry:postInit()
    entry:setPositionBroadcast(true)
    if i == 0 then
      entry:C("Touch"):select(entry)
    end
  end
  self:V("NumEntries"):SetInt(monsterIds:size())
  self:selectNewEntry()
end
function LeftMonsterList:onPostInit()
  local numMonsters = self:V("NumEntries"):GetInt()
  for i = 0, numMonsters do
    local entry = self:E("crucibleEntry" .. i)
    if entry ~= nil then
      local monsterLevel = game.monsterLevel(entry:V("MonsterID"):GetInt())
      if monsterLevel < game.evolveMinMonsterLevel() then
        entry:disableEntry()
      elseif not game.crucibleCanEvolveMonsterType(entry:V("MonsterID"):GetInt()) then
        entry:disableEntry()
      end
    end
  end
  local selectedEntry = self:parent():E(self:V("SelectedEntry"):GetString())
  if self:V("SelectedEntryID"):GetInt() ~= 0 and selectedEntry ~= nil and selectedEntry:V("disabled"):GetInt() == 0 then
    self:parent().e_EvolveButton:enable()
  else
    self:parent().e_EvolveButton:disable()
  end
end
function LeftMonsterList:selectNewEntry()
  local oldEntryName = self:V("SelectedEntry"):GetString()
  local newEntryName = self:V("NewSelectedEntry"):GetString()
  if oldEntryName ~= newEntryName then
    if oldEntryName ~= "" then
      local oldEntry = self:parent():E(oldEntryName)
      oldEntry:E("bg"):C("GreySprite"):V("visible"):SetInt(1)
      oldEntry:E("bg"):C("YellowSprite"):V("visible"):SetInt(0)
    end
    local newEntry = self:parent():E(newEntryName)
    self:V("SelectedEntry"):SetString(newEntryName)
    self:V("SelectedEntryID"):SetInt(newEntry:V("MonsterID"):GetInt())
    local selectedEntry = self:parent():E(self:V("SelectedEntry"):GetString())
    if self:V("SelectedEntryID"):GetInt() ~= 0 and selectedEntry ~= nil and selectedEntry:V("disabled"):GetInt() == 0 then
      self:parent().e_EvolveButton:enable()
    else
      self:parent().e_EvolveButton:disable()
    end
    local maxSupportedHeat = game.maxSupportedHeat(self:V("SelectedEntryID"):GetInt())
    local minSupportedHeat = game.minSupportedHeat(self:V("SelectedEntryID"):GetInt())
    if maxSupportedHeat <= self:parent():V("heatLevel"):GetInt() then
      self:parent():V("heatLevel"):SetInt(minSupportedHeat)
    end
    if minSupportedHeat > self:parent():V("heatLevel"):GetInt() then
      self:parent():V("heatLevel"):SetInt(minSupportedHeat)
    end
    self:parent():updateTemperature()
  end
end
CrucibleMenu.LeftMonsterList = LeftMonsterList
local LeftMonsterListSwiper = {}
function LeftMonsterListSwiper:onPostInit(element)
  self:V("direction"):SetInt(lua_sys.MenuSwipeComponent_SwipeDirectionVertical)
  self:V("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeFree)
  self:V("tSteps"):SetFloat(25)
  self:listenToTouches(element)
  local totalHeight = element:V("NumEntries"):GetInt() * (element:parent():E("crucibleEntry0"):absH() + 14) + 14
  if totalHeight > element:absH() then
    self:setScrollSize(totalHeight - element:absH())
  else
    self:setScrollSize(0)
  end
  element:parent():setPositionBroadcast(true)
  local topSprite = element:parent():E("LeftTitleFrame")
  element:parent():C("TouchBlockerTop"):setOrientation(lua_sys.MenuOrientation(0, -(topSprite:absY() + topSprite:absH() - 5), 6, lua_sys.LEFT, lua_sys.BOTTOM))
  element:parent():C("TouchBlockerTop"):setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  local botSprite = element:parent():E("LeftMonsterBg")
  element:parent():C("TouchBlockerBot"):setOrientation(lua_sys.MenuOrientation(0, botSprite:absY() + botSprite:absH() - 10, 6, lua_sys.LEFT, lua_sys.TOP))
  element:parent():C("TouchBlockerBot"):setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
end
function LeftMonsterListSwiper:onTick(element)
  local first = element:parent():E("crucibleEntry0")
  if first then
    local offset = self:scrollOffset()
    if first:getOrientationPosition().y ~= offset then
      first:setOrientationPosition(lua_sys.Vector2(first("xOffset"):GetInt(), offset))
    end
  end
end
LeftMonsterList.Swiper = LeftMonsterListSwiper
local Thermometer = {}
function Thermometer:updateMask()
  local heatLevel = self:parent():V("heatLevel"):GetInt()
  if heatLevel >= 0 and heatLevel <= game.numCrucibleHeatLevels() then
    self:C("Sprite"):V("animation"):SetString("thermometer_0" .. heatLevel + 1)
  end
end
CrucibleMenu.Thermometer = Thermometer
local IncrHeat = {super_onTick = nil}
function IncrHeat:onTick(dt)
  self:super_onTick(dt)
  if self:C("UpSprite"):V("size"):GetFloat() ~= self:C("Overlay"):V("size"):GetFloat() then
    self:C("Overlay"):V("size"):SetFloat(self:C("UpSprite"):V("size"):GetFloat())
  end
end
function IncrHeat:enable()
  self:super_enable()
  self:C("Overlay"):setColor(1, 1, 1)
end
function IncrHeat:disable()
  self:super_disable()
  self:C("Overlay"):setColor(0.5, 0.5, 0.5)
end
function IncrHeat:update()
  local selectedMonsterUid = self:parent():E("LeftMonsterList"):V("SelectedEntryID"):GetInt()
  local maxSupportedHeat = game.maxSupportedHeat(selectedMonsterUid)
  if maxSupportedHeat <= self:parent():V("heatLevel"):GetInt() then
    self:disable()
  else
    self:enable()
  end
end
CrucibleMenu.IncrHeat = IncrHeat
local DecrHeat = {super_onTick = nil}
function DecrHeat:onTick(dt)
  self:super_onTick(dt)
  if self:C("UpSprite"):V("size"):GetFloat() ~= self:C("Overlay"):V("size"):GetFloat() then
    self:C("Overlay"):V("size"):SetFloat(self:C("UpSprite"):V("size"):GetFloat())
  end
end
function DecrHeat:enable()
  self:super_enable()
  self:C("Overlay"):setColor(1, 1, 1)
end
function DecrHeat:disable()
  self:super_disable()
  self:C("Overlay"):setColor(0.5, 0.5, 0.5)
end
function DecrHeat:update()
  local selectedMonsterUid = self:parent():E("LeftMonsterList"):V("SelectedEntryID"):GetInt()
  local minSupportedHeat = game.minSupportedHeat(selectedMonsterUid)
  if self:parent():V("heatLevel"):GetInt() <= math.max(game.crucHeatLevel(), minSupportedHeat) then
    self:disable()
  else
    self:enable()
  end
end
CrucibleMenu.DecrHeat = DecrHeat
local EvolveButton = {
  super_setVisible = nil,
  super_setInvisible = nil,
  super_enable = nil,
  super_disable = nil
}
function EvolveButton:setVisible()
  self:super_setVisible()
  self:C("Label"):V("visible"):SetInt(1)
end
function EvolveButton:setInvisible()
  self:super_setInvisible()
  self:C("Label"):V("visible"):SetInt(0)
end
function EvolveButton:enable()
  self:super_enable()
  self:C("Label"):setColor(1, 1, 1)
end
function EvolveButton:disable()
  self:super_disable()
  self:C("Label"):setColor(0.5, 0.5, 0.5)
end
CrucibleMenu.EvolveButton = EvolveButton
local CEvolveButtonTouch = {}
function CEvolveButtonTouch:startEvolve(element)
  if element:parent().e_MonsterList:V("SelectedEntryID"):GetInt() ~= 0 then
    local numCostumes = game.numPurchasedCostumes(element:parent().e_MonsterList:V("SelectedEntryID"):GetInt())
    if numCostumes > 0 then
      local txt = game.getLocalizedText("EVOLVE_CONFIRMATION_WITH_COSTUMES")
      txt = txt:gsub("%${NUM_COSTUMES}", numCostumes)
      game.displayConfirmation("EVOLVE_CONFIRMATION", txt)
    elseif game.startCrucEvolve(element:parent().e_MonsterList:V("SelectedEntryID"):GetInt(), element:parent():V("heatLevel"):GetInt()) then
      game.popPopUp()
    end
  end
end
EvolveButton.Touch = CEvolveButtonTouch
return CrucibleMenu
