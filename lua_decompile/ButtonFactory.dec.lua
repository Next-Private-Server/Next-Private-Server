local ButtonFactory = {}
function ButtonFactory:CreateButton(params)
  params = params or {}
  local name = params.name or "Button"
  local xOffset = params.xOffset or 0
  local yOffset = params.yOffset or 0
  local relAnchorH = params.relAnchorH or lua_sys.HCENTER
  local relAnchorV = params.relAnchorV or lua_sys.VCENTER
  local anchorH = params.anchorH or lua_sys.HCENTER
  local anchorV = params.anchorV or lua_sys.VCENTER
  local priority = params.priority or 0
  local spriteScale = params.spriteScale or 0.5 * game.hudScale()
  local text = params.text or "Button"
  local layer = params.layer or "HUD"
  local onTouchUp = params.onTouchUp or function()
    print("Button Click!")
  end
  if not params.root then
    error("Need to set 'root'!")
  end
  if not params.relativeTo then
    error("Need to set 'relativeTo'!")
  end
  local button = menu:addTemplateElement("template_spritesheetbutton", name, params.root)
  button:relativeTo(params.relativeTo)
  button:setRelativeObjectAnchors(relAnchorH, relAnchorV)
  button:setOrientation(lua_sys.MenuOrientation(xOffset, yOffset, priority, anchorH, anchorV))
  button:templateVars().layer = layer
  button:templateVars().text = text
  button:templateVars().spriteScale = spriteScale
  button:init()
  button:setPositionBroadcast(true)
  button:postInit()
  local superTouchUp = button.Touch.onTouchUp
  function button.Touch.onTouchUp(c, e, x, y)
    if superTouchUp then
      superTouchUp(c, e, x, y)
    end
    onTouchUp(c, e, x, y)
  end
  function button.show(element)
    element:DoStoredScript("setVisible")
  end
  function button.hide(element)
    element:DoStoredScript("setInvisible")
  end
  return button
end
return ButtonFactory
