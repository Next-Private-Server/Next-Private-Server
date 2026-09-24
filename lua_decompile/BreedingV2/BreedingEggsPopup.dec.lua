local MenuHelpers = include("MenuHelpers")
local ScrollingListHelper = include("ScrollingListHelper")
local TweenerPingPong = include("TweenerPingPong")
local ShaderColorizeSimple = include("ShaderColorizeSimple")
local EGG_GLOW_MIN_ALPHA = 0.2
local EGG_GLOW_MAX_ALPHA_DELTA = 0.35
local EGG_GLOW_MIN_SIZE = 1 * BreedingMenuScaleX()
local EGG_GLOW_MAX_SIZE_DELTA = 0.1 * BreedingMenuScaleX()
local BreedingEggsPopup = {
  FadedBG = {},
  Panel = {},
  Title = {
    Text = {},
    Sprite = {}
  },
  Description = {
    Text = {}
  },
  Torches = {
    BG = {},
    Touch = {}
  },
  Eggs = {
    Swiper = {},
    Touch = {}
  }
}
function BreedingEggsPopup:onInit()
  self.tickables = {}
  ScrollingListHelper.ListInit(self.Eggs, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 5 * BreedingMenuScaleX()
  })
  self.pingPong = TweenerPingPong:new({
    loopTime = 1.6,
    ease = lua_sys.Sinusoidal_EaseInOut,
    onUpdate = function(target, t, tweener)
      target:GetVar("alpha"):SetFloat(EGG_GLOW_MIN_ALPHA + (1 - t) * EGG_GLOW_MAX_ALPHA_DELTA)
      target:GetVar("size"):SetFloat(EGG_GLOW_MIN_SIZE + t * EGG_GLOW_MAX_SIZE_DELTA)
    end
  })
  table.insert(self.tickables, self.pingPong)
  manager:setContext("BREED_SELECT")
  playSoundFx("audio/sfx/menu_slide.wav")
  function self.Panel.onDoneHide()
    self:root():popPopUp()
  end
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgPopPopUpGlobal", "gotMsgPopPopUpGlobal")
end
function BreedingEggsPopup:queuePop()
  manager:setContext("BREED_MENU_V2")
  self.Panel:Hide()
  self.FadedBG:Hide()
end
local createTooltip = function(name, parentElement, tooltipText, onDoneHide)
  local tooltip = menu:addTemplateElement("template_tooltip", name, parentElement)
  tooltip:relativeTo(parentElement)
  tooltip:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.BOTTOM))
  tooltip:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  tooltip:init()
  tooltip:setPositionBroadcast(true)
  tooltip.Text:GetVar("text"):SetString(tooltipText)
  tooltip.Sprite:setSize(lua_sys.Vector2(tooltip.Text:absW() + 8 * BreedingMenuScaleX(), tooltip.Text:absH() + 8 * BreedingMenuScaleY()))
  function tooltip.onDoneHide()
    parentElement:RemoveElement(tooltip)
    if onDoneHide then
      onDoneHide()
    end
  end
  return tooltip
end
function BreedingEggsPopup:SetupEggs(possibleResults)
  local eggsPerRow = 4
  local totalWidth = self.Eggs:absW()
  local gridCellSizeX = totalWidth / eggsPerRow
  local gridCellSizeY = gridCellSizeX
  self.eggList = {}
  for i, monsterId in ipairs(possibleResults) do
    do
      local col = (i - 1) % eggsPerRow
      local row = math.floor((i - 1) / eggsPerRow)
      local xOffset = col * gridCellSizeX + gridCellSizeX / 2
      local yOffset = row * gridCellSizeY + gridCellSizeY / 2
      local monsterData = game.getMonsterData(monsterId)
      local entryName = "entry" .. i - 1
      local egg = menu:addTemplateElement("template_breeding_spore", entryName, self.Eggs)
      egg:GetVar("listOffset"):SetFloat(yOffset)
      egg:relativeTo(self.Eggs)
      egg:setOrientation(lua_sys.MenuOrientation(xOffset, yOffset, -2, lua_sys.HCENTER, lua_sys.VCENTER))
      egg:setRelativeObjectAnchors(lua_sys.TOP, lua_sys.LEFT)
      egg:init()
      local spriteName = monsterData:spore()
      local sheetName = "xml_resources/" .. monsterData:spore() .. ".xml"
      local tooltipText = LOC(monsterData:name())
      local hasUnlockedMonster = game.hasOrHasEverHadMonsterOnActiveIsland(monsterId)
      if not hasUnlockedMonster then
        local colors = {
          common = {
            r = 1,
            g = 1,
            b = 0.75
          },
          rare = {
            r = 0.529,
            g = 0.89,
            b = 0.757
          },
          epic = {
            r = 0.984,
            g = 0.78,
            b = 0.373
          }
        }
        local raritySprite = "button_monsters"
        local rarityColor = colors.common
        if monsterData:isRareMonster() then
          tooltipText = LOC("BREEDING_LOCKED_TOOLTIP")
          raritySprite = "button_monstersrares"
          rarityColor = colors.rare
        elseif monsterData:isEpicMonster() then
          tooltipText = LOC("BREEDING_LOCKED_TOOLTIP")
          raritySprite = "button_monstersepics"
          rarityColor = colors.epic
        else
          tooltipText = LOC("BREEDING_LOCKED_TOOLTIP")
        end
        egg.Sprite:setColor(0, 0, 0)
        egg.Rarity:GetVar("visible"):SetInt(1)
        egg.Rarity:GetVar("spriteName"):SetString(raritySprite)
        local glowSprite = egg.Glow
        glowSprite:GetVar("visible"):SetInt(1)
        glowSprite:GetVar("spriteName"):SetString("white glow")
        glowSprite:GetVar("sheetName"):SetString("xml_resources/island_intro_sheet.xml")
        local imageScale = 0.055
        glowSprite:setScale(lua_sys.Vector2(6 * imageScale, 5 * imageScale))
        glowSprite:setShader(ShaderColorizeSimple)
        glowSprite:setColor(rarityColor.r, rarityColor.g, rarityColor.b)
        table.insert(self.pingPong.targets, glowSprite)
      end
      local discoveredByText = game.monsterIdDiscoveredBy(monsterId)
      if discoveredByText ~= "" then
        tooltipText = tooltipText .. [[


]] .. LOC("DISCOVERED_BY_LABEL")
        tooltipText = tooltipText:gsub("%${PLAYER_NAME}", discoveredByText)
      end
      egg.Sprite:GetVar("monsterId"):SetInt(monsterId)
      egg.Sprite:GetVar("size"):SetFloat(1 * BreedingMenuScaleX())
      egg.Sprite:GetVar("layer"):SetString("MidPopUps")
      egg.Sprite:GetVar("spriteName"):SetString(spriteName)
      egg.Sprite:GetVar("sheetName"):SetString(sheetName)
      local isAvailable = game.monsterIsAvail(monsterId, false)
      local isLimitedAvailability = game.monsterLimitedAvailability(monsterId, false)
      if not isAvailable then
        egg.Text:GetVar("visible"):SetInt(1)
        egg.Text:GetVar("text"):SetString(LOC("BREEDING_MONSTER_UNAVAILABLE"))
      elseif isLimitedAvailability then
        egg.Text:GetVar("visible"):SetInt(1)
        do
          local function updateTimerText()
            local secsRemaining = game.timedAvailMonsterTimeRemaining(monsterId)
            if secsRemaining > 0 then
              egg.Text:GetVar("text"):SetString(LOC("AVAILABLE_UNTIL") .. [[

<c=#6efa05>]] .. game.timeToString(secsRemaining) .. "</c>")
            else
              egg.Text:GetVar("visible"):SetInt(0)
            end
          end
          updateTimerText()
          local tickable = {t = 0}
          function tickable:Tick(dt)
            self.t = self.t + dt
            if self.t >= 1 then
              updateTimerText()
              self.t = 0
            end
          end
          table.insert(self.tickables, tickable)
        end
      else
        egg.Text:GetVar("visible"):SetInt(0)
      end
      egg:setPositionBroadcast(true)
      function egg.Touch.onTouchDown(component, element, x, y)
        element.dragging = 0
        if not egg.tooltip then
          egg.tooltip = createTooltip("tooltip_" .. monsterId, egg, tooltipText, function()
            egg.tooltip = nil
          end)
        end
        egg.tooltip:Show()
      end
      function egg.Touch.onTouchDrag(component, element, x, y, dx, dy)
        local dist = math.sqrt(dx * dx + dy * dy)
        element.dragging = dist
      end
      function egg.Touch.onTouchRelease(component, element)
        if egg.tooltip then
          egg.tooltip:Hide()
        end
      end
      function egg.Touch.onTouchUp(component, element, x, y)
        if egg.tooltip then
          egg.tooltip:Hide()
        end
        if element.dragging < 10 and hasUnlockedMonster then
          self:GetVar("selectedMonster"):SetInt(monsterId)
          local popup = game.pushPopUp("monster_book_info_owned")
          manager:setContext("BLANK")
        end
      end
      table.insert(self.eggList, egg)
    end
  end
  local totalHeight = math.ceil(#self.eggList / eggsPerRow) * gridCellSizeY
  self.Eggs:GetVar("numEntries"):SetInt(#self.eggList)
  self.Eggs:GetVar("totalSize"):SetFloat(totalHeight)
  self.Eggs.Swiper:DoStoredScript("refresh")
  if totalHeight < self.Eggs:absH() then
    self.Eggs.Swiper:GetVar("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeDisabled)
  end
end
function BreedingEggsPopup:Setup(possibleResults)
  self:SetupEggs(possibleResults)
  self.Eggs.Swiper:setScrollOffset(0)
end
function BreedingEggsPopup:onTick(dt)
  local egg_1 = self.Eggs:GetElement("egg_1")
  if egg_1 and egg_1.tooltip then
    local tooltip = egg_1.tooltip
    local pos = tooltip.Sprite:position()
  end
  for _, tickable in ipairs(self.tickables) do
    if tickable.Tick then
      tickable:Tick(dt)
    end
  end
  ScrollingListHelper.ListTick(self.Eggs, dt)
  self:updateEggClipping()
end
function BreedingEggsPopup:updateEggClipping()
  local clipX = self.Eggs:absX()
  local clipY = self.Description:absY() + self.Description:absH()
  local clipW = self.Eggs:absW()
  local clipH = self.Eggs:absH() + self.Eggs:absY() - clipY
  if self.eggClippingX == clipX and self.eggClippingY == clipY and self.eggClippingW == clipW and self.eggClippingH == clipH then
    return
  end
  self.eggClippingX = clipX
  self.eggClippingY = clipY
  self.eggClippingW = clipW
  self.eggClippingH = clipH
  for _, egg in ipairs(self.eggList) do
    egg:updateClipping(clipX, clipY, clipW, clipH)
  end
end
function BreedingEggsPopup.Eggs.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function BreedingEggsPopup.Eggs.Swiper:onTick(element, dt)
  ScrollingListHelper.SwiperTick(self, element, dt)
end
local createTooltip = function(name, parentElement, tooltipText, onDoneHide)
  local tooltip = menu:addTemplateElement("template_tooltip", name, parentElement)
  tooltip:relativeTo(parentElement)
  tooltip:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.BOTTOM))
  tooltip:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  tooltip:init()
  tooltip:setPositionBroadcast(true)
  tooltip.Text:GetVar("text"):SetString(tooltipText)
  tooltip.Sprite:setSize(lua_sys.Vector2(tooltip.Text:absW() + 8 * BreedingMenuScaleX(), tooltip.Text:absH() + 8 * BreedingMenuScaleY()))
  function tooltip.onDoneHide()
    parentElement:RemoveElement(tooltip)
    if onDoneHide then
      onDoneHide()
    end
  end
  return tooltip
end
function BreedingEggsPopup.Torches.Touch:onTouchDown(element)
  local torchTooltipText = LOC("BREEDING_TORCH_TOOLTIP")
  if not element.tooltip then
    element.tooltip = createTooltip("tooltip_" .. element:name(), element, torchTooltipText, function()
      element.tooltip = nil
    end)
  end
  element.tooltip:Show()
end
function BreedingEggsPopup.Torches.Touch:onTouchUp(element)
  if element.tooltip then
    element.tooltip:Hide()
  end
end
function BreedingEggsPopup.Torches.Touch:onTouchRelease(element)
  if element.tooltip then
    element.tooltip:Hide()
  end
end
function BreedingEggsPopup:gotMsgPopPopUpGlobal(msg)
  if msg.menuName == "monster_book_info_owned" then
    manager:setContext("BREED_SELECT")
  end
end
return BreedingEggsPopup
