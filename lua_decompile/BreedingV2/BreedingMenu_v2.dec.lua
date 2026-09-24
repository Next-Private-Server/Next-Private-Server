local BreedingRules = include("BreedingRules")
local BreedingGuidance = include("BreedingGuidance")
local BreedingPossibilities = include("BreedingV2/BreedingPossibilities")
local ScrollingListHelper = include("ScrollingListHelper")
local MenuHelpers = include("MenuHelpers")
local OffsetTransition = include("OffsetTransition")
local FadeTransition = include("FadeTransition")
local TweenerPingPong = include("TweenerPingPong")
local MonsterProperties = include("MonsterProperties")
local Coroutines = include("Coroutines")
local ShaderColorizeAndFade = include("ShaderColorizeAndFade")
local ShaderColorizeSimple = include("ShaderColorizeSimple")
local TRANSITION_TIME = 0.33
local EGG_GLOW_MIN_ALPHA = 0.2
local EGG_GLOW_MAX_ALPHA_DELTA = 0.35
local EGG_GLOW_MIN_SIZE = 1 * BreedingMenuScaleX()
local EGG_GLOW_MAX_SIZE_DELTA = 0.1 * BreedingMenuScaleX()
local BreedingMenu_v2 = {
  TouchBlocker = {
    Touch = {}
  },
  LeftMonsterSelect = {
    Handle = {
      BG = {},
      Icon = {},
      Touch = {}
    }
  },
  RightMonsterSelect = {},
  MiddleArea = {
    LeftMonsterPlaceholder = {
      Sprite = {},
      Plus = {},
      Touch = {}
    },
    LeftMonsterAnim = {
      Sprite = {},
      Touch = {}
    },
    RightMonsterPlaceholder = {
      Sprite = {},
      Plus = {},
      Touch = {}
    },
    RightMonsterAnim = {
      Sprite = {},
      Touch = {}
    },
    HeartButton = {
      Sprite = {},
      Text = {},
      Touch = {}
    }
  },
  PossibleEggsFrame = {},
  PossibleEggsBg = {
    Touch = {}
  },
  PossibleEggsList = {
    Swiper = {},
    Touch = {}
  },
  UniqueToggle = {},
  BGGradient = {},
  BGPattern = {},
  LastEggSoundIndex = 0
}
function BreedingMenu_v2:onInit()
  self.executeBreedLeft = 0
  self.executeBreedRight = 0
  self.doneExitTransition = false
  self.tickables = {}
  self.eggGlowPingPong = TweenerPingPong:new({
    loopTime = 1.6,
    ease = lua_sys.Sinusoidal_EaseOut,
    onUpdate = function(target, t, tweener)
      target:GetVar("alpha"):SetFloat(EGG_GLOW_MIN_ALPHA + (1 - t) * EGG_GLOW_MAX_ALPHA_DELTA)
      target:GetVar("size"):SetFloat(EGG_GLOW_MIN_SIZE + t * EGG_GLOW_MAX_SIZE_DELTA)
    end
  })
  table.insert(self.tickables, self.eggGlowPingPong)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
  local hideArrowButtons = true
  if hideArrowButtons then
    self.LeftMonsterSelect.Handle.BG:GetVar("visible"):SetInt(0)
    self.LeftMonsterSelect.Handle.Icon:GetVar("visible"):SetInt(0)
    self.LeftMonsterSelect.Handle.Touch:GetVar("enabled"):SetInt(0)
    self.RightMonsterSelect.Handle.BG:GetVar("visible"):SetInt(0)
    self.RightMonsterSelect.Handle.Icon:GetVar("visible"):SetInt(0)
    self.RightMonsterSelect.Handle.Touch:GetVar("enabled"):SetInt(0)
  end
  game.setMidiFade(0.5, 1)
end
local function SetupListTransitions(controller, list, flipped)
  local showingX = list:GetVar("xOffset"):GetFloat()
  local showingY = list:GetVar("yOffset"):GetFloat()
  local hidingX = -list:absW() - lua_sys.deviceMarginX()
  local hidingY = showingY
  list.Transition = OffsetTransition:new({
    startX = hidingX,
    startY = hidingY,
    endX = showingX,
    endY = showingY,
    duration = TRANSITION_TIME,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y)
      list:GetVar("xOffset"):SetFloat(x)
    end,
    onDoneShow = function()
      list.Handle.Icon:GetVar("hFlip"):SetInt(flipped and 1 or 0)
      list.isShowing = true
    end,
    onDoneHide = function()
      list.Handle.Icon:GetVar("hFlip"):SetInt(flipped and 0 or 1)
      list.isShowing = false
    end
  })
  table.insert(controller.tickables, list.Transition)
  local startHidden = true
  if startHidden then
    list:GetVar("xOffset"):SetFloat(hidingX)
    list:GetVar("yOffset"):SetFloat(hidingY)
  end
  list.isShowing = not startHidden
  list.Handle.Icon:GetVar("hFlip"):SetInt(flipped and 0 or 1)
  function list.Handle.Touch.onTouchUp()
    controller:ToggleList(list)
  end
end
local function SetupEggTrayTransitions(controller, eggTray)
  local showingX = eggTray:GetVar("xOffset"):GetFloat()
  local showingY = eggTray:GetVar("yOffset"):GetFloat()
  local hidingX = showingX
  local hidingY = -(eggTray:absH() + 64 * BreedingMenuScaleY())
  eggTray.Transition = OffsetTransition:new({
    startX = hidingX,
    startY = hidingY,
    endX = showingX,
    endY = showingY,
    duration = TRANSITION_TIME,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y)
      eggTray:GetVar("xOffset"):SetFloat(x)
      eggTray:GetVar("yOffset"):SetFloat(y)
    end,
    onDoneShow = function()
      eggTray.isShowing = true
    end,
    onDoneHide = function()
      eggTray.isShowing = false
    end
  })
  table.insert(controller.tickables, eggTray.Transition)
  local startHidden = true
  if startHidden then
    eggTray:GetVar("xOffset"):SetFloat(hidingX)
    eggTray:GetVar("yOffset"):SetFloat(hidingY)
  end
  eggTray.isShowing = not startHidden
end
local function SetupMonsterSquishTransition(controller, monsterAnim)
  local startScaleX = monsterAnim.Sprite:scale().x
  local startScaleY = monsterAnim.Sprite:scale().y
  monsterAnim.Transition = TweenerPingPong:new({
    onUpdate = function(target, t, tweener)
      if tweener.ping == 0 then
        target:setScale(lua_sys.Vector2(startScaleX * (1 + t * 0.15), startScaleY * (1 - t * 0.15)))
      else
        target:setScale(lua_sys.Vector2(startScaleX * (1 + t * 0.15), startScaleY * (1 - t * 0.15)))
      end
    end,
    onPing = function(tweener)
      tweener.ease = lua_sys.Elastic_EaseOut
      tweener.duration = 0.6
      if tweener.monsterId and tweener.monsterId > 0 then
        game.playMonsterSelectSound(tweener.monsterId, 0)
      end
    end,
    onPong = function(tweener)
      if tweener.monsterId and tweener.monsterId > 0 then
        monsterAnim.Sprite:setScale(lua_sys.Vector2(startScaleX, startScaleY))
      end
      tweener.active = false
    end
  })
  monsterAnim.Transition.targets = {
    monsterAnim.Sprite
  }
  table.insert(controller.tickables, monsterAnim.Transition)
  function monsterAnim:PlaySquish(monsterId)
    if not self.Transition.active then
      self.Transition:Reset()
      self.Transition.active = true
      self.Transition.ease = lua_sys.Back_EaseOut
      self.Transition.loopTime = 0.3
      self.Transition.monsterId = monsterId
      lua_sys.playSoundFx("audio/sfx/item_select.wav")
    end
  end
end
function BreedingMenu_v2:ToggleList(list)
  local otherList = list == self.LeftMonsterSelect and self.RightMonsterSelect or self.LeftMonsterSelect
  local middleTransition = list == self.LeftMonsterSelect and self.MiddleArea.LeftTransition or self.MiddleArea.RightTransition
  if list.isShowing then
    list.Transition:Hide()
  else
    list.Transition:Show()
    if otherList.isShowing then
    end
  end
end
function BreedingMenu_v2:onPostInit()
  SetupListTransitions(self, self.LeftMonsterSelect, false)
  SetupListTransitions(self, self.RightMonsterSelect, true)
  SetupEggTrayTransitions(self, self.PossibleEggsFrame)
  SetupMonsterSquishTransition(self, self.MiddleArea.LeftMonsterAnim)
  SetupMonsterSquishTransition(self, self.MiddleArea.RightMonsterAnim)
  self.fadeables = {}
  self.FadeTransition = FadeTransition:new({
    duration = TRANSITION_TIME,
    ease = lua_sys.Sinusoidal_EaseInOut,
    onUpdate = function(alpha)
      for _, fadeable in ipairs(self.fadeables) do
        fadeable:GetVar("alpha"):SetFloat(alpha)
      end
    end,
    onDoneHide = function()
      self:OnExitTransitionDone()
    end
  })
  table.insert(self.tickables, self.FadeTransition)
  table.insert(self.fadeables, self.MiddleArea.HeartButton.Sprite)
  table.insert(self.fadeables, self.MiddleArea.HeartButton.Text)
  table.insert(self.fadeables, self.UniqueToggle.Sprite)
  table.insert(self.fadeables, self.UniqueToggle.Text)
  table.insert(self.fadeables, self.UniqueToggle.ToggleArea.Sprite)
  table.insert(self.fadeables, self.UniqueToggle.ToggleArea.Handle.Sprite)
  self.FadeTransition:SetAlpha(0)
  self.FadeTransition:Show()
  lua_sys.playSoundFx("audio/sfx/structure_breeding_menu_open.ogg")
  self.MiddleArea.LeftTransition = OffsetTransition:new({
    startX = 0,
    startY = 0,
    endX = self.LeftMonsterSelect:absW() * 0.5,
    endY = 0,
    duration = TRANSITION_TIME,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y)
      self.MiddleArea:GetVar("xOffset"):SetFloat(x)
    end
  })
  table.insert(self.tickables, self.MiddleArea.LeftTransition)
  self.MiddleArea.RightTransition = OffsetTransition:new({
    startX = 0,
    startY = 0,
    endX = -self.RightMonsterSelect:absW() * 0.5,
    endY = 0,
    duration = TRANSITION_TIME,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y)
      self.MiddleArea:GetVar("xOffset"):SetFloat(x)
    end
  })
  table.insert(self.tickables, self.MiddleArea.RightTransition)
  function self.MiddleArea.LeftMonsterAnim.Touch.onTouchUp()
    self.MiddleArea.LeftMonsterAnim:PlaySquish(self.LeftMonsterSelect.SelectedEntry.monster:data():monsterId())
  end
  function self.MiddleArea.RightMonsterAnim.Touch.onTouchUp()
    self.MiddleArea.RightMonsterAnim:PlaySquish(self.RightMonsterSelect.SelectedEntry.monster:data():monsterId())
  end
  self.MiddleArea.HeartButton.heartButtonSize = self.MiddleArea.HeartButton.Sprite:GetVar("size"):GetFloat()
  self.MiddleArea.HeartButton.pulser = TweenerPingPong:new({
    loopTime = 0.5,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(target, t)
      target:GetVar("size"):SetFloat(self.MiddleArea.HeartButton.heartButtonSize * (1 + t * 0.25))
    end
  })
  table.insert(self.tickables, self.MiddleArea.HeartButton.pulser)
  self.MiddleArea.HeartButton.pulser.targets = {
    self.MiddleArea.HeartButton.Sprite
  }
  function self.MiddleArea.HeartButton.Touch.onTouchUp()
    self:breed()
  end
  if game.showBreedingPromoDesc() then
    game.displayNotification(game.breedingPromoDescription())
    game.setShowedBreedingPromoDesc()
  end
  ScrollingListHelper.ListInit(self.PossibleEggsList, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal,
    spacing = 5 * BreedingMenuScaleX()
  })
  self.PossibleEggsList.Swiper:GetVar("enableMouseScroll"):SetInt(0)
  local breedingMonsters = game.worldContext():getAvailableBreedingMonsters()
  local leftMonsters = BreedingRules.Filter(breedingMonsters, BreedingRules.BreedableOnLeft)
  self.LeftMonsterSelect:Setup(self, leftMonsters, false)
  local rightMonsters = BreedingRules.Filter(breedingMonsters, BreedingRules.BreedableOnRight)
  self.RightMonsterSelect:Setup(self, rightMonsters, true)
  local listMaxHeight = lua_sys.screenHeight() - game.contextBarHeight() * 0.5 - 96 * BreedingMenuScaleY()
  local function resizeListHeight(list)
    local listActualHeight = list:absH()
    if listActualHeight > listMaxHeight then
      list:setSize(lua_sys.Vector2(list:absW(), listMaxHeight))
    end
  end
  resizeListHeight(self.LeftMonsterSelect)
  resizeListHeight(self.RightMonsterSelect)
  self:OnListSelected(self.LeftMonsterSelect)
  self:OnEntryDeselected(nil, self.LeftMonsterSelect)
  self:OnEntryDeselected(nil, self.RightMonsterSelect)
  self.MiddleArea.HeartButton:SetActive(false, true)
  local UNIQUE_TOGGLE_KEY = "breedingShowUniqueOnly"
  function self.UniqueToggle.OnToggled(toggle)
    if toggle:IsToggled() then
      self.LeftMonsterSelect:SetUniqueFilter(true)
      self.RightMonsterSelect:SetUniqueFilter(true)
      game.getLocalSettings():set(UNIQUE_TOGGLE_KEY, "1")
    else
      self.LeftMonsterSelect:SetUniqueFilter(false)
      self.RightMonsterSelect:SetUniqueFilter(false)
      game.getLocalSettings():set(UNIQUE_TOGGLE_KEY, "0")
    end
    lua_sys.playSoundFx("audio/sfx/item_select.wav")
  end
  local uniqueToggleState = game.getLocalSettings():get(UNIQUE_TOGGLE_KEY)
  self.UniqueToggle:SetToggled(uniqueToggleState == "1")
  self:SetupFancyBG()
  self:ToggleList(self.LeftMonsterSelect)
  self:ToggleList(self.RightMonsterSelect)
  if not game.tutorialActive() then
    self.PossibleEggsFrame.Transition:Show()
  end
end
function BreedingMenu_v2:BreedingCutsceneCo(doBreed)
  if self.LeftMonsterSelect.SelectedEntry == nil or self.RightMonsterSelect.SelectedEntry == nil then
    print("BreedingMenu_v2:BreedingCutsceneCo() - No monsters selected")
    self:root():removePopUp(self:name())
    return
  end
  local setupSpore = function(spore, gfx)
    spore:GetVar("spriteName"):SetString(gfx)
    spore:GetVar("sheetName"):SetString("xml_resources/" .. gfx .. ".xml")
    spore:GetVar("visible"):SetInt(1)
    spore:GetVar("alpha"):SetFloat(0)
  end
  local leftSpore = self.MiddleArea.LeftMonsterAnim.Spore
  local leftSporeGfx = self.LeftMonsterSelect.SelectedEntry.monster:data():spore()
  setupSpore(leftSpore, leftSporeGfx)
  local leftSporeScaleX = leftSpore:scale().x
  local leftSporeScaleY = leftSpore:scale().y
  local rightSpore = self.MiddleArea.RightMonsterAnim.Spore
  local rightSporeGfx = self.RightMonsterSelect.SelectedEntry.monster:data():spore()
  setupSpore(rightSpore, rightSporeGfx)
  local rightSporeScaleX = rightSpore:scale().x
  local rightSporeScaleY = rightSpore:scale().y
  local leftMonster = self.MiddleArea.LeftMonsterAnim.Sprite
  local rightMonster = self.MiddleArea.RightMonsterAnim.Sprite
  local leftMonsterScaleX = leftMonster:scale().x
  local leftMonsterScaleY = leftMonster:scale().y
  local rightMonsterScaleX = rightMonster:scale().x
  local rightMonsterScaleY = rightMonster:scale().y
  ShaderColorizeAndFade:getUniform("u_Factor"):setFloat(0)
  ShaderColorizeAndFade:getUniform("u_Fade"):setFloat(1)
  ShaderColorizeAndFade:getUniform("u_TargetColor"):setVec3(lua_sys.Vector3(1, 1, 1))
  leftMonster:setShader(ShaderColorizeAndFade)
  rightMonster:setShader(ShaderColorizeAndFade)
  if doBreed then
    game.breed(self.executeBreedLeft, self.executeBreedRight)
  end
  print("waiting for MsgBreedMonsters...")
  local success = false
  local errorMsg
  coroutine.yield({
    game.engineReceiver(),
    game.M_MsgBreedMonsters_GetMsgTypeId(),
    function(m)
      success = m.success
      errorMsg = m.msg
      return true
    end
  })
  print("got MsgBreedMonsters!", success, errorMsg)
  if success then
    do
      local leftEggTargetX = leftSpore:absX()
      local leftEggTargetY = leftSpore:absY()
      local rightEggTargetX = rightSpore:absX()
      local rightEggTargetY = rightSpore:absY()
      local getItNowPopup = self:root():getPopUp("get_it_now_breed")
      if getItNowPopup then
        print("BreedingMenu_v2:BreedingCutsceneCo() - found get_it_now_breed popup!!")
        local leftEgg = getItNowPopup.ParentEggsImage.Parent1.Sprite
        leftEggTargetX = leftEgg:absX()
        leftEggTargetY = leftEgg:absY()
        local rightEgg = getItNowPopup.ParentEggsImage.Parent2.Sprite
        rightEggTargetX = rightEgg:absX()
        rightEggTargetY = rightEgg:absY()
        getItNowPopup:SetEnabled(false)
        getItNowPopup:SetAlpha(0)
      end
      local SPORE_Y_OFFSET = 0
      local leftEggTransition = OffsetTransition:new({
        startX = leftSpore:GetVar("xOffset"):GetFloat(),
        startY = leftSpore:GetVar("yOffset"):GetFloat() + SPORE_Y_OFFSET,
        endX = leftSpore:GetVar("xOffset"):GetFloat() + (leftEggTargetX - leftSpore:absX()),
        endY = leftSpore:GetVar("yOffset"):GetFloat() + (leftEggTargetY - leftSpore:absY()),
        duration = 0.66,
        ease = lua_sys.Quadratic_EaseIn,
        onUpdate = function(x, y)
          leftSpore:GetVar("xOffset"):SetFloat(x)
          leftSpore:GetVar("yOffset"):SetFloat(y)
        end
      })
      table.insert(self.tickables, leftEggTransition)
      local rightEggTransition = OffsetTransition:new({
        startX = rightSpore:GetVar("xOffset"):GetFloat(),
        startY = rightSpore:GetVar("yOffset"):GetFloat() + SPORE_Y_OFFSET,
        endX = rightSpore:GetVar("xOffset"):GetFloat() + (rightEggTargetX - rightSpore:absX()),
        endY = rightSpore:GetVar("yOffset"):GetFloat() + (rightEggTargetY - rightSpore:absY()),
        duration = 0.66,
        ease = lua_sys.Quadratic_EaseIn,
        onUpdate = function(x, y)
          rightSpore:GetVar("xOffset"):SetFloat(x)
          rightSpore:GetVar("yOffset"):SetFloat(y)
        end
      })
      table.insert(self.tickables, rightEggTransition)
      local fadeTransition1 = FadeTransition:new({
        duration = 1,
        maxFade = 1,
        ease = lua_sys.Quadratic_EaseIn,
        onUpdate = function(alpha)
          ShaderColorizeAndFade:getUniform("u_Factor"):setFloat(alpha)
          local scaleFactor = 1 + alpha * 0.33
          leftMonster:setScale(lua_sys.Vector2(scaleFactor * leftMonsterScaleX, scaleFactor * leftMonsterScaleY))
          rightMonster:setScale(lua_sys.Vector2(scaleFactor * rightMonsterScaleX, scaleFactor * rightMonsterScaleY))
        end
      })
      table.insert(self.tickables, fadeTransition1)
      fadeTransition1:Show()
      lua_sys.playSoundFx("audio/sfx/structure_breeding_menu_breedcutscene_dissolve.ogg")
      Coroutines.WaitForSeconds(0.5)
      self.MiddleArea.LeftMonsterAnim.Effect:start()
      self.MiddleArea.RightMonsterAnim.Effect:start()
      Coroutines.WaitForSeconds(0.5)
      local fadeTransition2 = FadeTransition:new({
        duration = 1,
        maxFade = 1,
        ease = lua_sys.Exponential_EaseIn,
        onUpdate = function(alpha)
          leftSpore:GetVar("alpha"):SetFloat(alpha)
          rightSpore:GetVar("alpha"):SetFloat(alpha)
          local fadeFactor = 1 - alpha
          ShaderColorizeAndFade:getUniform("u_Fade"):setFloat(fadeFactor)
          ShaderColorizeAndFade:getUniform("u_TargetColor"):setVec3(lua_sys.Vector3(fadeFactor, fadeFactor, fadeFactor))
          local scaleFactor = fadeFactor * 1.33
          leftMonster:setScale(lua_sys.Vector2(scaleFactor * leftMonsterScaleX, scaleFactor * leftMonsterScaleY))
          rightMonster:setScale(lua_sys.Vector2(scaleFactor * rightMonsterScaleX, scaleFactor * rightMonsterScaleY))
        end
      })
      table.insert(self.tickables, fadeTransition2)
      fadeTransition2:Show()
      lua_sys.playSoundFx("audio/sfx/structure_breeding_menu_breedcutscene_eggthump.ogg")
      Coroutines.WaitForSeconds(0.75)
      leftEggTransition:Show()
      rightEggTransition:Show()
      if self.BGFadeTransition then
        self.BGFadeTransition:Hide()
      end
      local fadeTransition3 = FadeTransition:new({
        duration = 0.33,
        maxFade = 1,
        ease = lua_sys.Sinusoidal_EaseInOut,
        onUpdate = function(alpha)
          leftSpore:GetVar("alpha"):SetFloat(1 - alpha)
          rightSpore:GetVar("alpha"):SetFloat(1 - alpha)
          getItNowPopup = self:root():getPopUp("get_it_now_breed")
          if getItNowPopup then
            getItNowPopup:SetAlpha(alpha)
          end
        end
      })
      table.insert(self.tickables, fadeTransition3)
      fadeTransition3:Show()
      Coroutines.WaitForSeconds(0.33)
      getItNowPopup = self:root():getPopUp("get_it_now_breed")
      if getItNowPopup then
        getItNowPopup:SetEnabled(true)
      end
    end
  end
  self.doneExitTransition = true
  self.coroutineId = nil
end
function BreedingMenu_v2:OnExitTransitionDone()
  if not self.coroutineId and self.executeBreedLeft ~= 0 and self.executeBreedRight ~= 0 then
    self.coroutineId = RunIndyCoroutine(self.BreedingCutsceneCo, self, true)
  else
    self:root():removePopUp(self:name())
  end
end
function BreedingMenu_v2:onDestroy()
  if self.coroutineId then
    KillCoroutine(self.coroutineId)
    self.coroutineId = nil
  end
end
function BreedingMenu_v2:onTick(dt)
  if self.doneExitTransition then
    print("BreedingMenu_v2", "popping self")
    self:root():removePopUp(self:name())
    return
  end
  for _, tickable in ipairs(self.tickables) do
    if tickable.Tick then
      tickable:Tick(dt)
    end
  end
  if self.eggTransitions then
    for _, tickable in ipairs(self.eggTransitions) do
      if tickable.Tick then
        tickable:Tick(dt)
      end
    end
  end
  ScrollingListHelper.ListTick(self.PossibleEggsList, dt)
  self:updateClipping()
end
function BreedingMenu_v2:updatePossibilities()
  ScrollingListHelper.ListClear(self.PossibleEggsList)
  self.eggTransitions = {}
  self.eggGlowPingPong.targets = {}
  if not self.LeftMonsterSelect.SelectedEntry or not self.RightMonsterSelect.SelectedEntry then
    self.MiddleArea.HeartButton:SetActive(false)
    return
  end
  local leftMonster = self.LeftMonsterSelect.SelectedEntry.monster
  local rightMonster = self.RightMonsterSelect.SelectedEntry.monster
  local allPossibleResults = BreedingPossibilities:getPossibleResults(leftMonster:data(), rightMonster:data(), false)
  local function createFunc(idx, itemName)
    local possibleMonster = allPossibleResults[idx + 1]
    local data = game.getMonsterData(possibleMonster)
    local isAvailable = game.monsterIsAvail(possibleMonster, false)
    local newEntry = menu:addTemplateElement("template_breeding_spore", itemName, self.PossibleEggsList)
    local adjustmentSize = 0.7
    newEntry:templateVars().adjustmentSize = adjustmentSize
    newEntry:setSize(Vector2(newEntry:absW() * adjustmentSize, newEntry:absH() * adjustmentSize))
    newEntry:init()
    local spriteName = data:spore()
    local sheetName = "xml_resources/" .. data:spore() .. ".xml"
    local hasUnlockedMonster = game.hasOrHasEverHadMonsterOnActiveIsland(possibleMonster)
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
      if data:isRareMonster() then
        raritySprite = "button_monstersrares"
        rarityColor = colors.rare
      elseif data:isEpicMonster() then
        raritySprite = "button_monstersepics"
        rarityColor = colors.epic
      end
      newEntry.Sprite:setColor(0, 0, 0)
      newEntry.Rarity:GetVar("visible"):SetInt(1)
      newEntry.Rarity:GetVar("spriteName"):SetString(raritySprite)
      local glowSprite = newEntry.Glow
      glowSprite:GetVar("visible"):SetInt(1)
      glowSprite:GetVar("spriteName"):SetString("white glow")
      glowSprite:GetVar("sheetName"):SetString("xml_resources/island_intro_sheet.xml")
      local imageScale = 0.045 * adjustmentSize
      glowSprite:setScale(lua_sys.Vector2(6 * imageScale, 5 * imageScale))
      glowSprite:setShader(ShaderColorizeSimple)
      glowSprite:setColor(rarityColor.r, rarityColor.g, rarityColor.b)
    end
    newEntry.Sprite:GetVar("spriteName"):SetString(spriteName)
    newEntry.Sprite:GetVar("sheetName"):SetString(sheetName)
    newEntry.Text:GetVar("visible"):SetInt(0)
    function newEntry.Touch.onTouchDown(component, element, x, y)
      element.dragging = 0
    end
    function newEntry.Touch.onTouchDrag(component, element, x, y, dx, dy)
      local dist = math.sqrt(dx * dx + dy * dy)
      element.dragging = dist
    end
    function newEntry.Touch.onTouchUp(component, element, x, y)
      if element.dragging < 10 then
        self:ShowEggsPopup()
      end
    end
    newEntry:postInit()
    local eggSoundIndex = math.random(1, 4)
    if self.LastEggSoundIndex == eggSoundIndex then
      eggSoundIndex = eggSoundIndex % 4 + 1
    end
    self.LastEggSoundIndex = eggSoundIndex
    local targetSize = newEntry.Sprite:GetVar("size"):GetFloat()
    local targetGlowSize = newEntry.Glow:GetVar("size"):GetFloat()
    local transition = FadeTransition:new({
      duration = 0.33,
      maxFade = 1,
      delayOnShow = 0.1 * #self.eggTransitions,
      ease = lua_sys.Back_EaseIn,
      onUpdate = function(alpha, transitionSelf)
        newEntry.Sprite:GetVar("size"):SetFloat(targetSize * alpha)
        newEntry.Sprite:GetVar("alpha"):SetFloat(alpha)
        newEntry.Glow:GetVar("size"):SetFloat(targetGlowSize * alpha)
        newEntry.Glow:GetVar("alpha"):SetFloat(alpha * EGG_GLOW_MIN_ALPHA)
        if eggSoundIndex > 0 and 0 < transitionSelf.remainingTime then
          lua_sys.playSoundFx(string.format("audio/sfx/structure_breeding_menu_showpotentialegg_%02d.ogg", eggSoundIndex))
          eggSoundIndex = 0
        end
      end,
      onDoneShow = function()
        if not hasUnlockedMonster then
          table.insert(self.eggGlowPingPong.targets, newEntry.Glow)
        end
      end
    })
    transition:SetAlpha(0)
    transition:Show()
    table.insert(self.eggTransitions, transition)
    return newEntry
  end
  ScrollingListHelper.ListPopulate(self.PossibleEggsList, #allPossibleResults, createFunc)
  self.PossibleEggsList.Swiper:setScrollOffset(0)
  self.MiddleArea.HeartButton:SetActive(true)
  self:updateClipping()
  self.possibleResults = allPossibleResults
end
function BreedingMenu_v2:breed()
  if game.getPopUp("popup_breed_warning") then
    return
  end
  if self.coroutineId then
    return
  end
  if self.FadeTransition and self.FadeTransition:GetTransitionTime() > 0 then
    return
  end
  if self.possibleResults and #self.possibleResults == 0 then
    game.displayNotification("BREEDING_NO_COMBOS")
    return
  end
  local executeBreedLeft
  if self.LeftMonsterSelect.SelectedEntry then
    executeBreedLeft = self.LeftMonsterSelect.SelectedEntry.monster:uniqueId()
  end
  local executeBreedRight
  if self.RightMonsterSelect.SelectedEntry then
    executeBreedRight = self.RightMonsterSelect.SelectedEntry.monster:uniqueId()
  end
  self.executeBreedLeft = executeBreedLeft
  self.executeBreedRight = executeBreedRight
  if BreedingGuidance:CheckBreeding(self.executeBreedLeft, self.executeBreedRight) then
    if self.executeBreedLeft ~= 0 and self.executeBreedRight ~= 0 then
      self.TouchBlocker.Touch:GetVar("enabled"):SetInt(1)
      self:queuePop()
      lua_sys.playSoundFx("audio/sfx/structure_breeding_menu_breedcutscene_start.ogg")
    else
      game.displayNotification("BREED_ERROR_SELECT_TWO_MONSTERS")
    end
  end
end
function BreedingMenu_v2:RetryBreed()
  local lastMonsterA = game.lastBredMonster1()
  local lastMonsterB = game.lastBredMonster2()
  if lastMonsterA > 0 and lastMonsterB > 0 then
    if not self.LeftMonsterSelect.SelectedEntry or self.LeftMonsterSelect.SelectedEntry.monster:uniqueId() ~= lastMonsterA then
      self.LeftMonsterSelect:SelectMonsterByUId(lastMonsterA)
    end
    if not self.RightMonsterSelect.SelectedEntry or self.RightMonsterSelect.SelectedEntry.monster:uniqueId() ~= lastMonsterB then
      self.RightMonsterSelect:SelectMonsterByUId(lastMonsterB)
    end
  end
end
function BreedingMenu_v2:queuePop()
  manager:setContext("BLANK")
  self.MiddleArea.HeartButton.Touch("enabled"):SetInt(0)
  if self.FadeTransition then
    self.FadeTransition:Hide()
  end
  if self.LeftMonsterSelect.isShowing then
    self.LeftMonsterSelect.Transition:Hide()
  end
  if self.RightMonsterSelect.isShowing then
    self.RightMonsterSelect.Transition:Hide()
  end
  if self.PossibleEggsFrame.isShowing then
    self.PossibleEggsFrame.Transition:Hide()
  end
  if self.executeBreedLeft == 0 or self.executeBreedRight == 0 then
    if self.BGFadeTransition then
      self.BGFadeTransition:Hide()
    end
    if self.MiddleArea.LeftMonsterAnim.Sprite:GetVar("visible"):GetInt() == 1 then
      self.MiddleArea.LeftMonsterAnim.Sprite:GetVar("visible"):SetInt(0)
    end
    if self.MiddleArea.RightMonsterAnim.Sprite:GetVar("visible"):GetInt() == 1 then
      self.MiddleArea.RightMonsterAnim.Sprite:GetVar("visible"):SetInt(0)
    end
  end
  game.setMidiFade(1, 1)
  lua_sys.playSoundFx("audio/sfx/structure_breeding_menu_close.ogg")
end
function BreedingMenu_v2:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "BREED_WARNING" then
    if msg.choice == true then
      self:queuePop()
    else
      self.executeBreedLeft = 0
      self.executeBreedRight = 0
    end
  end
end
function BreedingMenu_v2:ShowFeedPopup(entry)
  if self:root():getPopUp("breeding_feed_popup") then
    print("Feed Popup already open, not opening another")
    return
  end
  local feedPopup = self:root():pushPopUp("breeding_feed_popup")
  if feedPopup then
    feedPopup:Setup(entry.monster)
    self.LeftMonsterSelect:SetActive(false)
    self.RightMonsterSelect:SetActive(false)
  end
end
function BreedingMenu_v2:ShowEggsPopup()
  if not self.LeftMonsterSelect.SelectedEntry or not self.RightMonsterSelect.SelectedEntry then
    print("Need 2 Monsters Selected to Show Eggs Popup")
    return
  end
  manager:setReserveState("BREED_MENU_V2")
  local eggsPopup = self:root():pushPopUp("breeding_eggs_popup")
  if eggsPopup then
    self.LeftMonsterSelect:SetActive(false)
    self.RightMonsterSelect:SetActive(false)
    local leftMonster = self.LeftMonsterSelect.SelectedEntry.monster
    local rightMonster = self.RightMonsterSelect.SelectedEntry.monster
    local allPossibleResults = BreedingPossibilities:getPossibleResults(leftMonster:data(), rightMonster:data(), true)
    eggsPopup:Setup(allPossibleResults)
  end
end
function BreedingMenu_v2:OnListSelected(list)
  list:SetActive(true)
  local otherList = list == self.LeftMonsterSelect and self.RightMonsterSelect or self.LeftMonsterSelect
  otherList:SetActive(false)
end
function BreedingMenu_v2:OnEntrySelected(entry, list)
  if entry then
    local monsterData = entry.monster:data()
    local animFile = monsterData:animationFile()
    local facing = MonsterProperties.getFacing(monsterData:monsterId())
    if monsterData:isModal() then
      local currentMode = game.player():getActiveIsland():islandMode()
      modalMonsterData = game.getModalMonsterData(monsterData, currentMode)
      animFile = modalMonsterData:animationFile()
      facing = MonsterProperties.getFacing(modalMonsterData:monsterId())
    end
    local targetAnim = list == self.LeftMonsterSelect and self.MiddleArea.LeftMonsterAnim or self.MiddleArea.RightMonsterAnim
    targetAnim.Touch:GetVar("enabled"):SetInt(1)
    targetAnim.Sprite:GetVar("visible"):SetInt(1)
    targetAnim.Sprite:GetVar("animationName"):SetString("xml_bin/" .. animFile)
    targetAnim.Sprite:GetVar("animation"):SetString("Store")
    local costumeId = entry.monster:getEquippedCostume()
    if costumeId > 0 then
      game.applyCostumeToAnimComponent(targetAnim.Sprite, costumeId)
    end
    local hFlip = list == self.RightMonsterSelect and 1 - facing or facing
    targetAnim.Sprite:GetVar("hFlip"):SetInt(hFlip)
    targetAnim.Sprite:GetVar("offsetCenter"):SetInt(1)
    targetAnim:PlaySquish(monsterData:monsterId())
    local otherList = list == self.LeftMonsterSelect and self.RightMonsterSelect or self.LeftMonsterSelect
    otherList:SetMonstersEnabled(monsterData:monsterId(), false)
    self:updatePossibilities()
  else
    self:updatePossibilities()
  end
end
function BreedingMenu_v2:OnEntryDeselected(entry, list)
  local targetAnim = list == self.LeftMonsterSelect and self.MiddleArea.LeftMonsterAnim or self.MiddleArea.RightMonsterAnim
  targetAnim.Sprite:GetVar("visible"):SetInt(0)
  targetAnim.Touch:GetVar("enabled"):SetInt(0)
  if entry then
    local otherList = list == self.LeftMonsterSelect and self.RightMonsterSelect or self.LeftMonsterSelect
    otherList:SetMonstersEnabled(entry.monster:data():monsterId(), true)
  end
end
function BreedingMenu_v2:updateClipping()
  local clipX = self.PossibleEggsBg:absX()
  local clipY = self.PossibleEggsBg:absY()
  local clipW = self.PossibleEggsBg:absW()
  local clipH = self.PossibleEggsBg:absH()
  MenuHelpers.ForEachEntry(self.PossibleEggsList, function(entry)
    entry:updateClipping(clipX, clipY, clipW, clipH)
  end)
end
function BreedingMenu_v2.PossibleEggsBg.Touch:onTouchUp(element)
  element:parent():ShowEggsPopup()
end
function BreedingMenu_v2.PossibleEggsList.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function BreedingMenu_v2.PossibleEggsList.Swiper:onTick(element, dt)
  ScrollingListHelper.SwiperTick(self, element, dt)
end
function BreedingMenu_v2.MiddleArea.HeartButton:SetActive(active, force)
  force = force or false
  if self.isActive ~= active or force then
    if active then
      self.Sprite:GetVar("spriteName"):SetString("breed_button_on")
      self.Text:GetVar("text"):SetString(LOC("BREEDING_HEART_READY"))
      self.Touch:GetVar("enabled"):SetInt(1)
    else
      self.Sprite:GetVar("spriteName"):SetString("breed_button_off")
      self.Text:GetVar("text"):SetString(LOC("BREEDING_HEART_EMPTY"))
      self.Touch:GetVar("enabled"):SetInt(0)
    end
    self.Sprite:GetVar("size"):SetFloat(self.heartButtonSize)
    self.isActive = active
    self.pulser:Reset()
    self.pulser.active = active
  end
end
function BreedingMenu_v2:SetupFancyBG()
  local showFancyBG = true
  local scrollingBG = self.BGPattern.Sprite
  local gradientBG = self.BGGradient.Sprite
  if showFancyBG then
    local targetWidth = lua_sys.screenWidth()
    local targetHeight = lua_sys.screenHeight()
    scrollingBG:setScale(lua_sys.Vector2(targetWidth / 128, targetHeight / 128))
    scrollingBG:GetVar("layer"):SetString("MidPopUps")
    scrollingBG:GetVar("alpha"):SetFloat(1)
    scrollingBG:GetVar("repeating"):SetInt(1)
    scrollingBG:setShader(include("ShaderScrollingPattern"))
    gradientBG:setScale(lua_sys.Vector2(targetWidth / 1024, targetHeight / 4))
    gradientBG:GetVar("layer"):SetString("MidPopUps")
    gradientBG:GetVar("spriteName"):SetString("gfx/menu/gradient_bg_breeding")
    scrollingBG:GetVar("spriteName"):SetString("gfx/menu/bg_symbols_bubble")
    self.BGFadeTransition = FadeTransition:new({
      duration = TRANSITION_TIME,
      onUpdate = function(alpha)
        gradientBG:GetVar("alpha"):SetFloat(alpha)
        scrollingBG:GetVar("alpha"):SetFloat(alpha)
      end
    })
    table.insert(self.tickables, self.BGFadeTransition)
    self.BGFadeTransition:SetAlpha(0)
    self.BGFadeTransition:Show()
  else
    gradientBG:GetVar("visible"):SetInt(0)
    scrollingBG:GetVar("visible"):SetInt(0)
  end
end
return BreedingMenu_v2
