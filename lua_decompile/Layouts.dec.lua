local MenuHelpers = include("MenuHelpers")
local Layout = {
  paddingTop = 0,
  paddingBottom = 0,
  paddingLeft = 0,
  paddingRight = 0,
  spacingX = 0,
  spacingY = 0,
  maxLineElements = 1,
  isCentered = true
}
function Layout:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function Layout:SetOffset(element, offsetX, offsetY)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry:GetVar("xOffset"):SetFloat(offsetX + entry.scrollOffsetX)
    entry:GetVar("yOffset"):SetFloat(offsetY + entry.scrollOffsetY)
  end)
end
local HorizontalLayout = Layout:new()
function HorizontalLayout:Apply(element)
  local maxColumnHeight = element:absH()
  local offsetX = self.paddingLeft
  local offsetY = self.paddingTop
  local entryMaxH = 0
  local currentColumnElements = {}
  local currentColumnHeight = self.paddingTop + self.paddingBottom
  local function fillColumn()
    local py = self.paddingTop
    if self.isCentered then
      py = -(currentColumnHeight - maxColumnHeight) * 0.5 + self.paddingTop
    end
    for _, v in ipairs(currentColumnElements) do
      v:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      v:setOrientation(lua_sys.MenuOrientation(offsetX, py, v.priority or -1, lua_sys.LEFT, lua_sys.TOP))
      v.scrollOffsetX = offsetX
      v.scrollOffsetY = py
      py = py + v:absH() + self.spacingY
    end
  end
  MenuHelpers.ForEachEntry(element, function(entry)
    local entryW = entry:absW()
    local entryH = entry:absH()
    if offsetY > 0 and (offsetY + entryH > maxColumnHeight - self.paddingBottom or #currentColumnElements >= self.maxLineElements and 0 < self.maxLineElements) then
      fillColumn()
      currentColumnElements = {}
      currentColumnWidth = self.paddingTop + self.paddingBottom
      offsetX = offsetX + entryMaxW + self.spacingX
      offsetY = self.paddingTop
      entryMaxW = 0
    end
    table.insert(currentColumnElements, entry)
    offsetY = offsetY + entryH + self.spacingY
    if #currentColumnElements > 1 then
      currentColumnHeight = currentColumnHeight + self.spacingY
    end
    currentColumnHeight = currentColumnHeight + entryH
    if entryW > entryMaxW then
      entryMaxW = entryW
    end
  end)
  fillColumn()
  offsetX = offsetX + entryMaxW + self.paddingRight
  return offsetX
end
local VerticalLayout = Layout:new()
function VerticalLayout:Apply(element)
  local maxRowWidth = element:absW()
  local offsetX = self.paddingLeft
  local offsetY = self.paddingTop
  local entryMaxH = 0
  local currentRowElements = {}
  local currentRowWidth = self.paddingLeft + self.paddingRight
  local function fillRow()
    local px = self.paddingLeft
    if self.isCentered then
      px = -(currentRowWidth - maxRowWidth) * 0.5 + self.paddingLeft
    end
    for _, v in ipairs(currentRowElements) do
      v:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      v:setOrientation(lua_sys.MenuOrientation(px, offsetY, -1, lua_sys.LEFT, lua_sys.TOP))
      v.scrollOffsetX = px
      v.scrollOffsetY = offsetY
      px = px + v:absW() + self.spacingX
    end
  end
  MenuHelpers.ForEachEntry(element, function(entry)
    local entryW = entry:absW()
    local entryH = entry:absH()
    if offsetX > 0 and (offsetX + entryW > maxRowWidth - self.paddingRight or #currentRowElements >= self.maxLineElements and 0 < self.maxLineElements) then
      fillRow()
      currentRowElements = {}
      currentRowWidth = self.paddingLeft + self.paddingRight
      offsetX = self.paddingLeft
      offsetY = offsetY + entryMaxH + self.spacingY
      entryMaxH = 0
    end
    table.insert(currentRowElements, entry)
    offsetX = offsetX + entryW + self.spacingX
    if #currentRowElements > 1 then
      currentRowWidth = currentRowWidth + self.spacingX
    end
    currentRowWidth = currentRowWidth + entryW
    if entryH > entryMaxH then
      entryMaxH = entryH
    end
  end)
  fillRow()
  offsetY = offsetY + entryMaxH + self.paddingBottom
  return offsetY
end
local Layouts = {HorizontalLayout = HorizontalLayout, VerticalLayout = VerticalLayout}
return Layouts
