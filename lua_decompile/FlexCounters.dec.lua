local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local FlexCounters = {}
local handleElement, keyCounterElement, relicCounterElement, starCounterElement, wildcardCounterElement
local isExpanded = false
local isVisibleOnIsland = true
local isInSpinGame = false
local function showHandle()
  handleElement.Touch("enabled"):SetInt(1)
  handleElement.BackingSprite("visible"):SetInt(1)
  handleElement.TextBox.Text("visible"):SetInt(1)
  handleElement.Icon("visible"):SetInt(1)
  handleElement.LeftArrow("visible"):SetInt(1)
  handleElement.RightArrow("visible"):SetInt(1)
end
local function hideHandle()
  handleElement.Touch("enabled"):SetInt(0)
  handleElement.BackingSprite("visible"):SetInt(0)
  handleElement.TextBox.Text("visible"):SetInt(0)
  handleElement.Icon("visible"):SetInt(0)
  handleElement.LeftArrow("visible"):SetInt(0)
  handleElement.RightArrow("visible"):SetInt(0)
end
local function updateHandle(alpha)
  handleElement.BackingSprite("alpha"):SetFloat(alpha)
  handleElement.TextBox.Text("alpha"):SetFloat(alpha)
  handleElement.Icon("alpha"):SetFloat(alpha)
  handleElement.LeftArrow("alpha"):SetFloat(alpha)
  handleElement.RightArrow("alpha"):SetFloat(1 - alpha)
end
local function shouldShowWildcardCounter()
  return game.currentIslandType() == game.IslandType_PAIRONORMAL and isVisibleOnIsland and not isInSpinGame and game.showPaironormalMinor()
end
local function shouldShowRelicCounter()
  return not isInSpinGame and (game.currentIslandType() ~= game.IslandType_PAIRONORMAL or not game.showPaironormalMinor()) and isVisibleOnIsland and game.playerLevel() >= 8
end
local function refresh(element)
  local foodCounter = element:parent():GetElement("FoodCounter")
  element("yOffset"):SetFloat(foodCounter:absY() + foodCounter:absH() + 2 * game.hudScale())
  local width = 4 * game.hudScale()
  local height = foodCounter:absH()
  local visibleCounters = 0
  if isInSpinGame or isVisibleOnIsland and game.playerLevel() >= game.minKeyGiftingLevel() then
    visibleCounters = visibleCounters + 1
    keyCounterElement("xOffset"):SetFloat(width)
    width = width + keyCounterElement:absW()
  end
  if shouldShowRelicCounter() then
    visibleCounters = visibleCounters + 1
    relicCounterElement("xOffset"):SetFloat(width)
    width = width + relicCounterElement:absW()
  end
  if shouldShowWildcardCounter() then
    visibleCounters = visibleCounters + 1
    wildcardCounterElement("xOffset"):SetFloat(width)
    width = width + wildcardCounterElement:absW()
  end
  if isInSpinGame or isVisibleOnIsland and (1 < game.numIslands() or game.playerLevel() >= 10) then
    visibleCounters = visibleCounters + 1
    starCounterElement("xOffset"):SetFloat(width)
    width = width + starCounterElement:absW()
  end
  width = width + lua_sys.deviceMarginX()
  element:setSize(lua_sys.Vector2(width, height))
  OffsetTransition.OnInit(element, {
    startX = 0,
    startY = element("yOffset"):GetFloat(),
    endX = -width,
    endY = element("yOffset"):GetFloat()
  })
  element("visibleCounters"):SetInt(visibleCounters)
  if visibleCounters > 0 then
    FlexCounters.showHUD(element)
  else
    FlexCounters.hideHUD(element)
  end
  if isInSpinGame then
    OffsetTransition.Show(element)
    isExpanded = true
    hideHandle()
  end
end
local function showKeyCounter()
  if isInSpinGame or isVisibleOnIsland and game.playerLevel() >= game.minKeyGiftingLevel() then
    keyCounterElement.BackingSprite("visible"):SetInt(1)
    keyCounterElement.Icon("visible"):SetInt(1)
    keyCounterElement.Plus("visible"):SetInt(1)
    keyCounterElement.Text("visible"):SetInt(1)
    keyCounterElement.Text("size"):SetFloat(0.25 * game.menuScaleX())
    keyCounterElement.Text("autoScale"):SetInt(1)
    keyCounterElement.TouchIcon("enabled"):SetInt(keyCounterElement("enabled"):GetInt())
  end
end
local function showRelicCounter()
  if shouldShowRelicCounter() then
    relicCounterElement.BackingSprite("visible"):SetInt(1)
    relicCounterElement.Icon("visible"):SetInt(1)
    relicCounterElement.Text("visible"):SetInt(1)
    relicCounterElement.Text("size"):SetFloat(0.25 * game.menuScaleX())
    relicCounterElement.Text("autoScale"):SetInt(1)
    relicCounterElement.Plus("visible"):SetInt(1)
    relicCounterElement.TouchIcon("enabled"):SetInt(relicCounterElement("enabled"):GetInt())
  end
end
local function showWildcardCounter()
  if shouldShowWildcardCounter() then
    wildcardCounterElement.BackingSprite("visible"):SetInt(1)
    wildcardCounterElement.Icon("visible"):SetInt(1)
    wildcardCounterElement.Text("visible"):SetInt(1)
    wildcardCounterElement.Text("size"):SetFloat(0.25 * game.menuScaleX())
    wildcardCounterElement.Text("autoScale"):SetInt(1)
    wildcardCounterElement.Touch("enabled"):SetInt(wildcardCounterElement("enabled"):GetInt())
  end
end
local function showStarCounter()
  if isInSpinGame or isVisibleOnIsland and (game.numIslands() > 1 or game.playerLevel() >= 10) then
    starCounterElement.BackingSprite("visible"):SetInt(1)
    starCounterElement.Icon("visible"):SetInt(1)
    starCounterElement.Text("visible"):SetInt(1)
    starCounterElement.Text("size"):SetFloat(0.25 * game.menuScaleX())
    starCounterElement.Text("autoScale"):SetInt(1)
    starCounterElement.TouchIcon("enabled"):SetInt(starCounterElement("enabled"):GetInt())
  end
end
local hideCounter = function(counterElement)
  counterElement.BackingSprite("visible"):SetInt(0)
  counterElement.Icon("visible"):SetInt(0)
  counterElement.Text("visible"):SetInt(0)
  local touch = counterElement.Touch
  if touch then
    touch("enabled"):SetInt(0)
  end
  local touchIcon = counterElement.TouchIcon
  if touchIcon then
    touchIcon("enabled"):SetInt(0)
  end
  local plus = counterElement.Plus
  if plus then
    plus("visible"):SetInt(0)
  end
end
local function toggleExpansion(element)
  if isExpanded then
    OffsetTransition.Hide(element)
    isExpanded = false
    handleElement.FadeTransition:Show()
  else
    showKeyCounter()
    showRelicCounter()
    showWildcardCounter()
    showStarCounter()
    refresh(element)
    OffsetTransition.Show(element)
    isExpanded = true
    handleElement.FadeTransition:Hide()
  end
  handleElement.Touch("enabled"):SetInt(0)
end
local function enableCounterButtons(counterElement)
  counterElement("enabled"):SetInt(1)
  if isVisibleOnIsland then
    local touchIcon = counterElement.TouchIcon
    if touchIcon then
      touchIcon("enabled"):SetInt(1)
    end
    local plus = counterElement.Plus
    if plus then
      plus:setColor(1, 1, 1)
    end
  end
end
local disableCounterButtons = function(counterElement)
  counterElement("enabled"):SetInt(0)
  local touchIcon = counterElement.TouchIcon
  if touchIcon then
    touchIcon("enabled"):SetInt(0)
  end
  local plus = counterElement.Plus
  if plus then
    plus:setColor(0.5, 0.5, 0.5)
  end
end
function FlexCounters.onInit(element)
  handleElement = element:GetElement("Handle")
  handleElement.FadeTransition = FadeTransition:new({onUpdate = updateHandle})
  handleElement.FadeTransition:SetAlpha(1)
  handleElement:GetComponent("Touch"):addLuaFunction("onTouchUp", function()
    lua_sys.playSoundFx("audio/sfx/starpower_button_click.wav")
    toggleExpansion(element)
  end)
  keyCounterElement = element:GetElement("KeyCounter")
  keyCounterElement("enabled"):SetInt(1)
  relicCounterElement = element:GetElement("RelicCounter")
  relicCounterElement("enabled"):SetInt(1)
  wildcardCounterElement = element:GetElement("WildcardCounter")
  wildcardCounterElement("enabled"):SetInt(1)
  starCounterElement = element:GetElement("StarCounter")
  starCounterElement("enabled"):SetInt(1)
  element("visibleCounters"):SetInt(0)
  element("invisibleOnIsland"):SetInt(isVisibleOnIsland and 0 or 1)
end
function FlexCounters.onPostInit(element)
  if game.playerLevel() < game.minKeyGiftingLevel() then
    hideCounter(keyCounterElement)
  end
  if not shouldShowRelicCounter() then
    hideCounter(relicCounterElement)
  end
  if not shouldShowWildcardCounter() then
    hideCounter(wildcardCounterElement)
  end
  if game.numIslands() <= 1 and game.playerLevel() < 10 then
    hideCounter(starCounterElement)
  end
  refresh(element)
end
function FlexCounters.onTick(element, dt)
  OffsetTransition.OnTick(element, dt, {
    ease = lua_sys.Sinusoidal_EaseInOut,
    onDoneShow = function()
      if not isInSpinGame then
        handleElement.Touch("enabled"):SetInt(1)
      end
    end,
    onDoneHide = function()
      if isInSpinGame then
        isInSpinGame = false
        FlexCounters.enableButtons(element)
        showKeyCounter()
        showRelicCounter()
        showWildcardCounter()
        showStarCounter()
        refresh(element)
      else
        handleElement.Touch("enabled"):SetInt(1)
      end
    end
  })
  handleElement.FadeTransition:Tick(dt)
end
function FlexCounters.setInvisibleOnIsland(element)
  isVisibleOnIsland = false
  element("invisibleOnIsland"):SetInt(1)
  FlexCounters.hideHUD(element)
end
function FlexCounters.showHUD(element)
  if isVisibleOnIsland and element("visibleCounters"):GetInt() > 0 then
    showHandle()
    showKeyCounter()
    if shouldShowRelicCounter() then
      showRelicCounter()
    else
      hideCounter(relicCounterElement)
    end
    if shouldShowWildcardCounter() then
      showWildcardCounter()
    else
      hideCounter(wildcardCounterElement)
    end
    showStarCounter()
  end
end
function FlexCounters.hideHUD(element)
  hideHandle()
  hideCounter(keyCounterElement)
  hideCounter(relicCounterElement)
  hideCounter(wildcardCounterElement)
  hideCounter(starCounterElement)
end
function FlexCounters.enableSpinGame(element)
  isInSpinGame = true
  FlexCounters.disableButtons(element)
  showKeyCounter()
  if shouldShowRelicCounter() then
    showRelicCounter()
  else
    hideCounter(relicCounterElement)
  end
  if shouldShowWildcardCounter() then
    showWildcardCounter()
  else
    hideCounter(wildcardCounterElement)
  end
  showStarCounter()
  refresh(element)
end
function FlexCounters.disableSpinGame(element)
  isExpanded = false
  OffsetTransition.Hide(element)
  handleElement.FadeTransition:Show()
end
function FlexCounters.enableButtons(element)
  enableCounterButtons(keyCounterElement)
  enableCounterButtons(relicCounterElement)
  enableCounterButtons(wildcardCounterElement)
  enableCounterButtons(starCounterElement)
end
function FlexCounters.disableButtons(element)
  disableCounterButtons(keyCounterElement)
  disableCounterButtons(relicCounterElement)
  disableCounterButtons(wildcardCounterElement)
  disableCounterButtons(starCounterElement)
end
return FlexCounters
