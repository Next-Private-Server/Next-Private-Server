local FadeTransition = include("FadeTransition")
local BreedingMonsterListFilter = {
  Items = {
    BG = {}
  },
  ArrowButton = {
    Touch = {},
    Sprite = {},
    Icon = {}
  },
  Tray = {
    BG = {},
    Grid = {},
    Corner = {}
  },
  Block = {
    Touch = {}
  }
}
function BreedingMonsterListFilter:onInit()
  self.enabledFilters = {}
end
function BreedingMonsterListFilter:onPostInit()
  self.ArrowButton.Icon:GetVar("spriteName"):SetString("filter_arrow")
  self.ArrowButton.Icon:setColor(1, 1, 1)
  self.ArrowButton.Sprite:setColor(1, 1, 1)
end
function BreedingMonsterListFilter:onTick(dt)
  if self.trayTransition then
    self.trayTransition:Tick(dt)
  end
end
function BreedingMonsterListFilter:Setup(list, availableGenes, flipped)
  self.list = list
  self.filterItems = {}
  self.flipped = flipped or false
  if #availableGenes <= 4 then
    self.ArrowButton.Sprite:GetVar("visible"):SetInt(0)
    self.ArrowButton.Icon:GetVar("visible"):SetInt(0)
    self.ArrowButton.Touch:GetVar("enabled"):SetInt(0)
    self.trayHidden = true
    self.Tray.BG:GetVar("visible"):SetInt(0)
    self.Tray.Corner:GetVar("visible"):SetInt(0)
    if #availableGenes > 1 then
      self:populateItems(availableGenes)
    else
      self.Items.BG:GetVar("visible"):SetInt(0)
    end
  else
    self.trayTransition = FadeTransition:new({
      duration = 0.2,
      ease = lua_sys.Linear_EaseNone,
      onDoneShow = function()
        self.trayHidden = false
        for i, item in ipairs(self.filterItems) do
          item.Touch:GetVar("enabled"):SetInt(1)
        end
      end,
      onDoneHide = function()
        self.trayHidden = true
        for i, item in ipairs(self.filterItems) do
          item.Touch:GetVar("enabled"):SetInt(0)
        end
      end,
      onUpdate = function(alpha)
        local trayAlpha = alpha * 0.75
        self.Tray.BG:GetVar("alpha"):SetFloat(trayAlpha)
        self.Tray.Corner:GetVar("alpha"):SetFloat(trayAlpha)
        for i, item in ipairs(self.filterItems) do
          item.Sprite:GetVar("alpha"):SetFloat(alpha)
        end
      end
    })
    if self.flipped then
      local offsetX = self.ArrowButton:GetVar("xOffset"):GetFloat()
      local offsetY = self.ArrowButton:GetVar("yOffset"):GetFloat()
      self.ArrowButton:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      self.ArrowButton:setOrientation(lua_sys.MenuOrientation(offsetX, offsetY, -3, lua_sys.LEFT, lua_sys.VCENTER))
      self.ArrowButton.Icon:GetVar("hFlip"):SetInt(1)
      self.ArrowButton.Icon:GetVar("xOffset"):SetFloat(-2 * BreedingMenuScaleX())
      offsetX = self.Tray:GetVar("xOffset"):GetFloat()
      offsetY = self.Tray:GetVar("yOffset"):GetFloat()
      self.Tray:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      self.Tray:setOrientation(lua_sys.MenuOrientation(offsetX, offsetY, 0, lua_sys.RIGHT, lua_sys.TOP))
      offsetX = self.Tray.Corner:GetVar("xOffset"):GetFloat()
      offsetY = self.Tray.Corner:GetVar("yOffset"):GetFloat()
      self.Tray.Corner:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
      self.Tray.Corner:setOrientation(lua_sys.MenuOrientation(offsetX, offsetY, -1, lua_sys.LEFT, lua_sys.VCENTER))
      self.Tray.Corner:GetVar("hFlip"):SetInt(1)
    end
    self.ArrowButton.Touch:GetVar("enabled"):SetInt(1)
    function self.ArrowButton.Touch.onTouchUp(component, element, x, y)
      if self.trayHidden then
        self.trayTransition:Show()
      else
        for i, item in ipairs(self.filterItems) do
          item.Touch:GetVar("enabled"):SetInt(0)
        end
        self.trayTransition:Hide()
      end
    end
    self.trayHidden = true
    self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgTouchDown", "gotMsgTouchDown")
    self:populateTray(availableGenes)
    self.trayTransition:SetAlpha(0)
    for i, item in ipairs(self.filterItems) do
      item.Touch:GetVar("enabled"):SetInt(0)
    end
  end
end
function BreedingMonsterListFilter:gotMsgTouchDown(msg)
  if self.trayHidden then
    return
  end
  local touchX = msg.x
  local touchY = msg.y
  local contains = function(x, y, rX, rY, rW, rH)
    return rX <= x and x <= rX + rW and rY <= y and y <= rY + rH
  end
  if not contains(touchX, touchY, self.Tray:absX(), self.Tray:absY(), self.Tray:absW(), self.Tray:absH()) then
    for i, item in ipairs(self.filterItems) do
      item.Touch:GetVar("enabled"):SetInt(0)
    end
    self.trayTransition:Hide()
  end
end
function BreedingMonsterListFilter:toggleFilter(item)
  if item.filterEnabled then
    item.filterEnabled = false
    item.Sprite:setColor(0.5, 0.5, 0.5)
  else
    item.filterEnabled = true
    item.Sprite:setColor(1, 1, 1)
  end
  if item.filterEnabled then
    table.insert(self.enabledFilters, item.gene)
  else
    for i, gene in ipairs(self.enabledFilters) do
      if gene == item.gene then
        table.remove(self.enabledFilters, i)
        break
      end
    end
  end
  lua_sys.playSoundFx("audio/sfx/item_select.wav")
  self.list:ApplyFilter()
end
function BreedingMonsterListFilter:populateItems(availableGenes)
  local itemSize = 40 * BreedingMenuScaleX()
  local margin = 0
  for i, gene in ipairs(availableGenes) do
    do
      local item = menu:addTemplateElement("template_breeding_monsterlist_filter_item", "breeding_filter_" .. i, self.Items)
      item:relativeTo(self.Items)
      local xOffset = (margin + ((i - 1) * itemSize + itemSize / 2)) * (self.flipped and 1 or -1)
      item:setOrientation(lua_sys.MenuOrientation(xOffset, 0, -2, lua_sys.HCENTER, lua_sys.VCENTER))
      item:setRelativeObjectAnchors(self.flipped and lua_sys.LEFT or lua_sys.RIGHT, lua_sys.VCENTER)
      item:init()
      item.gene = gene
      item.filterEnabled = false
      item.Sprite:GetVar("spriteName"):SetString(gene)
      item.Sprite:GetVar("sheetName"):SetString("xml_resources/hud02.xml")
      item.Sprite:GetVar("size"):SetFloat(0.45 * BreedingMenuScaleX())
      item:setPositionBroadcast(true)
      function item.Touch.onTouchUp(component, element, x, y)
        self:toggleFilter(item)
      end
      table.insert(self.filterItems, item)
    end
  end
end
function BreedingMonsterListFilter:populateTray(availableGenes)
  local itemsPerRow = 4
  local marginSize = 8 * BreedingMenuScaleX()
  local availableWidth = self.Tray:absW() - 2 * marginSize
  local gridCellSize = availableWidth / itemsPerRow
  for i, gene in ipairs(availableGenes) do
    do
      local col = (i - 1) % itemsPerRow
      local row = math.floor((i - 1) / itemsPerRow)
      local xOffset = marginSize + col * gridCellSize + gridCellSize / 2
      local yOffset = marginSize + row * gridCellSize + gridCellSize / 2
      local item = menu:addTemplateElement("template_breeding_monsterlist_filter_item", "breeding_filter_" .. i, self.Tray.Grid)
      item:relativeTo(self.Tray.Grid)
      item:setOrientation(lua_sys.MenuOrientation(xOffset, yOffset, -2, lua_sys.HCENTER, lua_sys.VCENTER))
      item:setRelativeObjectAnchors(lua_sys.TOP, lua_sys.LEFT)
      item:init()
      item.gene = gene
      item.filterEnabled = false
      item.Sprite:GetVar("spriteName"):SetString(gene)
      item.Sprite:GetVar("sheetName"):SetString("xml_resources/hud02.xml")
      item:setPositionBroadcast(true)
      function item.Touch.onTouchUp(component, element, x, y)
        self:toggleFilter(item)
      end
      table.insert(self.filterItems, item)
    end
  end
  local rowsNeeded = math.ceil(#self.filterItems / itemsPerRow)
  local trayHeight = rowsNeeded * gridCellSize + 2 * marginSize
  self.Tray:setSize(lua_sys.Vector2(self.Tray:absW(), trayHeight))
end
return BreedingMonsterListFilter
