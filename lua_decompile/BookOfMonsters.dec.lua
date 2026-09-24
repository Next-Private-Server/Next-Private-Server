local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local MenuHelpers = include("MenuHelpers")
local ColorizeShader = include("ShaderColorize")
local DesaturateShader = include("ShaderDesaturate")
local sort = include("sort")
local MonsterPortraits = include("MonsterPortraits")
local BookOfMonsters = {}
local flashSprite
local spotlightMonsterId = 0
local spotlightCostumeId = 0
local spotlightMonsterEntry
local spotlightWait = 0
local spotlightDepth = 0
local spotlightState = 0
local oldCamPosX = 0
local oldCamPosY = 0
local oldScale = 0
local oldRarity = -1
local touchEnableDelay = -1
local e_MonsterList, e_Layout, c_Camera
local DEVICE_MARGIN_X = lua_sys.deviceMarginX()
local DEVICE_MARGIN_Y = lua_sys.deviceMarginY()
local MARGIN_TOP = 50 * game.hudScale() + 20 * game.menuScaleX()
local MARGIN_BOTTOM = 50 * game.menuScaleY() + 35 * game.menuScaleY() + DEVICE_MARGIN_Y
local MARGIN_LEFT = 30 * game.menuScaleX() + DEVICE_MARGIN_X
local MARGIN_RIGHT = 30 * game.menuScaleX() + DEVICE_MARGIN_X
local SPACE_X = lua_sys.screenWidth() - MARGIN_LEFT - MARGIN_RIGHT
local SPACE_Y = lua_sys.screenHeight() - MARGIN_TOP - MARGIN_BOTTOM
local COLLAGE_Y_OFFSET = -(MARGIN_BOTTOM * 0.5) + MARGIN_TOP * 0.5
local calculatedOriginalScale = 1
local filterButtons = {
  "MonsterSingleGeneFilter",
  "MonsterDoubleGeneFilter",
  "MonsterTripleGeneFilter",
  "MonsterQuadGeneFilter",
  "MonsterFiveGeneFilter",
  "MonsterSpecialFilter"
}
local bookPositions = {}
local monsterIdsByRarity
local monsterRarities = {
  {
    rarity = game.COMMON,
    icon = "map_common_icon",
    elementName = "Common",
    label = "COMMONS_LABEL",
    color = {
      1,
      1,
      1
    },
    pageAnim = "common"
  },
  {
    rarity = game.RARE,
    icon = "map_rare_icon",
    elementName = "Rare",
    label = "RARES_LABEL",
    color = {
      0.529,
      0.89,
      0.757
    },
    pageAnim = "rare"
  },
  {
    rarity = game.EPIC,
    icon = "map_epic_icon",
    elementName = "Epic",
    label = "EPICS_LABEL",
    color = {
      0.984,
      0.78,
      0.373
    },
    pageAnim = "epic"
  }
}
if game.getBookOfMonstersIslandType() == game.IslandType_CELESTIAL then
  monsterRarities[1].label = "YOUTH_LABEL"
  monsterRarities[1].icon = "map_celestial_icon"
  monsterRarities[1].color = {
    1,
    1,
    1
  }
  monsterRarities[2].label = "ADULT_LABEL"
  monsterRarities[2].icon = "map_ascension_icon"
  monsterRarities[2].color = {
    1,
    1,
    1
  }
  monsterRarities[3].label = "ELDER_LABEL"
  monsterRarities[3].icon = "map_ascension_icon"
  monsterRarities[3].color = {
    1,
    1,
    1
  }
end
local isSeasonalIsland = game.getBookOfMonstersIslandType() == game.IslandType_SEASONAL
monsterRarities[1].available = 0 < game.getAllUniqueCommonsForIslandType(game.getBookOfMonstersIslandType(), game.getBookOfMonstersIslandMode(), isSeasonalIsland)
monsterRarities[2].available = 0 < game.getAllUniqueRaresForIslandType(game.getBookOfMonstersIslandType(), game.getBookOfMonstersIslandMode(), isSeasonalIsland)
monsterRarities[3].available = 0 < game.getAllUniqueEpicsForIslandType(game.getBookOfMonstersIslandType(), game.getBookOfMonstersIslandMode(), isSeasonalIsland)
local spotlightFader = FadeTransition:new({
  duration = 2,
  maxFade = 1,
  onDoneShow = function(f)
    f:Hide()
    spotlightState = 1
  end,
  onDoneHide = function(e)
    spotlightMonsterEntry:E("CharacterImage"):C("Sprite"):setShader(nil)
    spotlightMonsterEntry:E("Silhouette"):C("Sprite"):setShader(nil)
    spotlightMonsterEntry:DoStoredScript("Refresh")
  end,
  onUpdate = function(alpha)
    local scale = (1 - spotlightState) * (1.33 + 0.17 * alpha) + spotlightState * (1 + 0.5 * alpha)
    spotlightMonsterEntry:E("CharacterImage"):C("Sprite"):setScale(lua_sys.Vector2(scale, scale))
    spotlightMonsterEntry:E("Silhouette"):C("Sprite"):setScale(lua_sys.Vector2(scale, scale))
    if ColorizeShader then
      ColorizeShader:getUniform("u_Factor"):setFloat(alpha)
    end
  end
})
local function bookPos(rarity, monsterId)
  local rarityPage = bookPositions[rarity]
  if rarityPage ~= nil then
    local val = rarityPage[monsterId]
    if val ~= nil then
      return val
    end
  end
  return lua_sys.Vector4(0, 0, 0, 0)
end
function UpdateCounters(element, offset)
  local curr, total, target
  local isSeasonalIsland = game.getBookOfMonstersIslandType() == game.IslandType_SEASONAL
  local islandMode = game.getBookOfMonstersIslandMode()
  local monsterData = game.getMonsterData(spotlightMonsterId)
  if monsterData:isSeasonal() and not isSeasonalIsland then
    curr = game.numUniqueSeasonalsCollectedOnBookOfMonstersIsland(true, currentRarity) + offset
    total = game.getAllUniqueSeasonalsForIslandType(game.getBookOfMonstersIslandType(), islandMode, true, currentRarity)
    target = element:E("CollectedSeasonals")
  elseif game.getBookOfMonstersIslandType() ~= game.IslandType_CELESTIAL then
    if monsterData:isEpicMonster() then
      curr = game.numUniqueEpicsCollectedOnBookOfMonstersIsland(isSeasonalIsland) + offset
      total = game.getAllUniqueEpicsForIslandType(game.getBookOfMonstersIslandType(), islandMode, isSeasonalIsland)
      target = element:E("CollectedEpics")
    elseif monsterData:isRareMonster() then
      curr = game.numUniqueRaresCollectedOnBookOfMonstersIsland(isSeasonalIsland) + offset
      total = game.getAllUniqueRaresForIslandType(game.getBookOfMonstersIslandType(), islandMode, isSeasonalIsland)
      target = element:E("CollectedRares")
    else
      curr = game.numUniqueCommonsCollectedOnBookOfMonstersIsland(isSeasonalIsland) + offset
      total = game.getAllUniqueCommonsForIslandType(game.getBookOfMonstersIslandType(), islandMode, isSeasonalIsland)
      target = element:E("CollectedCommons")
    end
  elseif monsterData:isElder() then
    curr = game.numUniqueEpicsCollectedOnBookOfMonstersIsland(isSeasonalIsland) + offset
    total = game.getAllUniqueEpicsForIslandType(game.getBookOfMonstersIslandType(), islandMode, isSeasonalIsland)
    target = element:E("CollectedEpics")
  elseif monsterData:isAdult() then
    curr = game.numUniqueRaresCollectedOnBookOfMonstersIsland(isSeasonalIsland) + offset
    total = game.getAllUniqueRaresForIslandType(game.getBookOfMonstersIslandType(), islandMode, isSeasonalIsland)
    target = element:E("CollectedRares")
  else
    curr = game.numUniqueCommonsCollectedOnBookOfMonstersIsland(isSeasonalIsland) + offset
    total = game.getAllUniqueCommonsForIslandType(game.getBookOfMonstersIslandType(), islandMode, isSeasonalIsland)
    target = element:E("CollectedCommons")
  end
  target:C("Text")("text"):SetString(curr .. "/" .. total)
  local x = target:absX() + target:absW() * 0.5
  local y = target:absY() + target:absH() * 0.5
  game.playParticle("particles/particle_diamond_get.psi", "gfx/particles/particle_star", x, y, "ContextBar", 0.001, 1, 1)
end
local function onInitMonsterList(element)
  local bookAnim = game.getBookOfMonstersAnim(game.getBookOfMonstersIslandType())
  e_Layout("animationName"):SetString("xml_bin/" .. bookAnim)
  local animUtil = game.AnimUtil(e_Layout)
  usePagination = not animUtil:hasAnimation("all")
  monsterFilter = game.getBookOfMonstersFilter()
  game.setBookOfMonstersFilter(game.NO_MONSTER_FILTER)
  currentRarity = game.getBookOfMonstersRarityFilter()
  game.setBookOfMonstersRarityFilter(game.COMMON)
  pageNum = currentRarity + 1
  currentRarityIndex = pageNum
  game.setBookIslandCount()
  monsterIdsByRarity = game.getAllMonstersForBookOfMonstersIslandByRarity()
  spotlightMonsterId = game.getSpotlightMonsterId()
  if usePagination and spotlightMonsterId > 0 then
    local newRarity = game.getSpotlightMonsterRarity(spotlightMonsterId)
    if newRarity ~= currentRarity then
      currentRarity = newRarity
      pageNum = currentRarity + 1
      currentRarityIndex = pageNum
    end
  end
  local targetMode = game.getBookOfMonstersIslandMode()
  local minY = 99999
  local maxY = -99999
  local minX = 99999
  local maxX = -99999
  local numMonsters = 0
  for k, v in ipairs(monsterRarities) do
    local rarity = v.rarity
    if monsterIdsByRarity:has_key(rarity) then
      local animName = v.pageAnim
      local pageRarity = rarity
      if not usePagination then
        animName = "all"
        pageRarity = 0
      end
      if bookPositions[pageRarity] == nil then
        bookPositions[pageRarity] = {}
      end
      e_Layout("animation"):SetString(animName)
      local monsterIds = monsterIdsByRarity:get(rarity)
      for i = 0, monsterIds:size() - 1 do
        local monsterId = monsterIds[i]
        local layerName = MonsterPortraits:getBookOfMonstersPortraitName(monsterId, targetMode) .. ".png"
        local pos = lua_sys.Vector4(0, 0, 0, 0)
        if layerName ~= nil and animUtil:hasLayer(layerName) then
          local layerPos = animUtil:getPos(layerName)
          local layerSize = animUtil:getSize(layerName)
          local layerScale = animUtil:getScale(layerName)
          local layerIndex = animUtil:getIndex(layerName)
          pos.x = layerPos.x + layerSize.x * 0.5
          pos.y = layerPos.y + layerSize.y * 0.5
          pos.z = layerIndex
          pos.w = 0 < layerScale.x and 0 or 1
          bookPositions[pageRarity][monsterId] = pos
          local monsterEntry = menu:addTemplateElement("template_book_o_monsters_entry", "monsterEntry" .. numMonsters, element)
          monsterEntry:V("List"):SetString("MonsterList")
          monsterEntry.MonsterID = monsterIds[i]
          monsterEntry.MonsterRarity = rarity
          monsterEntry.FilteredOut = false
          monsterEntry:V("MonsterFlip"):SetInt(pos.w)
          monsterEntry:setParent(element)
          monsterEntry:relativeTo(element)
          monsterEntry:setOrientation(lua_sys.MenuOrientation(pos.x, pos.y, pos.z * 2, lua_sys.HCENTER, lua_sys.VCENTER))
          monsterEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
          monsterEntry:setPositionBroadcast(false)
          monsterEntry:init()
          if usePagination and rarity ~= currentRarity then
            monsterEntry.visible = true
          end
          local curWidth = monsterEntry:E("CharacterImage"):C("Sprite"):absW() / 2
          local curHeight = monsterEntry:E("CharacterImage"):C("Sprite"):absH() / 2
          if minX > pos.x - curWidth then
            minX = pos.x - curWidth
          end
          if maxX < pos.x + curWidth then
            maxX = pos.x + curWidth
          end
          if minY > pos.y - curHeight then
            minY = pos.y - curHeight
          end
          if maxY < pos.y + curHeight then
            maxY = pos.y + curHeight
          end
          numMonsters = numMonsters + 1
        else
          print("***** BOM MISSING LAYER '" .. layerName .. "' FOR MONSTER " .. monsterId .. " *****")
        end
      end
    end
  end
  local scaleWidth = SPACE_X / (maxX * 2)
  local scaleHeight = SPACE_Y / (maxY * 2)
  calculatedOriginalScale = scaleWidth
  if scaleWidth > scaleHeight then
    calculatedOriginalScale = scaleHeight
  end
  element:setPositionBroadcast(true)
  element("NumMonsters"):SetInt(numMonsters)
end
local isSpecial = function(monsterData)
  if monsterData:hasKeyword("special") then
    if monsterData:isRareMonster() or monsterData:isEpicMonster() then
      local commonMonsterId = game.commonMonster(monsterData:monsterId())
      if commonMonsterId > 0 then
        local commonMonsterData = game.getMonsterData(commonMonsterId)
        if commonMonsterData and commonMonsterData:hasKeyword("special") then
          return true
        end
      else
        print("no common monster does this make sense?")
      end
    else
      return true
    end
  end
  return false
end
local function isInFilter(fliter, monsterId)
  local monsterData = game.getMonsterData(monsterId)
  if not monsterData then
    return false
  end
  local genes = monsterData:unsortedGenes()
  local numGenes = #genes
  if fliter == game.SPECIAL_FILTER then
    return isSpecial(monsterData)
  elseif fliter == game.ONE_GENE_FILTER then
    return numGenes == 1 or monsterData:isSeasonal() or monsterData:isPrimordial()
  elseif fliter == game.TWO_GENE_FILTER then
    return numGenes == 2
  elseif fliter == game.THREE_GENE_FILTER then
    return numGenes == 3
  elseif fliter == game.FOUR_GENE_FILTER then
    return numGenes == 4
  elseif fliter == game.FIVE_GENE_FILTER then
    return numGenes == 5
  end
  return true
end
local function hasMonsterInFilter(element, filter)
  local numMonsters = element("NumMonsters"):GetInt()
  for i = 0, numMonsters - 1 do
    local monster = element:E("monsterEntry" .. i)
    if (not usePagination or monster.MonsterRarity == currentRarity) and isInFilter(filter, monster.MonsterID) then
      return true
    end
  end
  return false
end
local function updateFilters(element)
  local buttons = {}
  if game.getBookOfMonstersIslandType() == game.IslandType_ETHEREAL then
    filterButtons = {
      "MonsterSingleGeneFilter",
      "MonsterDoubleGeneFilter",
      "MonsterTripleGeneFilter",
      "MonsterQuadGeneFilter",
      "MonsterFiveGeneFilter"
    }
    element:parent():E("MonsterSpecialFilter"):setInvisible()
  end
  for i = 1, #filterButtons do
    local filterElement = element:parent():E(filterButtons[i])
    if #filterButtons > 0 then
      table.insert(buttons, MenuHelpers.CreateSpacer(-1 * game.menuScaleX()))
    end
    if hasMonsterInFilter(element, tonumber(filterElement.filterName)) and game.getBookOfMonstersIslandType() ~= game.IslandType_CELESTIAL and game.getBookOfMonstersIslandType() ~= game.IslandType_SEASONAL and game.getBookOfMonstersIslandType() ~= game.IslandType_UNDERLING then
      filterElement:setVisible()
      table.insert(buttons, filterElement)
    else
      filterElement:setInvisible()
    end
  end
  include("MenuHelpers").CenterHorizontally(buttons)
end
local function onPostInitMonsterList(element)
  if hasMonsterInFilter(element, monsterFilter) == false then
    monsterFilter = game.NO_MONSTER_FILTER
    for i = 1, #filterButtons do
      element:parent():E(filterButtons[i]):DoStoredScript("deselect")
    end
  end
  for i = 1, #filterButtons do
    local element = element:parent():E(filterButtons[i])
    if tonumber(element.filterName) == monsterFilter then
      element:DoStoredScript("select")
    end
  end
  BookOfMonsters.RefreshPage(element)
  updateFilters(element)
  local islandType = game.getBookOfMonstersIslandType()
  local islandMode = game.getBookOfMonstersIslandMode()
  local isSeasonalIsland = false
  if islandType == game.IslandType_SEASONAL then
    isSeasonalIsland = true
  end
  local curr = game.numUniqueCommonsCollectedOnBookOfMonstersIsland(isSeasonalIsland)
  local total = game.getAllUniqueCommonsForIslandType(islandType, islandMode, isSeasonalIsland)
  element:parent():E("Collected"):E("CollectedCommons"):C("Text"):V("text"):SetString(curr .. "/" .. total)
  curr = game.numUniqueRaresCollectedOnBookOfMonstersIsland(isSeasonalIsland)
  total = game.getAllUniqueRaresForIslandType(islandType, islandMode, isSeasonalIsland)
  element:parent():E("Collected"):E("CollectedRares"):C("Text"):V("text"):SetString(curr .. "/" .. total)
  curr = game.numUniqueEpicsCollectedOnBookOfMonstersIsland(isSeasonalIsland)
  total = game.getAllUniqueEpicsForIslandType(islandType, islandMode, isSeasonalIsland)
  element:parent():E("Collected"):E("CollectedEpics"):C("Text"):V("text"):SetString(curr .. "/" .. total)
  for k, v in ipairs(monsterRarities) do
    local e = element:parent().Collected["Collected" .. monsterRarities[k].elementName .. "s"]
    e:C("Text"):setColor(v.color[1], v.color[2], v.color[3])
    e:C("Sprite"):V("spriteName"):SetString(v.icon)
  end
  if game.showSeasonalCount() then
    element:parent().CollectedSeasonals:Show()
  else
    element:parent().CollectedSeasonals:Hide()
  end
  if game.getAllUniqueCostumesForIslandType(islandType, islandMode, false) > 0 and islandType ~= game.IslandType_GOLD then
    element:parent().CollectedCostumes:Show()
  else
    element:parent().CollectedCostumes:Hide()
  end
  BookOfMonsters.UpdateRarityInfo(element, currentRarityIndex)
end
local function updateCamera(component, element)
  local scale = component:zoom()
  component:GetVar("dragFactor"):SetFloat(scale)
  local collageScreen = math.max(scale / calculatedOriginalScale - 1, 0)
  component:setCameraBounds(-(collageScreen * SPACE_X * 0.5), -(collageScreen * SPACE_Y * 0.5), collageScreen * SPACE_X * 0.5, collageScreen * SPACE_Y * 0.5)
  local camPosX = component:posX()
  local camPosY = component:posY()
  if oldCamPosX ~= camPosX or oldCamPosY ~= camPosY or oldScale ~= scale or oldRarity ~= currentRarity then
    local numMonsters = element("NumMonsters"):GetInt()
    for i = 0, numMonsters - 1 do
      local monster = element:E("monsterEntry" .. i)
      if monster and monster.visible then
        monster.CharacterImage.Sprite("size"):SetFloat(scale)
        monster.Silhouette.Sprite("size"):SetFloat(scale)
        local pos = bookPos(currentRarity, monster.MonsterID)
        monster:setOrientationPosition(lua_sys.Vector2(pos.x * scale - camPosX, pos.y * scale + COLLAGE_Y_OFFSET - camPosY))
      end
    end
    oldCamPosX = camPosX
    oldCamPosY = camPosY
    oldScale = scale
    oldRarity = currentRarity
  end
end
local function onTickCamera(component, element, dt)
  updateCamera(component, element)
end
local function onInitCamera(component, element)
  component:setZoom(calculatedOriginalScale)
  component:setMinZoom(calculatedOriginalScale)
  component:setMaxZoom(calculatedOriginalScale * 2)
  component:GetVar("allowBounce"):SetInt(1)
  component:GetVar("dragFactor"):SetFloat(calculatedOriginalScale)
  oldScale = calculatedOriginalScale
end
local onPostInitCamera = function(component, element)
  component:listenToTouches(element)
end
local function initializeChildren(element)
  e_MonsterList = element:E("MonsterList")
  e_Layout = e_MonsterList:C("Layout")
  c_Camera = e_MonsterList:C("Camera")
  e_MonsterList:addLuaFunction("onInit", onInitMonsterList)
  e_MonsterList:addLuaFunction("onPostInit", onPostInitMonsterList)
  c_Camera:addLuaFunction("onInit", onInitCamera)
  c_Camera:addLuaFunction("onPostInit", onPostInitCamera)
  c_Camera:addLuaFunction("onTick", onTickCamera)
end
function BookOfMonsters.onInit(element)
  game.setTouchEnable(false)
  if DesaturateShader then
    DesaturateShader:getUniform("blackIntensity"):setFloat(0)
  end
  initializeChildren(element)
  element("FromWorld"):SetInt(0)
  element("SpotlightMonster"):SetInt(0)
  element("SpotlightCostume"):SetInt(0)
  element("SpotlightStartX"):SetFloat(0)
  element("SpotlightStartY"):SetFloat(0)
  flashSprite = element:C("flash")
  flashSprite.FadeTransition = FadeTransition:new({
    duration = 0.33,
    maxFade = 1,
    onDoneShow = function()
      if DesaturateShader then
        DesaturateShader:getUniform("blackIntensity"):setFloat(0)
      end
      game.showHUD()
      element:root():popPopUp()
      local monsterData = game.getMonsterData(spotlightMonsterId)
      if element("WasFugued"):GetInt() == 1 then
        local fugue = game.FindFugue()
        if fugue then
          fugue:finishFuguing()
        end
      elseif element("isCrucibleEvolve"):GetInt() == 0 then
        if not monsterData:isDipster() and (not monsterData:isBoxMonster() or not not game.isAmberIsland()) and not monsterData:isTitansoul() and not game.isUnderlingIsland() and not game.isCelestialIsland() and not game.onGoldIsland() then
          game.showHatchPopup(spotlightMonsterId, spotlightCostumeId)
          manager:setContext(game.getEggHoldingContext())
        else
          manager:setContext(manager:getDefaultContext())
          if game.currentIsland() == game.IslandType_UNDERLING then
            local polarityAmplifier = game.getPolarityAmplifier()
            if polarityAmplifier ~= nil and polarityAmplifier:canLevelUp() then
              include("PolarityAmplifierCutscene").PlayUpgrade()
            end
          end
        end
      else
        game.showEvolvePopup(spotlightMonsterId, spotlightCostumeId)
        manager:setContext(manager:getDefaultContext())
      end
    end,
    onUpdate = function(alpha)
      flashSprite:GetVar("alpha"):SetFloat(alpha)
    end
  })
end
function BookOfMonsters.onPostInit(element)
  touchEnableDelay = 0.066
end
function BookOfMonsters.onTick(element, dt)
  dt = math.min(dt, 0.033)
  if touchEnableDelay > -1 then
    touchEnableDelay = touchEnableDelay - dt
    if touchEnableDelay < 0 then
      touchEnableDelay = -1
      game.setTouchEnable(true)
    end
  end
  if 0 < element("SpotlightMonster"):GetInt() and not spotlightMonsterEntry then
    element.BackButton.Overlay("visible"):SetInt(0)
    element.BackButton:DoStoredScript("setInvisible")
    element.IslandSelectButton.Overlay("visible"):SetInt(0)
    element.IslandSelectButton:DoStoredScript("setInvisible")
    element.PreviousButton:DoStoredScript("hide")
    element.NextButton:DoStoredScript("hide")
    element.MonsterTripleGeneFilter:DoStoredScript("setInvisible")
    element.MonsterDoubleGeneFilter:DoStoredScript("setInvisible")
    element.MonsterQuadGeneFilter:DoStoredScript("setInvisible")
    element.MonsterSingleGeneFilter:DoStoredScript("setInvisible")
    element.MonsterFiveGeneFilter:DoStoredScript("setInvisible")
    element.MonsterSpecialFilter:DoStoredScript("setInvisible")
    element.MonsterList.Touch("enabled"):SetInt(0)
    element.MonsterList.Camera("enabled"):SetInt(0)
    spotlightMonsterId = element("SpotlightMonster"):GetInt()
    local spotlightMonsterData = game.getMonsterData(spotlightMonsterId)
    if spotlightMonsterData:isModal() then
      local islandMode = game.getBookOfMonstersIslandMode()
      print("Found modal monster (", spotlightMonsterId, "), getting the mode monster for mode: ", islandMode)
      local modeMonster = game.getModalMonsterData(spotlightMonsterData, islandMode)
      spotlightMonsterId = modeMonster:monsterId()
    end
    spotlightCostumeId = element("SpotlightCostume"):GetInt()
    UpdateCounters(element, -1)
    MenuHelpers.ForEachEntry(element:E("MonsterList"), function(entry)
      local characterImage = entry:E("CharacterImage"):C("Sprite")
      characterImage:V("enabled"):SetInt(0)
      local silhouetteImage = entry:E("Silhouette"):C("Sprite")
      silhouetteImage:V("enabled"):SetInt(0)
      if entry.MonsterID == spotlightMonsterId then
        spotlightMonsterEntry = entry
        entry.pulsing = 0
        if ColorizeShader then
          ColorizeShader:getUniform("u_Factor"):setFloat(1)
        end
        characterImage:setShader(ColorizeShader)
        silhouetteImage:setShader(ColorizeShader)
        spotlightFader:SetAlpha(1)
        spotlightFader:Hide()
        spotlightState = 1
        local monsterList = element:E("MonsterList")
        local startX = element:V("SpotlightStartX"):GetFloat() - monsterList:absX()
        local startY = element:V("SpotlightStartY"):GetFloat() - monsterList:absY()
        OffsetTransition.OnInit(entry, {
          duration = 3,
          startX = startX,
          startY = startY,
          endX = entry:V("xOffset"):GetFloat(),
          endY = entry:V("yOffset"):GetFloat()
        })
        entry:V("xOffset"):SetFloat(startX)
        entry:V("yOffset"):SetFloat(startY)
        spotlightDepth = entry:orientationPriority()
        entry:setOrientationPriority(0)
        OffsetTransition.Show(entry)
      end
    end, {
      entryName = "monsterEntry"
    })
  end
  if spotlightMonsterEntry then
    OffsetTransition.OnTick(spotlightMonsterEntry, dt, {
      onDoneShow = function(e)
        UpdateCounters(element, 0)
        local sprite = spotlightMonsterEntry:E("CharacterImage"):C("Sprite")
        local spriteSize = math.max(sprite:V("width"):GetInt(), sprite:V("height"):GetInt())
        local effectScale = spriteSize / 10 * calculatedOriginalScale
        game.playEffect("particles/FX_BookOfMonsters_AddMonster.efkefc", spotlightMonsterEntry:absX() + spotlightMonsterEntry:absW() / 2, spotlightMonsterEntry:absY() + spotlightMonsterEntry:absH() / 2, sprite("layer"):GetString(), 0.001, effectScale)
        spotlightWait = 3
        spotlightMonsterEntry:setOrientationPriority(spotlightDepth)
        game.setSpotlightMonsterId(-1)
      end
    })
    spotlightFader:Tick(dt)
  end
  if spotlightWait > 0 then
    spotlightWait = spotlightWait - dt
    if spotlightWait <= 0 then
      flashSprite.FadeTransition:Show()
      flashSprite("visible"):SetInt(1)
    end
  end
  if element.flash("visible"):GetInt() == 1 then
    flashSprite.FadeTransition:Tick(dt)
  end
end
function BookOfMonsters.queuePop(element)
  if touchEnableDelay > 0 then
    game.setTouchEnable(true)
  end
  element:root():popPopUp()
  if game.mapVersion() == 2 then
    manager:setContext(manager:getDefaultContext())
  elseif element("FromWorld"):GetInt() == 1 then
    manager:setContext(manager:getDefaultContext())
  elseif game.getPopUp() ~= "island_select" then
    manager:setContext("ISLAND_MAP")
    if game.getPopUp() ~= "island_select" then
      game.pushPopUp("island_select")
    end
  end
end
function BookOfMonsters.PreviousPage(component, element)
  if currentRarityIndex > 1 then
    pageNum = pageNum - 1
    currentRarityIndex = currentRarityIndex - 1
    currentRarity = monsterRarities[currentRarityIndex].rarity
    local monsterList = element:parent():E("MonsterList")
    if hasMonsterInFilter(monsterList, monsterFilter) == false then
      monsterFilter = game.NO_MONSTER_FILTER
      for i = 1, #filterButtons do
        monsterList:parent():E(filterButtons[i]):DoStoredScript("deselect")
      end
    end
    BookOfMonsters.RefreshPage(element)
    BookOfMonsters.UpdateRarityInfo(element, currentRarityIndex)
    updateFilters(monsterList)
    lua_sys.playSoundFx("audio/sfx/menu_click.wav")
  end
end
function BookOfMonsters.NextPage(component, element)
  if currentRarityIndex < #monsterRarities then
    pageNum = pageNum + 1
    currentRarityIndex = currentRarityIndex + 1
    currentRarity = monsterRarities[currentRarityIndex].rarity
    BookOfMonsters.UpdateRarityInfo(element, currentRarityIndex)
    local monsterList = element:parent():E("MonsterList")
    if hasMonsterInFilter(monsterList, monsterFilter) == false then
      monsterFilter = game.NO_MONSTER_FILTER
      for i = 1, #filterButtons do
        monsterList:parent():E(filterButtons[i]):DoStoredScript("deselect")
      end
    end
    BookOfMonsters.RefreshPage(element)
    updateFilters(monsterList)
    lua_sys.playSoundFx("audio/sfx/menu_click.wav")
  end
end
local function priorityCompare(m1, m2)
  local pos1 = bookPos(currentRarity, m1.MonsterID)
  local pos2 = bookPos(currentRarity, m2.MonsterID)
  return pos1.z < pos2.z
end
function BookOfMonsters.RefreshPage(element)
  if usePagination then
    element:parent().IslandName.Text("text"):SetString(game.getLocalizedText(game.islandName(game.getBookOfMonstersIslandType())) .. " - " .. game.getLocalizedText(monsterRarities[currentRarityIndex].label))
  else
    element:parent().IslandName.Text("text"):SetString(game.getLocalizedText(game.islandName(game.getBookOfMonstersIslandType())))
  end
  local filteredOutMonsters = {}
  local filteredInMonsters = {}
  MenuHelpers.ForEachEntry(element:parent():E("MonsterList"), function(entry)
    local characterImage = entry:E("CharacterImage"):C("Sprite")
    local silhouetteImage = entry:E("Silhouette"):C("Sprite")
    if usePagination and entry.MonsterRarity ~= currentRarity then
      entry.visible = false
      characterImage:V("enabled"):SetInt(0)
      silhouetteImage:V("enabled"):SetInt(0)
    else
      entry.visible = true
      characterImage:V("enabled"):SetInt(1)
      silhouetteImage:V("enabled"):SetInt(1)
      if isInFilter(monsterFilter, entry.MonsterID) then
        entry.FilteredOut = false
        characterImage:V("alpha"):SetFloat(1)
        silhouetteImage:V("alpha"):SetFloat(1)
        table.insert(filteredInMonsters, entry)
      else
        entry.FilteredOut = true
        characterImage:V("alpha"):SetFloat(0.25)
        silhouetteImage:V("alpha"):SetFloat(0.25)
        table.insert(filteredOutMonsters, entry)
      end
    end
    entry:Refresh()
  end, {
    entryName = "monsterEntry"
  })
  sort.stable_sort(filteredOutMonsters, priorityCompare)
  sort.stable_sort(filteredInMonsters, priorityCompare)
  local priority = 1
  for i = 1, #filteredInMonsters do
    filteredInMonsters[i]:setOrientationPriority(priority * 2)
    priority = priority + 1
  end
  for i = 1, #filteredOutMonsters do
    filteredOutMonsters[i]:setOrientationPriority(priority * 2)
    priority = priority + 1
  end
  if usePagination then
    if pageNum == #monsterRarities or not monsterRarities[currentRarityIndex + 1].available then
      element:parent().NextButton:DoStoredScript("hide")
    else
      element:parent().NextButton:DoStoredScript("show")
      element:parent().NextButton.Rarity("spriteName"):SetString(monsterRarities[currentRarityIndex + 1].icon)
    end
    if pageNum == 1 then
      element:parent().PreviousButton:DoStoredScript("hide")
    else
      element:parent().PreviousButton:DoStoredScript("show")
      element:parent().PreviousButton.Rarity("spriteName"):SetString(monsterRarities[currentRarityIndex - 1].icon)
    end
  else
    element:parent().NextButton:DoStoredScript("hide")
    element:parent().PreviousButton:DoStoredScript("hide")
  end
  local islandType = game.getBookOfMonstersIslandType()
  local islandMode = game.getBookOfMonstersIslandMode()
  curr = game.numUniqueSeasonalsCollectedOnBookOfMonstersIsland(usePagination, currentRarity)
  total = game.getAllUniqueSeasonalsForIslandType(islandType, islandMode, usePagination, currentRarity)
  element:parent().CollectedSeasonals.Text("text"):SetString(curr .. "/" .. total)
  curr = game.numUniqueCostumesCollectedOnBookOfMonstersIsland(usePagination, currentRarity)
  total = game.getAllUniqueCostumesForIslandType(islandType, islandMode, false, usePagination, currentRarity)
  element:parent().CollectedCostumes.Text("text"):SetString(curr .. "/" .. total)
  element:parent().CollectedLayoutHelper:Refresh()
  updateCamera(c_Camera, e_MonsterList)
end
function BookOfMonsters.UpdateRarityInfo(element, index)
  for k, v in ipairs(monsterRarities) do
    if not usePagination and monsterRarities[k].available or k == index then
      element:parent().Collected["Collected" .. monsterRarities[k].elementName .. "s"]:Show()
    else
      element:parent().Collected["Collected" .. monsterRarities[k].elementName .. "s"]:Hide()
    end
  end
  element:parent().CollectedLayoutHelper:Refresh()
end
function BookOfMonsters.onMonsterFilterSelected(element, buttonElement, filterName)
  if monsterFilter == tonumber(filterName) then
    monsterFilter = game.NO_MONSTER_FILTER
    buttonElement:DoStoredScript("deselect")
  else
    monsterFilter = tonumber(filterName)
    for i = 1, #filterButtons do
      element:E(filterButtons[i]):DoStoredScript("deselect")
    end
    buttonElement:DoStoredScript("select")
  end
  BookOfMonsters.RefreshPage(element)
end
function BookOfMonsters.DoPageButtonEffect(element, dt)
  local buttonState = element("ButtonState"):GetInt()
  if buttonState ~= game.BUTTON_IDLE then
    local buttonSize = 0.4 * game.menuScaleX()
    local arrowSize = 0.5 * game.menuScaleX()
    local backingWidth = 55 * game.menuScaleX()
    local backingHeight = 45 * game.menuScaleY()
    local newTime = element("TickTimer"):GetFloat() + dt
    element("TickTimer"):SetFloat(newTime)
    if buttonState == game.BUTTON_PRESSED then
      local smoothedButtonSize = lua_sys.smooth(buttonSize, buttonSize - 0.03, newTime * 15)
      local smoothedArrowSize = lua_sys.smooth(arrowSize, arrowSize - 0.03, newTime * 15)
      element.Arrow("size"):SetFloat(smoothedArrowSize)
      element.Rarity("size"):SetFloat(smoothedButtonSize)
      local width = lua_sys.smooth(backingWidth, backingWidth * 0.97, newTime * 15)
      local height = lua_sys.smooth(backingHeight, backingHeight * 0.97, newTime * 15)
      element.BackingSprite("width"):SetInt(width)
      element.BackingSprite("height"):SetInt(height)
      if smoothedButtonSize == buttonSize - 0.03 then
        element("ButtonState"):SetInt(game.BUTTON_IDLE)
      end
    elseif buttonState == game.BUTTON_RELEASED then
      if newTime < 0.1 then
        local smoothedButtonSize = lua_sys.smooth(buttonSize - 0.03, buttonSize + 0.05, newTime * 20)
        local smoothedArrowSize = lua_sys.smooth(arrowSize - 0.03, arrowSize + 0.05, newTime * 20)
        element.Arrow("size"):SetFloat(smoothedArrowSize)
        element.Rarity("size"):SetFloat(smoothedButtonSize)
        local width = lua_sys.smooth(backingWidth * 0.97, backingWidth * 1.05, newTime * 20)
        local height = lua_sys.smooth(backingHeight * 0.97, backingHeight * 1.05, newTime * 20)
        element.BackingSprite("width"):SetInt(width)
        element.BackingSprite("height"):SetInt(height)
      elseif newTime < 0.3 then
        local smoothedButtonSize = lua_sys.smooth(buttonSize + 0.05, buttonSize, (newTime - 0.1) * 20)
        local smoothedArrowSize = lua_sys.smooth(arrowSize + 0.05, arrowSize, (newTime - 0.1) * 20)
        element.Arrow("size"):SetFloat(smoothedArrowSize)
        element.Rarity("size"):SetFloat(smoothedButtonSize)
        local width = lua_sys.smooth(backingWidth * 1.05, backingWidth, (newTime - 0.1) * 20)
        local height = lua_sys.smooth(backingHeight * 1.05, backingHeight, (newTime - 0.1) * 20)
        element.BackingSprite("width"):SetInt(width)
        element.BackingSprite("height"):SetInt(height)
        if smoothedButtonSize == buttonSize then
          element("ButtonState"):SetInt(game.BUTTON_IDLE)
        end
      else
        element.Arrow("size"):SetFloat(arrowSize)
        element.Rarity("size"):SetFloat(buttonSize)
        element.BackingSprite("width"):SetInt(backingWidth)
        element.BackingSprite("height"):SetInt(backingHeight)
        element("ButtonState"):SetInt(game.BUTTON_IDLE)
      end
    end
  end
end
return BookOfMonsters
