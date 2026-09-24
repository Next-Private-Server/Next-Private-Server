local ShaderDesaturate = include("ShaderDesaturate")
local CommonListElement_Touch = {}
local CommonListElement = {Touch = CommonListElement_Touch}
function CommonListElement:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
local m_clipX = 0
local m_clipY = 0
local m_clipW = lua_sys.screenWidth()
local m_clipH = lua_sys.screenHeight()
local m_enabled = true
local m_visible = true
local m_selected = false
local m_alpha = 1
local m_touchEnabled = true
local m_dragging = 0
local m_touchStartY = 0
local graphics = {}
local touches = {}
function CommonListElement:registerGraphics(graphicComponent, selectVisiblility)
  status = status or 0
  if graphicComponent then
    table.insert(graphics, {gfx = graphicComponent, selectVis = selectVisiblility})
  else
    print("attempting to register nil graphics")
  end
  self:updateGraphicColor()
  self:updateGraphicVisibility()
end
function CommonListElement:registerTouch(touchComponent)
  if touchComponent then
    table.insert(touches, touchComponent)
  else
    print("attempting to register nil touch")
  end
end
function CommonListElement:isEnabled()
  return m_enabled
end
function CommonListElement:setEnabled(enabled)
  m_enabled = enabled
  self:updateGraphicColor()
end
function CommonListElement:isSelected()
  return m_selected
end
function CommonListElement:setSelected(selected)
  m_selected = selected
  self:updateGraphicVisibility()
end
function CommonListElement:updateGraphicColor()
  for _, v in ipairs(graphics) do
    if m_enabled then
      v.gfx:setShader(nil)
    elseif ShaderDesaturate then
      v.gfx:setShader(ShaderDesaturate)
    end
  end
end
function CommonListElement:updateGraphicVisibility()
  for _, v in ipairs(graphics) do
    if v.selectVis == 1 then
      v.gfx:GetVar("visible"):SetInt(m_selected and 1 or 0)
    elseif v.selectVis == 2 then
      v.gfx:GetVar("visible"):SetInt(m_selected and 0 or 1)
    end
  end
end
function CommonListElement:isVisible()
  return m_visible
end
function CommonListElement:setVisible(visible)
  m_visible = visible
end
function CommonListElement:getClipping()
  return m_clipX, m_clipY, m_clipW, m_clipH
end
function CommonListElement:setClipping(x, y, w, h)
  m_clipX = x
  m_clipY = y
  m_clipW = w
  m_clipH = h
  for _, v in ipairs(graphics) do
    v.gfx:setClipRect(m_clipX, m_clipY, m_clipW, m_clipH)
  end
  for _, v in ipairs(touches) do
    v:setClipRect(m_clipX, m_clipY, m_clipW, m_clipH)
  end
end
function CommonListElement:getAlpha()
  return m_alpha
end
function CommonListElement:setAlpha(alpha)
  m_alpha = alpha
  for _, v in ipairs(graphics) do
    v.gfx:GetVar("alpha"):SetFloat(m_alpha)
  end
  for _, v in ipairs(touches) do
    v:GetVar("enabled"):SetInt(m_alpha > 0.1 and 1 or 0)
  end
end
function CommonListElement_Touch:onInit(element)
  m_dragging = 0
  m_touchStartY = 0
end
function CommonListElement_Touch:onPostInit(element)
  self:setSize(lua_sys.Vector2(element:GetElement("bg"):absW() * 1.25, element:GetElement("bg"):absH() * 1.5))
  self("yOffset"):SetInt(element:GetElement("bg"):absH() * -0.25)
end
function CommonListElement_Touch:onTouchDrag(element, x, y)
  m_dragging = m_dragging + math.abs(y - m_touchStartY)
  m_touchStartY = y
end
function CommonListElement_Touch:onTouchDown(element, x, y)
  m_touchStartY = y
end
function CommonListElement_Touch:onTouchUp(element, x, y)
  if m_touchEnabled then
    if m_dragging < 10 and element.onSelected then
      element:onSelected()
    end
    m_dragging = 0
    m_touchStartY = 0
  end
end
return CommonListElement
