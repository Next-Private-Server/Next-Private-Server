local MenuHelpers = {}
function MenuHelpers.ApplyHorizontalLayout(perceptibles)
  local offsetX = 0
  for _, perceptible in ipairs(perceptibles) do
    if type(perceptible) ~= "table" then
      perceptible("xOffset"):SetInt(offsetX)
    end
    offsetX = offsetX + perceptible:absW()
  end
  return offsetX
end
function MenuHelpers.ApplyVerticalLayout(perceptibles)
  local offsetY = 0
  for _, perceptible in ipairs(perceptibles) do
    if type(perceptible) ~= "table" then
      perceptible("yOffset"):SetInt(offsetY)
    end
    offsetY = offsetY + perceptible:absH()
  end
  return offsetY
end
function MenuHelpers.CenterHorizontally(perceptibles)
  local totalWidth = 0
  for _, perceptible in ipairs(perceptibles) do
    totalWidth = totalWidth + perceptible:absW()
  end
  local offsetX = -totalWidth * 0.5
  for _, perceptible in ipairs(perceptibles) do
    if type(perceptible) ~= "table" then
      perceptible("xOffset"):SetInt(offsetX)
    end
    offsetX = offsetX + perceptible:absW()
  end
end
function MenuHelpers.CenterVertically(perceptibles)
  local totalHeight = 0
  for _, perceptible in ipairs(perceptibles) do
    totalHeight = totalHeight + perceptible:absH()
  end
  local offsetY = -totalHeight * 0.5
  for _, perceptible in ipairs(perceptibles) do
    if type(perceptible) ~= "table" then
      perceptible("yOffset"):SetInt(offsetY)
    end
    offsetY = offsetY + perceptible:absH()
  end
end
function MenuHelpers.JustifyHorizontally(perceptibles, parentWidth)
  local totalPerceptibleWidth = 0
  for _, perceptible in ipairs(perceptibles) do
    totalPerceptibleWidth = totalPerceptibleWidth + perceptible:absW()
  end
  local totalWidth = parentWidth or 0
  if totalPerceptibleWidth > totalWidth then
    totalWidth = totalPerceptibleWidth
  end
  local offsetX = -totalWidth * 0.5
  local numElements = #perceptibles
  local perceptSpace = totalWidth / numElements
  for _, perceptible in ipairs(perceptibles) do
    local buffer = perceptSpace - perceptible:absW()
    offsetX = offsetX + buffer / 2
    if type(perceptible) ~= "table" then
      perceptible("xOffset"):SetInt(offsetX)
    end
    offsetX = offsetX + perceptible:absW() + buffer / 2
  end
end
function MenuHelpers.CreateSpacer(width, height)
  return {
    absW = function()
      return width
    end,
    absH = function()
      return height
    end
  }
end
function MenuHelpers.ForEachElement(element, action, options)
  options = options or {}
  local entryName = options.entryName or "entry"
  local offset = options.offset or 0
  local i = offset
  while true do
    local entry = element:GetElement(entryName .. i)
    if entry == nil then
      break
    end
    if not swig_equals(element, entry:parent()) then
      break
    end
    action(entry, i)
    i = i + 1
  end
end
MenuHelpers.ForEachEntry = MenuHelpers.ForEachElement
function MenuHelpers.SetClipFrom(targetPerceptible, fromScriptable)
  targetPerceptible:setClipRect(fromScriptable("clipX"):GetFloat(), fromScriptable("clipY"):GetFloat(), fromScriptable("clipW"):GetFloat(), fromScriptable("clipH"):GetFloat())
end
function MenuHelpers.ShrinkTextToWidth(text, textComponent, maxWidth)
  maxWidth = maxWidth or 100 * game.menuScaleX()
  local textLength = string.len(text)
  local result = text
  textComponent("text"):SetString(result)
  local charsToRemove = 0
  while maxWidth < textComponent:absW() and textLength > charsToRemove do
    charsToRemove = charsToRemove + 1
    result = string.sub(text, 0, textLength - charsToRemove) .. "..."
    textComponent("text"):SetString(result)
  end
  return result
end
function MenuHelpers.ShrinkTextToNumChars(text, textComponent, numChars)
  local result = text
  numChars = numChars or 9
  if numChars < string.len(result) then
    result = string.sub(result, 0, numChars - 1) .. "..."
  end
  textComponent("text"):SetString(result)
  return result
end
function MenuHelpers.MagicScale(matchWidthOrHeight)
  local referenceResolutionWidth = 480
  local referenceResolutionHeight = 320
  matchWidthOrHeight = matchWidthOrHeight or 0.5
  return math.pow(lua_sys.screenWidth() / referenceResolutionWidth, 1 - matchWidthOrHeight) * math.pow(lua_sys.screenHeight() / referenceResolutionHeight, matchWidthOrHeight)
end
function MenuHelpers.AspectRatioReference()
  return 1.5
end
function MenuHelpers.AspectRatio()
  return lua_sys.screenWidth() / lua_sys.screenHeight()
end
function MenuHelpers.DoCelebrateEffect(element, options)
  options = options or {}
  local playSound = options.playSound or true
  if playSound then
    lua_sys.playSoundFx("audio/sfx/level_up_player.wav")
  end
  local midX = lua_sys.screenWidth() / 2
  local midY = lua_sys.screenHeight() / 2
  local scale = 2 * game.windowScaleX()
  local emissionScale = 0.5
  game.playParticle("particles/particle_growup.psi", "gfx/particles/particle_growup", midX, midY, "Tutorial", 0.001, scale, emissionScale)
  game.playParticle("particles/particle_growup.psi", "gfx/particles/particle_growup", midX, midY, "Tutorial", 0.001, scale, emissionScale)
  game.playParticle("particles/particle_growup.psi", "gfx/particles/particle_growup", midX, midY, "Tutorial", 0.001, scale, emissionScale)
end
function MenuHelpers.DoUnlockEffect(element)
  local x = element:absX() + element:absW() * 0.5
  local y = element:absY() + element:absH() * 0.5
  game.playParticle("particles/particle_diamond_get.psi", "gfx/particles/particle_diamond", x, y, "Tutorial", 0.001, 1, 1)
end
function MenuHelpers.CreateFromTemplate(args)
  local template = args.template
  if not template then
    print("template arg required")
    return nil
  end
  local name = args.name or "New Element"
  local parent = args.parent
  local relativeTo = args.relativeTo
  local relativeAnchorH = args.relativeAnchorH or lua_sys.LEFT
  local relativeAnchorV = args.relativeAnchorV or lua_sys.TOP
  local anchorH = args.anchorH or lua_sys.LEFT
  local anchorV = args.anchorV or lua_sys.TOP
  local priority = args.priority or 0
  local offsetX = args.offsetX or 0
  local offsetY = args.offsetY or 0
  local e = menu:addTemplateElement(args.template, name, parent)
  if relativeTo then
    e:relativeTo(relativeTo)
    e:setRelativeObjectAnchors(relativeAnchorH, relativeAnchorV)
  end
  if args.setupFn then
    args.setupFn(e)
  end
  e:setOrientation(lua_sys.MenuOrientation(offsetX, offsetY, priority, anchorH, anchorV))
  e:init()
  e:setPositionBroadcast(true)
  e:postInit()
  return e
end
return MenuHelpers
