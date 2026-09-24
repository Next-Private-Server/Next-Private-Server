local FadeTransition = include("FadeTransition")
local FlyingIcon = include("FlyingIcon")
local getCardMaskShader = function()
  local shader = game.getShader("ShaderCardMask")
  if shader == nil then
    shader = game.createShader()
    shader:setVertexShaderSource("shaders/vertex_additive.glsl")
    shader:setFragmentShaderSource("shaders/frag_masking_extra.glsl")
    shader:addSamplerUniform("u_MaskTexture", 2, "gfx/menu/stickers/sticker_MASK")
    shader:addVec3Uniform("u_TargetColor", lua_sys.Vector3(1, 1, 1))
    local imageWidth = 222
    local imageHeight = 290
    local maskWidth = 222
    local maskHeight = 290
    local scaleX = maskWidth / imageWidth
    local scaleY = maskHeight / imageHeight
    shader:addVec2Uniform("u_ImageScale", lua_sys.Vector2(scaleX, scaleY))
    local offsetX = (1 - scaleX) / 2
    local offsetY = (1 - scaleY) / 2
    shader:addVec2Uniform("u_ImageOffset", lua_sys.Vector2(offsetX, offsetY))
    shader:link()
    if shader:isLinked() then
      game.putShader("ShaderCardMask", shader)
    else
      print("Error linking shader!")
      game.destroyShader(shader)
      shader = nil
    end
  end
  return shader
end
local AUTO_OPEN_DELAY = 0.33
local TAP_TO_CONTINUE_DELAY = 2
local OpenCardPack = {
  Fade = {
    Touch = {}
  },
  Layout = {
    Sprite = {},
    Text = {},
    Effect = {}
  },
  CurrencyCounter = {},
  BackButton = {
    Overlay = {}
  },
  PacksRemaining = {
    Sprite = {},
    Text = {}
  },
  SkipAllButton = {}
}
local CardPackTypeStr = {
  [game.CardPackType_Common] = "Common",
  [game.CardPackType_Uncommon] = "Uncommon",
  [game.CardPackType_Rare] = "Rare",
  [game.CardPackType_Epic] = "Epic",
  [game.CardPackType_Legendary] = "Legendary"
}
local CardRarityStr = {
  [game.CardRarity_Unknown] = "Unknown",
  [game.CardRarity_OneStar] = "One Star",
  [game.CardRarity_TwoStar] = "Two Star",
  [game.CardRarity_ThreeStar] = "Three Star",
  [game.CardRarity_FourStar] = "Four Star",
  [game.CardRarity_FiveStar] = "Five Star",
  [game.CardRarity_FourStarGold] = "Four Star Gold",
  [game.CardRarity_FiveStarGold] = "Five Star Gold"
}
local STATES = {
  INTRO = 1,
  IDLE = 2,
  OPEN = 3,
  RESULTS = 4,
  POST_RESULTS = 5,
  OUTRO = 6
}
local packAnimations = {
  [game.CardPackType_Common] = {
    [STATES.INTRO] = "intro",
    [STATES.IDLE] = "idle",
    [STATES.OPEN] = "ripping_common",
    [STATES.RESULTS] = "layout_common",
    [STATES.OUTRO] = "collect_common"
  },
  [game.CardPackType_Uncommon] = {
    [STATES.INTRO] = "intro",
    [STATES.IDLE] = "idle",
    [STATES.OPEN] = "ripping_uncommon",
    [STATES.RESULTS] = "layout_uncommon",
    [STATES.OUTRO] = "collect_uncommon"
  },
  [game.CardPackType_Rare] = {
    [STATES.INTRO] = "intro",
    [STATES.IDLE] = "idle",
    [STATES.OPEN] = "ripping_rare",
    [STATES.RESULTS] = "layout_rare",
    [STATES.OUTRO] = "collect_rare"
  },
  [game.CardPackType_Epic] = {
    [STATES.INTRO] = "intro",
    [STATES.IDLE] = "idle",
    [STATES.OPEN] = "ripping_epic",
    [STATES.RESULTS] = "layout_epic",
    [STATES.OUTRO] = "collect_epic"
  },
  [game.CardPackType_Legendary] = {
    [STATES.INTRO] = "intro",
    [STATES.IDLE] = "idle",
    [STATES.OPEN] = "ripping_legendary",
    [STATES.RESULTS] = "layout_legendary",
    [STATES.OUTRO] = "collect_legendary"
  }
}
local packRemaps = {
  [game.CardPackType_Common] = "sticker_pack_common_sheet.xml",
  [game.CardPackType_Uncommon] = "sticker_pack_uncommon_sheet.xml",
  [game.CardPackType_Rare] = "sticker_pack_rare_sheet.xml",
  [game.CardPackType_Epic] = "sticker_pack_epic_sheet.xml",
  [game.CardPackType_Legendary] = "sticker_pack_legendary_sheet.xml"
}
local function getPackAnimation(packType, state)
  packType = packType or game.CardPackType_Common
  state = state or STATES.INTRO
  if packAnimations[packType] and packAnimations[packType][state] then
    return packAnimations[packType][state]
  else
    return nil
  end
end
local cardEntities = {}
local createCardEntity = function(parent, name)
  local entity = menu:addTemplateElement("template_card", name, parent)
  entity:templateVars().layer = "Tutorial"
  entity:init()
  entity:setPositionBroadcast(true)
  entity:postInit()
  entity.FX:GetVar("magnification"):SetFloat(16)
  entity.FX:GetVar("layer"):SetString("Tutorial")
  entity.FX:GetVar("effect"):SetString("particles/Menus/Stickers/FX_RareCard.efkefc")
  entity.FX:setOrientationPriority(100)
  entity:SetupGenericListener(entity.Sprite:GetReceiver(), "sys::msg::MsgAnimationFinished", "gotMsgAnimationFinished")
  return entity
end
local function createCardEntities(parent, cardDataList)
  for i, entity in ipairs(cardEntities) do
    parent:RemoveElement(entity)
  end
  cardEntities = {}
  local cardIds = {}
  for i = 1, #cardDataList do
    local entity = createCardEntity(parent, "CARD_0" .. tostring(i))
    local playerCardAlbum = game.player():currentlyActiveCardAlbum()
    local multipleInPack = false
    for j = 1, #cardIds do
      if cardIds[j] == cardDataList[i].id then
        multipleInPack = true
      end
    end
    local isNew = playerCardAlbum:numCardsCollected(cardDataList[i].id) == 0 and multipleInPack == false
    entity:Setup(cardDataList[i], isNew, false)
    table.insert(cardIds, cardDataList[i].id)
    table.insert(cardEntities, entity)
  end
end
local function playCollectParticle(e, c, starsCollected)
  local delayInc = 0.1
  local amount = starsCollected
  for i = 1, math.min(10, amount) do
    local SPREAD_X = 16 * game.hudScale()
    local SPREAD_Y = 8 * game.hudScale()
    local spreadX = amount == 1 and 0 or (math.random() * 2 - 1) * SPREAD_X
    local spreadY = amount == 1 and 0 or (math.random() * 2 - 1) * SPREAD_Y
    if i == 1 then
    else
    end
    local flyingIcon = FlyingIcon.Create({
      parent = menu,
      layer = "Loading",
      spriteName = "star_01",
      sheetName = "xml_resources/stickers_sheet_01.xml",
      size = 0.5 * game.hudScale(),
      delayOnStart = 0.05 + i * delayInc,
      srcX = c:absX() + c:absW() * 0.5 + spreadX,
      srcY = c:absY() + 20 * game.hudScale() + spreadY,
      onComplete = function(fi)
        if not fi.isDead then
          e.targetCurrency = e.targetCurrency + starsCollected
          for i = #e.flyingIcons, 1, -1 do
            if e.flyingIcons[i] == fi then
              table.remove(e.flyingIcons, i)
              break
            end
          end
        end
      end or nil
    })
    table.insert(e.flyingIcons, flyingIcon)
    delayInc = delayInc - 0.005
  end
end
local revealCard = function(e, c)
  c.Touch.onTouchUp = nil
  local starsCollected = e:cardSelected(c)
  if starsCollected > 0 then
    table.insert(e.queuedParticles, {card = c, starsCollected = starsCollected})
  end
  function c:gotMsgAnimationFinished(msg)
    c.revealed = true
  end
  print("revealed card's rarity:", c.cardData.rarity)
  if c.appearance.showRevealFX then
    c.FX:start()
  end
  if c.appearance.revealSound then
    lua_sys.playSoundFx(c.appearance.revealSound)
  end
  c:playRevealAnimation()
end
local getFxColorForPack = function(packContents)
  local color = {
    r = 0.45,
    g = 0.8,
    b = 1
  }
  local isUltra = false
  local isGolden = false
  for i = 1, #packContents do
    local card = packContents[i]
    if card.rarity == game.CardRarity_FourStarGold or card.rarity == game.CardRarity_FourStarGold then
      isUltra = true
      break
    end
    if card.rarity == game.CardRarity_FiveStar then
      isGolden = true
    end
  end
  if isUltra then
    color = {
      r = 0.4,
      g = 0.286,
      b = 0.847
    }
  elseif isGolden then
    color = {
      r = 1,
      g = 0.867,
      b = 0.22
    }
  end
  return color.r, color.g, color.b
end
local function skipPackOpeningSequence(self, e)
  print("skipping")
  if e.currentState.id < STATES.OPEN then
    e:openCardPack()
    e:setState(STATES.OPEN)
  end
  if e.currentState.id < STATES.RESULTS then
    e:setState(STATES.RESULTS)
  end
  if e.currentState.id == STATES.RESULTS then
    for i = 1, #cardEntities do
      local c = cardEntities[i]
      local starsCollected = e:cardSelected(c)
      if starsCollected > 0 then
        table.insert(e.queuedParticles, {card = c, starsCollected = starsCollected})
      end
      c.gotMsgAnimationFinished = nil
      c.Sprite:GetVar("animation"):SetString("shown_01")
    end
    e:setState(STATES.POST_RESULTS)
  end
end
local states = {
  [STATES.INTRO] = {
    id = STATES.INTRO,
    setup = function(self, e)
      e.Layout.Sprite:GetVar("visible"):SetInt(1)
      lua_sys.playSoundFx("audio/sfx/sticker_pack_show.ogg")
      e:setAnimationForState(STATES.INTRO)
      for i = 1, #cardEntities do
        local c = cardEntities[i]
        c:setInvisible()
      end
      e.BackButton:setVisible()
      e.BackButton.Overlay:GetVar("visible"):SetInt(1)
    end,
    onSkip = skipPackOpeningSequence,
    onAnimationFinished = function(self, e)
      e:setNextState(STATES.IDLE)
    end
  },
  [STATES.IDLE] = {
    id = STATES.IDLE,
    setup = function(self, e)
      e:setAnimationForState(STATES.IDLE)
      function e.Fade.Touch.onTouchUp(component, element)
        e:packSelected()
        e:setState(STATES.OPEN)
        lua_sys.playSoundFx("audio/sfx/sticker_pack_open.ogg")
      end
      e.TapTimer = 0
    end,
    tick = function(self, e, dt)
      e.TapTimer = e.TapTimer + dt
      if e.Layout.Text:GetVar("visible"):GetInt() == 0 and e.TapTimer > TAP_TO_CONTINUE_DELAY then
        e.Layout.Text:GetVar("visible"):SetInt(1)
        e.LayoutTextTransition:SetAlpha(0)
        e.LayoutTextTransition:Show()
      end
    end,
    onSkip = skipPackOpeningSequence,
    teardown = function(self, e)
      e.Fade.Touch.onTouchUp = nil
      e.LayoutTextTransition:Hide()
    end
  },
  [STATES.OPEN] = {
    id = STATES.OPEN,
    setup = function(self, e)
      e:setAnimationForState(STATES.OPEN)
      for i = 1, #cardEntities do
        e:attachCardToPack(i)
      end
      e.animUtil:resetAnim()
      e.Layout.Sprite:Play()
      self.hasPlayedRipEffect = false
    end,
    tick = function(self, e, dt)
      if not self.hasPlayedRipEffect then
        self.hasPlayedRipEffect = true
        local packSize = e.animUtil:getSize("Pack")
        local packPos = e.animUtil:getWorldPos("Pack")
        local packScale = e.animUtil:getWorldScale("Pack")
        local posX = packPos.x + packSize.x * packScale.x * 0.16
        local posY = packPos.y
        e.Layout.Effect:setPosition(lua_sys.Vector2(posX, posY))
        e.Layout.Effect:setColor(getFxColorForPack(e.packContents))
        e.Layout.Effect:start()
      end
    end,
    onSkip = skipPackOpeningSequence,
    onAnimationFinished = function(self, e)
      e:setNextState(STATES.RESULTS)
    end
  },
  [STATES.RESULTS] = {
    id = STATES.RESULTS,
    setup = function(self, e)
      e.openingAll = true
      e:setAnimationForState(STATES.RESULTS)
      for i = 1, #cardEntities do
        local c = cardEntities[i]
        c.revealed = false
      end
    end,
    tick = function(self, e, dt)
      if e.openingAll then
        e.openingDelay = e.openingDelay or 0
        e.openingDelay = math.max(e.openingDelay - dt, 0)
        if e.openingDelay == 0 then
          for i = 1, #cardEntities do
            local c = cardEntities[i]
            if not c.revealing then
              c.revealing = true
              revealCard(e, c)
              e.openingDelay = c.appearance.revealDelay or 1
              break
            end
          end
        end
      end
      local allRevealed = true
      for i = 1, #cardEntities do
        local c = cardEntities[i]
        if c.revealed and c.Sprite:GetVar("animation"):GetString() ~= "shown_01" then
          c.gotMsgAnimationFinished = nil
          c.Sprite:GetVar("animation"):SetString("shown_01")
        elseif not c.revealed then
          allRevealed = false
        end
      end
      if allRevealed then
        e:setNextState(STATES.POST_RESULTS)
      end
    end,
    onSkip = skipPackOpeningSequence,
    teardown = function(self, e)
      e.Fade.Touch.onTouchUp = nil
      for i = 1, #cardEntities do
        local c = cardEntities[i]
        c.Touch:GetVar("enabled"):SetInt(0)
        c.Touch.onTouchUp = nil
      end
    end
  },
  [STATES.POST_RESULTS] = {
    id = STATES.POST_RESULTS,
    setup = function(self, e)
      function e.Fade.Touch.onTouchUp(component, element)
        if e.particleDelay <= 0 then
          e:setState(STATES.OUTRO)
        end
      end
      e.TapTimer = 0
      e.BackButton:setInvisible()
      e.BackButton.Overlay:GetVar("visible"):SetInt(0)
      e.particleDelay = 0.05
      lua_sys.playSoundFx("audio/sfx/collect_stickerstars.wav")
    end,
    tick = function(self, e, dt)
      e.TapTimer = e.TapTimer + dt
      if e.Layout.Text:GetVar("visible"):GetInt() == 0 and e.TapTimer > TAP_TO_CONTINUE_DELAY then
        e.Layout.Text:GetVar("visible"):SetInt(1)
        e.LayoutTextTransition:SetAlpha(0)
        e.LayoutTextTransition:Show()
      end
      if 0 < e.particleDelay then
        e.particleDelay = e.particleDelay - dt
        if 0 >= e.particleDelay then
          for i = 1, #e.queuedParticles do
            local qp = e.queuedParticles[i]
            qp.card:hideStars()
            playCollectParticle(e, qp.card, qp.starsCollected)
          end
          e.queuedParticles = {}
        end
      end
    end,
    teardown = function(self, e)
      e.Fade.Touch.onTouchUp = nil
      e.LayoutTextTransition:Hide()
      e.queuedParticles = {}
    end
  },
  [STATES.OUTRO] = {
    id = STATES.OUTRO,
    setup = function(self, e)
      e:setAnimationForState(STATES.OUTRO)
      e.checkForOutroFinish = false
      lua_sys.playSoundFx("audio/sfx/menu_stickerbook_whoosh.wav")
    end,
    onAnimationFinished = function(self, e)
      e.checkForOutroFinish = true
    end,
    tick = function(self, e, dt)
      if e.checkForOutroFinish then
        e.checkForOutroFinish = false
        local playerCardAlbum = game.player():currentlyActiveCardAlbum()
        if playerCardAlbum ~= nil then
          if #e.cardPacks > 0 then
            e:setUpNextCardPack()
          else
            e:queuePop()
          end
        end
      end
    end
  }
}
function OpenCardPack:setState(stateName)
  if self.currentState and self.currentState.teardown then
    self.currentState:teardown(self)
  end
  self.currentState = states[stateName]
  if self.currentState and self.currentState.setup then
    self.currentState:setup(self)
  end
end
function OpenCardPack:setNextState(stateName)
  self.nextState = stateName
end
function OpenCardPack:setAnimationForState(state)
  local anim = getPackAnimation(self.packType, state)
  if anim then
    self.Layout.Sprite:GetVar("animation"):SetString(anim)
  end
end
function OpenCardPack:onPostInit()
  if game.getContextBar() then
    self.lastContext = game.getContextBar():getContext()
    game.getContextBar():setContext("BLANK")
  end
  self.eventOver = false
  self:SetupGenericListener(self.Layout.Sprite:GetReceiver(), "sys::msg::MsgAnimationFinished", "gotMsgAnimationFinished")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCardAlbumUpdated", "gotMsgCardAlbumUpdated")
  self.cardPacks = {}
  local playerCardAlbum = game.player():currentlyActiveCardAlbum()
  self.showAlbumRewards = false
  if playerCardAlbum ~= nil then
    local cardPacks = playerCardAlbum:getUncollectedCardPacks()
    for i = 0, cardPacks:size() - 1 do
      self.cardPacks[i + 1] = cardPacks[i]
    end
    if cardPacks:size() > 1 then
      self.showSkipAll = true
    end
    self:setUpNextCardPack()
    self.currency = playerCardAlbum:cardCurrency()
    self.targetCurrency = self.currency
    self:updateCurrency()
    self.showAlbumRewards = playerCardAlbum:willPacksCompleteAnyPage() or game.player():currentlyActiveCardAlbum():hasUncollectedRewards()
  end
  self.tickables = {}
  local availableHeight = lua_sys.screenHeight() * 0.6
  local layoutHeight = self.Layout.Sprite:absH()
  local layoutScaleFactor = availableHeight / layoutHeight
  self.Layout.Sprite:setScale(Vector2(layoutScaleFactor, layoutScaleFactor))
  self.Layout.Text:GetVar("visible"):SetInt(0)
  self.LayoutTextTransition = FadeTransition:new({
    duration = 1,
    onUpdate = function(alpha)
      self.Layout.Text:GetVar("alpha"):SetFloat(alpha)
    end,
    onDoneHide = function()
      self.Layout.Text:GetVar("visible"):SetInt(0)
    end
  })
  self.LayoutTextTransition:SetAlpha(0)
  table.insert(self.tickables, self.LayoutTextTransition)
  if self.showSkipAll then
    self.PacksRemaining.Sprite:GetVar("visible"):SetInt(1)
    self.PacksRemaining.Text:GetVar("visible"):SetInt(1)
    self.SkipAllButton:setVisible()
    self.SkipAllButton.Overlay:GetVar("visible"):SetInt(1)
  else
    self.PacksRemaining.Sprite:GetVar("visible"):SetInt(0)
    self.PacksRemaining.Text:GetVar("visible"):SetInt(0)
    self.SkipAllButton:setInvisible()
    self.SkipAllButton.Overlay:GetVar("visible"):SetInt(0)
  end
  self.queuedParticles = {}
  self.flyingIcons = {}
end
function OpenCardPack:onDestroy()
  for i = #self.flyingIcons, 1, -1 do
    self.flyingIcons[i].isDead = true
  end
end
function OpenCardPack:setUpNextCardPack()
  self.PacksRemaining.Text:GetVar("text"):SetString(tostring(#self.cardPacks))
  if #self.cardPacks > 0 then
    local unopenedPack = self.cardPacks[1]
    self.packId = unopenedPack:getId()
    self.packType = unopenedPack:getCardPackType()
    self.packContents = {}
    local packContents = unopenedPack:getCards()
    for i = 0, packContents:size() - 1 do
      local cardId = packContents[i]
      local cardData = game.getCardData(cardId)
      table.insert(self.packContents, cardData)
    end
    local packTypeStr = CardPackTypeStr[unopenedPack:getCardPackType()]
    print("Pack ID:", self.packId)
    print("Pack Type:", packTypeStr)
    print("Pack Contents:")
    for i = 1, #self.packContents do
      local card = self.packContents[i]
      print(" - Card ID:", card.id, "Rarity:", CardRarityStr[card.rarity], "Asset Path:", card.assetPath)
    end
    self:setup()
  end
end
function OpenCardPack:setup()
  self.revealedCards = {}
  self.animUtil = game.AnimUtil(self.Layout.Sprite)
  self.animUtil:clearAttachedAnims()
  for i, entity in ipairs(cardEntities) do
    self:RemoveElement(entity)
  end
  cardEntities = {}
  print("setting up remap for pack type:", self.packType)
  self.animUtil:addSheetRemap("sticker_pack_common_sheet.xml", packRemaps[self.packType])
  createCardEntities(self, self.packContents)
  for i = 1, #cardEntities do
    local cardName = "CARD_0" .. i
    self.animUtil:addRemap(cardName, "empty.xml", "empty")
  end
  self.animUtil:resetAnim()
  if self.packId and self.packType then
    self:setState(STATES.INTRO)
  end
end
function OpenCardPack:hidePack()
  self.Layout.Sprite:V("visible"):SetInt(0)
  self.Layout.Text:V("visible"):SetInt(0)
end
function OpenCardPack:queuePop()
  self:root():removePopUp(self:name())
  if game.getContextBar() and self.lastContext then
    game.getContextBar():setContext(self.lastContext)
  end
  if self.showAlbumRewards then
    if game.player():currentlyActiveCardAlbum():hasUncollectedPageRewards() then
      game.pushPopUp("card_album_page_reward_collect")
      return
    elseif game.player():currentlyActiveCardAlbum():hasUncollectedAlbumRewards() then
      game.pushPopUp("card_album_reward_collect")
      return
    end
  end
  if game.hasDoubleEncoreRewardTrackAvailable() then
    game.pushPopUp("popup_extra_encore_rewards")
    return
  end
end
function OpenCardPack:packSelected()
  print("open pack")
  self:openCardPack()
end
function OpenCardPack:openCardPack()
  table.remove(self.cardPacks, 1)
  game.openCardPack(self.packId)
end
function OpenCardPack:cardSelected(card)
  table.insert(self.revealedCards, card.packIndex)
  local starsCollected = 0
  if card.isNew then
    lua_sys.playSoundFx("audio/sfx/sticker_reveal_new.ogg")
  else
    local currency = game.cardRarityToCurrencyConversion(self.packContents[card.packIndex].rarity)
    starsCollected = currency
  end
  return starsCollected
end
function OpenCardPack:updateCurrency()
  self.CurrencyCounter:C("Text"):V("text"):SetString(game.commaizeNumber(self.currency))
end
function OpenCardPack:skip()
  if self.currentState and self.currentState.onSkip then
    self.currentState:onSkip(self)
  else
    self:root():removePopUp(self:name())
  end
end
function OpenCardPack:skipAll()
  local playerCardAlbum = game.player():currentlyActiveCardAlbum()
  if playerCardAlbum ~= nil and #self.cardPacks > 0 then
    local list = game.M_int()
    for i = 1, #self.cardPacks do
      list:push_back(self.cardPacks[i]:getId())
    end
    game.openAllCardPacks(list)
  end
  self:root():removePopUp(self:name())
end
function OpenCardPack:gotMsgAnimationFinished(msg)
  if self.currentState and self.currentState.onAnimationFinished then
    self.currentState:onAnimationFinished(self)
  end
end
function OpenCardPack:gotMsgCardAlbumUpdated(msg)
end
function OpenCardPack:attachCardToPack(id)
  local animUtil = self.animUtil
  local cardName = "CARD_0" .. id
  if animUtil:hasLayer(cardName) then
    local cardEntity = cardEntities[id]
    cardEntity.revealed = false
    cardEntity.Sprite:GetVar("visible"):SetInt(1)
    cardEntity.Sprite:GetVar("animation"):SetString("hidden_01")
    animUtil:attachMenuAnim(cardName, cardEntity.Sprite)
    cardEntity.Touch:GetVar("enabled"):SetInt(0)
    cardEntity.packIndex = id
  end
  self:updateCardEntity(id)
end
function OpenCardPack:doTest()
  print("Doing Test!")
  self.packId = 1
  self.packType = game.CardPackType_Uncommon
  self.packContents = {
    {
      id = 21,
      rarity = game.CardRarity_FourStar,
      assetPath = "gfx/menu/cards/sticker_21"
    },
    {
      id = 22,
      rarity = game.CardRarity_FiveStarGold,
      assetPath = "gfx/menu/cards/sticker_22"
    }
  }
  self:setup()
end
function OpenCardPack:updateCardEntity(id)
  local scaleX = 0.46875
  local scaleY = 0.39473684210526316
  local cardName = "CARD_0" .. id
  if self.animUtil and self.animUtil:hasLayer(cardName) then
    local cardEntity = cardEntities[id]
    local cardSize = self.animUtil:getSize(cardName)
    local worldPos = self.animUtil:getWorldPos(cardName)
    local worldScale = self.animUtil:getWorldScale(cardName)
    cardEntity.Touch:GetVar("width"):SetFloat(cardSize.x * worldScale.x * scaleX)
    cardEntity.Touch:GetVar("height"):SetFloat(cardSize.y * worldScale.y * scaleY)
    cardEntity.Touch:setPosition(Vector2(worldPos.x + cardSize.x * worldScale.x * (1 - scaleX) * 0.5, worldPos.y + cardSize.y * worldScale.y * (1 - scaleY) * 0.5))
  end
end
function OpenCardPack:onTick(dt)
  if self.eventOver == false and game.getCurrentCardAlbumEvent() == nil then
    self.eventOver = true
    self:queuePop()
  end
  if self.nextState then
    self:setState(self.nextState)
    self.nextState = nil
  end
  for i = 1, #cardEntities do
    self:updateCardEntity(i)
  end
  if self.currentState and self.currentState.tick then
    self.currentState:tick(self, dt)
  end
  for _, tickable in ipairs(self.tickables) do
    if tickable.Tick then
      tickable:Tick(dt)
    end
  end
  if self.targetCurrency > self.currency then
    self.currency = self.currency + 1
    self:updateCurrency()
  end
end
return OpenCardPack
