local Button = {}
function Button.onInit(element, options)
  options = options or {}
  local buttonMapping = options.buttonMapping or 0
  local buttonScale = options.buttonScale or 1
  local sfx = options.sfx or "audio/sfx/menu_click.wav"
  local lockEnabled = options.lockEnabled or 0
  local componentName = options.componentName or "Sprite"
  element("ButtonMapping"):SetInt(buttonMapping)
  element("ButtonScale"):SetFloat(buttonScale)
  element("SFX"):SetString(sfx)
  element("LockEnabled"):SetInt(lockEnabled)
  element("ComponentName"):SetString(componentName)
  element:setPositionBroadcast(true)
  element("locked"):SetInt(0)
  if buttonMapping ~= 0 then
    element("buttonDown"):SetInt(0)
    element:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgKeyDown", "gotMsgKeyDown")
    element:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgKeyUp", "gotMsgKeyUp")
  end
  element("ButtonState"):SetInt(game.BUTTON_IDLE)
  element("TickTimer"):SetFloat(0)
  element("isCurrentlyLocked"):SetInt(0)
end
function Button.onTick(element, dt)
  local componentName = element("ComponentName"):GetString()
  local buttonState = element("ButtonState"):GetInt()
  local isLocked = element("isCurrentlyLocked"):GetInt()
  local buttonScale = element("ButtonScale"):GetFloat()
  if buttonState ~= game.BUTTON_IDLE or isLocked == 1 then
    local newTime = element("TickTimer"):GetFloat() + dt
    element("TickTimer"):SetFloat(newTime)
    if buttonState == game.BUTTON_PRESSED then
      local size = lua_sys.smooth(buttonScale, buttonScale - 0.03, newTime * 15)
      element[componentName]("size"):SetFloat(size)
      if size == buttonScale - 0.03 then
        element("ButtonState"):SetInt(game.BUTTON_IDLE)
      end
    elseif buttonState == game.BUTTON_RELEASED then
      if newTime < 0.1 then
        local size = lua_sys.smooth(buttonScale - 0.03, buttonScale + 0.05, newTime * 20)
        element[componentName]("size"):SetFloat(size)
      elseif newTime < 0.3 then
        local size = lua_sys.smooth(buttonScale + 0.05, buttonScale, (newTime - 0.1) * 20)
        element[componentName]("size"):SetFloat(size)
        if size == buttonScale then
          element("ButtonState"):SetInt(game.BUTTON_IDLE)
        end
      end
    end
  end
  if isLocked == 1 and 1 < element("TickTimer"):GetFloat() then
    element("isCurrentlyLocked"):SetInt(0)
    element.Touch("enabled"):SetInt(1)
  end
end
function Button.onPress(element)
  local componentName = element("ComponentName"):GetString()
  element[componentName]:setColor(0.5, 0.5, 0.5)
  element("ButtonState"):SetInt(game.BUTTON_PRESSED)
  element("TickTimer"):SetFloat(0)
end
function Button.onRelease(element)
  local componentName = element("ComponentName"):GetString()
  element[componentName]:setColor(1, 1, 1)
  local sfx = element("SFX"):GetString()
  if sfx ~= "" then
    lua_sys.playSoundFx(sfx)
  end
  element("ButtonState"):SetInt(game.BUTTON_RELEASED)
  element("TickTimer"):SetFloat(0)
  local lockEnabled = element("LockEnabled"):GetInt()
  if lockEnabled == 1 then
    element("isCurrentlyLocked"):SetInt(1)
    element.Touch("enabled"):SetInt(0)
  end
end
return Button
