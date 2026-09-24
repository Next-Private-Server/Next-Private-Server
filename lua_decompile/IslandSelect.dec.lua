local IslandSelect = {}
local TAU = math.pi * 2
local RADIUS = 175 * game.menuScaleX()
local Pulser = include("Pulser")
local pulsers = {}
function IslandSelect.onInit(element, curIsland)
  element("DragIsland"):SetInt(0)
  element("entryCurrentX"):SetInt(0)
  element("entryCurrentY"):SetInt(0)
  element("StartAngle"):SetFloat(0)
  element("CurrentAngle"):SetFloat(0)
  element("DragStartIndex"):SetInt(0)
  element("DragOffset"):SetFloat(0)
  element("SnapIslandToPosition"):SetInt(0)
  element("SnapTransitionTime"):SetInt(0)
  element("activeIsland"):SetInt(curIsland)
  element("NumIslands"):SetInt(0)
  element("activeIndex"):SetInt(0)
  pulsers = {}
  element:DoStoredScript("populate")
  element:parent().GoButton:DoStoredScript("updateText")
end
local EnableButtons = function(element, enable)
  local enableScript = "enable"
  if enable == false then
    enableScript = "disable"
  end
  element:parent().LeftButton:DoStoredScript(enableScript)
  element:parent().RightButton:DoStoredScript(enableScript)
  element:parent().MirrorButton:DoStoredScript(enableScript)
  element:parent().GoButton:DoStoredScript(enableScript)
  element:parent().HelpButton:DoStoredScript(enableScript)
  if element:HasVar("friendIslands") == false then
    element:parent().BackButton:DoStoredScript(enableScript)
    if enable == true then
      local activeIsland = element("activeIsland"):GetInt()
      if activeIsland == game.IslandType_TRIBAL or activeIsland == game.IslandType_COMPOSER or activeIsland == game.IslandType_BATTLE then
        element:parent().BookButton:DoStoredScript("disable")
      else
        element:parent().BookButton:DoStoredScript("enable")
      end
    else
      element:parent().BookButton:DoStoredScript("disable")
    end
  end
end
IslandSelect.EnableButtons = EnableButtons
local UpdateActiveIslandEntry = function(element, oldIndex, newIndex)
  local oldEntry = element:parent().IslandList:GetElement("islandEntry" .. oldIndex)
  oldEntry.Overlay:setColor(0.5, 0.5, 0.5)
  local nextActiveEntry = element:GetElement("islandEntry" .. newIndex)
  local nextActiveIsland = nextActiveEntry("IslandId"):GetInt()
  if element:HasVar("friendIslands") then
    if not game.doesFriendOwnIsland(nextActiveIsland) then
      nextActiveEntry:DoStoredScript("disable")
      nextActiveEntry.Lock("visible"):SetInt(1)
      element:parent().GoButton:DoStoredScript("disable")
    else
      nextActiveEntry:DoStoredScript("enable")
      nextActiveEntry.Lock("visible"):SetInt(0)
    end
  elseif not game.isIslandOwned(nextActiveIsland) then
    if not game.hasNecessaryPrevIslandsToUnlock(nextActiveIsland) then
      nextActiveEntry.Overlay:setColor(0.5, 0.5, 0.5)
    elseif not game.canUnlockIsland(nextActiveIsland) then
      nextActiveEntry.Overlay:setColor(0.5, 0.5, 0.5)
    else
      nextActiveEntry.Overlay:setColor(1, 1, 1)
    end
  else
    nextActiveEntry.Overlay:setColor(1, 1, 1)
  end
  element("activeIndex"):SetInt(newIndex)
  element("activeIsland"):SetInt(nextActiveIsland)
end
IslandSelect.UpdateActiveIslandEntry = UpdateActiveIslandEntry
local CalculateAngle = function(element, x, y)
  local numIslands = element("NumIslands"):GetInt()
  local degreesBetween = 360 / numIslands
  local rotAmount = 90 + degreesBetween * element("activeIndex"):GetInt()
  local angle = math.deg(math.atan2(y - lua_sys.screenHeight() / 2 + 60 * game.menuScaleX(), x - lua_sys.screenWidth() / 2)) + 180
  return angle
end
IslandSelect.CalculateAngle = CalculateAngle
local function CalculateIslandPositionScale(element, i, relativeIndex, amount)
  local numIslands = element("NumIslands"):GetInt()
  local degreesBetween = 360 / numIslands
  local angle = TAU * -(i / numIslands)
  local xPosOrig = RADIUS * math.cos(angle)
  local yPosOrig = RADIUS * math.sin(angle)
  local zPosOrig = 0
  local rotAmount = 90 + degreesBetween * relativeIndex + amount
  local xPosRot = xPosOrig * math.cos(math.rad(rotAmount)) - yPosOrig * math.sin(math.rad(rotAmount))
  local yPosRot = xPosOrig * math.sin(math.rad(rotAmount)) + yPosOrig * math.cos(math.rad(rotAmount))
  local zPosRot = zPosOrig
  local xPos = xPosRot
  local yPos = yPosRot * math.cos(math.rad(72.5)) - zPosRot * math.sin(math.rad(72.5))
  local zPos = yPosRot * math.sin(math.rad(72.5)) + zPosRot * math.cos(math.rad(72.5))
  xPos = xPos / (3 / (3 + zPos / RADIUS))
  yPos = yPos / (3 / (3 + zPos / RADIUS))
  zPos = zPos / game.menuScaleX() / -8.75 - 20
  local islandScale = 3 / (3 + (40 + zPos)) * 2 + 1
  return xPos, yPos, zPos, islandScale
end
IslandSelect.CalculateIslandPositionScale = CalculateIslandPositionScale
local function UpdateIslands(element, relativeIndex, amount, dt)
  local numIslands = element("NumIslands"):GetInt()
  local degreesBetween = 360 / numIslands
  for i = 0, numIslands - 1 do
    local xPos, yPos, zPos, islandScale = CalculateIslandPositionScale(element, i, relativeIndex, amount)
    local islandEntry = element:GetElement("islandEntry" .. i)
    islandEntry:setOrientationPosition(lua_sys.Vector2(xPos, yPos - 60 * game.menuScaleX()))
    islandEntry:setOrientationPriority(zPos / 2)
    islandEntry.Overlay("size"):SetFloat(0.2 * game.menuScaleX() * islandScale)
    islandEntry.Lock("size"):SetFloat(0.35 * game.menuScaleX() * islandScale)
    if element:HasVar("friendIslands") then
      islandEntry.TorchesUnlit("size"):SetFloat(0.2 * game.menuScaleX() * islandScale)
      islandEntry.LightTorchFlag("size"):SetFloat(0.2 * game.menuScaleX() * islandScale)
    end
  end
end
IslandSelect.UpdateIslands = UpdateIslands
local function HandleDrag(element, dt)
  local numIslands = element("NumIslands"):GetInt()
  local amount = 0
  local degreesBetween = 360 / numIslands
  local activeIndex = element("activeIndex"):GetInt()
  local newActiveIndex = activeIndex
  local relativeIndex = activeIndex
  if element("SnapIslandToPosition"):GetInt() == 1 then
    local transitionTime = element("SnapTransitionTime"):GetFloat() - dt
    if transitionTime < 0 then
      transitionTime = 0
    end
    local dragOffset = element("DragOffset"):GetFloat()
    if dragOffset > 0 then
      amount = dragOffset - dragOffset * (1 - transitionTime)
    else
      amount = dragOffset + -dragOffset * (1 - transitionTime)
    end
    element("SnapTransitionTime"):SetFloat(transitionTime)
    if transitionTime == 0 then
      element("SnapIslandToPosition"):SetInt(0)
      EnableButtons(element, true)
    end
  else
    amount = element("CurrentAngle"):GetFloat() - element("StartAngle"):GetFloat()
    newActiveIndex = element("DragStartIndex"):GetInt()
    if amount ~= 0 then
      newActiveIndex = newActiveIndex + lua_sys.Math.Round(amount / degreesBetween)
    end
    relativeIndex = element("DragStartIndex"):GetInt()
    if newActiveIndex > numIslands - 1 then
      newActiveIndex = newActiveIndex - numIslands
    end
    if newActiveIndex < 0 then
      newActiveIndex = newActiveIndex + numIslands
    end
  end
  UpdateIslands(element, relativeIndex, amount, dt)
  if element:HasVar("friendIslands") == false then
    element:parent().SaleDetails:DoStoredScript("populate")
  end
  element:parent().IslandDetails:DoStoredScript("populate")
  element:parent().IslandTitle:DoStoredScript("populate")
  UpdateActiveIslandEntry(element, activeIndex, newActiveIndex)
  element:parent().GoButton:DoStoredScript("updateText")
end
IslandSelect.HandleDrag = HandleDrag
function IslandSelect.onTick(element, dt)
  local numIslands = element("NumIslands"):GetInt()
  local amount = 0
  local degreesBetween = 360 / numIslands
  local transitionState = element:parent()("TransitionState"):GetInt()
  local draggingIsland = element("DragIsland"):GetInt()
  local snapToPosition = element("SnapIslandToPosition"):GetInt()
  if draggingIsland == 1 or snapToPosition == 1 then
    HandleDrag(element, dt)
  end
  if transitionState ~= 0 and dt <= 0.5 or (transitionState == 0 or transitionState == -2) and 0 < element:parent()("TransitionTime"):GetFloat() and dt <= 0.5 then
    local transitionTime = element:parent()("TransitionTime"):GetFloat() - dt
    if transitionTime < 0 then
      transitionTime = 0
    end
    if transitionState == -1 or transitionState == -2 then
      amount = -(degreesBetween - transitionTime * 4 * degreesBetween)
    else
      amount = -(transitionTime * 4 * degreesBetween) - degreesBetween
    end
    UpdateIslands(element, element("activeIndex"):GetInt() + 1, amount, dt)
    element:parent()("TransitionTime"):SetFloat(transitionTime)
    if transitionTime == 0 then
      if transitionState == -2 then
        transitionState = 0
      end
      if transitionState ~= 0 then
        transitionTime = 0.25
      end
      if transitionState == 0 then
        EnableButtons(element, true)
        element:parent()("spinning"):SetInt(0)
      end
      if element:HasVar("friendIslands") == false then
        element:parent().SaleDetails:DoStoredScript("populate")
      end
      element:parent().IslandDetails:DoStoredScript("populate")
      element:parent().IslandTitle:DoStoredScript("populate")
      local activeIndex = element("activeIndex"):GetInt()
      local oldIndex = activeIndex
      if transitionState == -1 then
        if activeIndex == 0 then
          activeIndex = element:parent().IslandList("NumIslands"):GetInt() - 1
        else
          activeIndex = activeIndex - 1
        end
      elseif transitionState == 1 then
        if activeIndex == numIslands - 1 then
          activeIndex = 0
        else
          activeIndex = activeIndex + 1
        end
      end
      UpdateActiveIslandEntry(element, oldIndex, activeIndex)
      element:parent().GoButton:DoStoredScript("updateText")
      element:parent()("TransitionTime"):SetFloat(transitionTime)
      element:parent()("TransitionState"):SetInt(transitionState)
    end
  end
  for i = 0, numIslands - 1 do
    if pulsers[i] ~= nil then
      if not pulsers[i]:isActive() then
        pulsers[i]:activate()
      end
      pulsers[i]:tick(dt)
    end
  end
end
function IslandSelect.populate(element, template)
  local numIslands = element("NumIslands"):GetInt()
  for i = 0, numIslands - 1 do
    element:RemoveElement(element:GetElement("islandEntry" .. i))
  end
  local curIsland = element("activeIsland"):GetInt()
  local islands
  if game.isMirrorIsland(curIsland) then
    islands = game.islandSorting(true)
    numIslands = islands:size()
    element:parent().MirrorButton.Overlay("spriteName"):SetString("button_mirror_out")
    element:parent().MirrorButton.Text("text"):SetString("CONTEXTBAR_UNMIRROR_LABEL")
  else
    islands = game.islandSorting(false)
    numIslands = islands:size()
    element:parent().MirrorButton.Overlay("spriteName"):SetString("button_mirror_in")
    element:parent().MirrorButton.Text("text"):SetString("CONTEXTBAR_MIRROR_LABEL")
  end
  local activeIndex = 0
  for i = 0, islands:size() - 1 do
    if islands[i] == curIsland then
      activeIndex = i
    end
  end
  element("activeIndex"):SetInt(activeIndex)
  element("NumIslands"):SetInt(numIslands)
  for i = 0, numIslands - 1 do
    do
      local islandEntry = menu:addTemplateElement(template, "islandEntry" .. i, element)
      islandEntry("IslandId"):SetInt(islands[i])
      if islands[i] == curIsland then
        islandEntry("IslandActive"):SetInt(1)
      else
        islandEntry("IslandActive"):SetInt(0)
      end
      local xPos, yPos, zPos, islandScale = CalculateIslandPositionScale(element, i, activeIndex, 0)
      islandEntry("IslandScale"):SetFloat(islandScale)
      islandEntry:setParent(element)
      islandEntry:relativeTo(element)
      islandEntry:setOrientation(lua_sys.MenuOrientation(xPos, yPos - 60 * game.menuScaleX(), zPos / 3, lua_sys.HCENTER, lua_sys.VCENTER))
      islandEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      islandEntry:setPositionBroadcast(false)
      islandEntry:init()
      islandEntry:postInit()
      if element:HasVar("friendIslands") then
        if islands[i] == curIsland then
          islandEntry:DoStoredScript("enable")
        else
          islandEntry:DoStoredScript("disable")
        end
        local flagPulser = Pulser.new({
          duration = 1.5,
          scale = 1.2,
          ease = lua_sys.EaseInOut,
          onUpdate = function(scale)
            islandEntry:GetComponent("LightTorchFlag"):setScale(lua_sys.Vector2(scale, scale))
          end
        })
        flagPulser:activate()
        pulsers[i] = flagPulser
      end
    end
  end
  element:setPositionBroadcast(true)
  if element:HasVar("friendIslands") == false then
    if curIsland == game.IslandType_TRIBAL or curIsland == game.IslandType_COMPOSER or curIsland == game.IslandType_BATTLE then
      element:parent().BookButton:DoStoredScript("disable")
    else
      element:parent().BookButton:DoStoredScript("enable")
    end
  end
end
function IslandSelect.islandTouched(element)
  if element("SnapIslandToPosition"):GetInt() == 0 then
    local x = element("entryCurrentX"):GetInt()
    local y = element("entryCurrentY"):GetInt()
    local angle = include("IslandSelect").CalculateAngle(element, x, y)
    element("StartAngle"):SetFloat(angle)
    element("CurrentAngle"):SetFloat(angle)
    element("DragStartIndex"):SetInt(element("activeIndex"):GetInt())
    element("DragIsland"):SetInt(1)
    include("IslandSelect").EnableButtons(element, false)
  end
end
function IslandSelect.islandDragged(element)
  local x = element("entryCurrentX"):GetInt()
  local y = element("entryCurrentY"):GetInt()
  local angle = include("IslandSelect").CalculateAngle(element, x, y)
  element("CurrentAngle"):SetFloat(angle)
end
function IslandSelect.islandReleased(element)
  local activeEntry = element:GetElement("islandEntry" .. element("activeIndex"):GetInt())
  local x = activeEntry:position().x + activeEntry:size().x / 2
  local y = activeEntry:position().y + activeEntry:size().y / 2
  local currentAngle = include("IslandSelect").CalculateAngle(element, x, y)
  currentAngle = currentAngle - 270
  local numIslands = element("NumIslands"):GetInt()
  local degreesBetween = 360 / numIslands
  local transitionTime = math.abs(currentAngle / degreesBetween * 0.25)
  element("DragOffset"):SetFloat(currentAngle)
  element("SnapTransitionTime"):SetFloat(transitionTime)
  element("SnapIslandToPosition"):SetInt(1)
  element("DragIsland"):SetInt(0)
end
return IslandSelect
