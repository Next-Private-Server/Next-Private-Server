local ScrollingListHelper = include("ScrollingListHelper")
local MenuHelpers = include("MenuHelpers")
local OffsetTransition = include("OffsetTransition")
local FadeTransition = include("FadeTransition")
local ITEMS_PER_ROW = 3
local MAX_CARDS_PER_PAGE = 10
local TRANSITION_TIME = 0.33
local CardAlbum = {
  BGPattern = {},
  BGGradient = {},
  PageNameText = {
    Text = {}
  },
  PageNumText = {
    Text = {}
  },
  AlbumPanel = {
    TitleFrame = {},
    TitleText = {},
    Timer = {
      Text = {}
    },
    Banner = {},
    RewardFrame = {
      RewardList = {},
      Text = {}
    },
    Bar = {
      BarBackingSprite = {},
      BarSprite = {},
      BarIcon = {},
      BarText = {},
      CollectButton = {},
      CollectedText = {},
      Notification = {}
    },
    InfoButton = {},
    StoreButton = {
      CurrencyText = {}
    }
  },
  PageInfoPanel = {
    PageBar = {
      BarBackingSprite = {},
      BarSprite = {},
      BarText = {},
      CollectButton = {},
      CollectedText = {},
      Notification = {}
    },
    CollectButton = {}
  },
  PagePanel = {
    AlbumList = {
      Touch = {},
      Swiper = {}
    }
  },
  Album = {
    Anim = {}
  },
  CardPanel = {},
  PreviousButton = {},
  NextButton = {},
  BackButton = {},
  TestButton = {},
  OpenPacksButton = {}
}
function CardAlbum:onInit()
  self.AlbumPanel.albumRewardElements = {
    self.AlbumPanel.RewardList.Reward1,
    self.AlbumPanel.RewardList.Reward2
  }
  self.pageRewardElements = {
    self.PageInfoPanel.RewardList.Reward1,
    self.PageInfoPanel.RewardList.Reward2
  }
  if game.testCardAlbumEnabled() == false then
    self.TestButton:Hide()
    self.OpenPacksButton:Hide()
  end
end
function CardAlbum:onPostInit()
  self.tickables = {}
  self.cardAlbumEvent = game.getCurrentCardAlbumEvent()
  self.playerCardAlbum = game.player():currentlyActiveCardAlbum()
  self.cardAlbum = game.getCardAlbumData(self.cardAlbumEvent:getCardAlbumId())
  game.player():setLastViewedCardAlbum(self.playerCardAlbum:cardAlbumId(), self.playerCardAlbum:eventStartTime())
  self.exit = false
  self.eventOver = false
  self.numCards = 0
  self.pages = self.cardAlbum:getPages()
  self.AlbumPanel.TitleText.Text:V("text"):SetString(game.localizedUpper(self.cardAlbum.name))
  self.cardView = false
  self.openingAlbum = false
  self.closingAlbum = false
  self.collectingReward = false
  self:SetupFancyBG()
  self:populateAlbumRewards(self.cardAlbum.rewards, {}, self.AlbumPanel.albumRewardElements)
  self.pageEntries = {}
  self:populatePageEntries()
  self.PageInfoPanel.PageBar.CollectButton:setInvisible()
  self.PageInfoPanel.PageBar.CollectButton:disable()
  self.startTime = game.serverTime()
  local animUtil = game.AnimUtil(self.Album.Anim)
  self.cardElements = {}
  for i = 1, MAX_CARDS_PER_PAGE do
    local cardName = "CARD_" .. string.format("%02d", i)
    local card = menu:addTemplateElement("template_card", cardName, self.Album)
    card("CardId"):SetInt(i)
    card:init()
    card:setPositionBroadcast(true)
    card:postInit()
    card:setInvisible()
    self.cardElements[i] = card
    if animUtil:hasLayer(cardName) then
      animUtil:attachMenuAnim(cardName, card.Sprite)
    end
  end
  animUtil:resetAnim()
  lua_sys.playSoundFx("audio/sfx/menu_stickers_open.ogg")
  self:refresh()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCardAlbumUpdated", "gotMsgCardAlbumUpdated")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCardAbumRewardCollected", "gotMsgCardAbumRewardCollected")
  self:SetupGenericListener(self.Album.Anim:GetReceiver(), "sys::msg::MsgAnimationFinished", "gotMsgAnimationFinished")
  self:SetupTransitions()
  self:showPages()
  self:hideCards()
end
function CardAlbum:SetupTransitions()
  self.AlbumPanel.Transition = OffsetTransition:new({
    startX = lua_sys.screenWidth() * 1,
    startY = self.PagePanel:GetVar("yOffset"):GetFloat(),
    endX = 70 * game.windowScaleY(),
    endY = self.PagePanel:GetVar("yOffset"):GetFloat(),
    duration = TRANSITION_TIME,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y)
      self.AlbumPanel:GetVar("xOffset"):SetFloat(x)
      self.AlbumPanel:GetVar("yOffset"):SetFloat(y)
    end,
    onDoneHide = function()
      if self.exit or self.eventOver then
        self:root():removePopUp(self:name())
        manager:setContext(manager:getDefaultContext())
      else
        self:showCards()
      end
    end
  })
  table.insert(self.tickables, self.AlbumPanel.Transition)
  self.PagePanel.Transition = OffsetTransition:new({
    startX = lua_sys.screenWidth() * 1,
    startY = self.PagePanel:GetVar("yOffset"):GetFloat(),
    endX = -70 * game.windowScaleY(),
    endY = self.PagePanel:GetVar("yOffset"):GetFloat(),
    duration = TRANSITION_TIME,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y)
      self.PagePanel:GetVar("xOffset"):SetFloat(x)
      self.PagePanel:GetVar("yOffset"):SetFloat(y)
    end
  })
  table.insert(self.tickables, self.PagePanel.Transition)
  self.PageInfoFadeTransition = FadeTransition:new({
    duration = TRANSITION_TIME,
    onUpdate = function(alpha)
      for i = 1, #self.pageRewardElements do
        self.pageRewardElements[i]:updateAlpha(alpha)
      end
      self.PageNameText.Text:V("alpha"):SetFloat(alpha)
      self.PageNameText.Sprite:V("alpha"):SetFloat(alpha)
      self.PageNumText.Text:V("alpha"):SetFloat(alpha)
      self.PageInfoPanel.Text:V("alpha"):SetFloat(alpha)
      self.PageInfoPanel.PageBar:setAlpha(alpha)
      self.PreviousButton.Arrow:V("alpha"):SetFloat(alpha)
      self.NextButton.Arrow:V("alpha"):SetFloat(alpha)
    end,
    onDoneShow = function()
      self.PreviousButton.Touch:V("enable"):SetInt(1)
      self.NextButton.Touch:V("enable"):SetInt(1)
      self.BackButton:Enable()
    end,
    onHide = function()
      self.PreviousButton.Touch:V("enable"):SetInt(0)
      self.NextButton.Touch:V("enable"):SetInt(0)
    end
  })
  table.insert(self.tickables, self.PageInfoFadeTransition)
end
function CardAlbum:SetupFancyBG()
  local scrollingBG = self.BGPattern.Sprite
  local gradientBG = self.BGGradient.Sprite
  local targetWidth = lua_sys.screenWidth()
  local targetHeight = lua_sys.screenHeight()
  scrollingBG:setScale(lua_sys.Vector2(targetWidth / 128, targetHeight / 128))
  scrollingBG:GetVar("layer"):SetString("MidPopUps")
  scrollingBG:GetVar("alpha"):SetFloat(1)
  scrollingBG:GetVar("repeating"):SetInt(1)
  scrollingBG:setShader(include("ShaderCardAlbum"))
  gradientBG:setScale(lua_sys.Vector2(targetWidth / 1024, targetHeight / 4))
  gradientBG:GetVar("layer"):SetString("MidPopUps")
  gradientBG:GetVar("spriteName"):SetString("gfx/menu/gradient_bg_breeding")
  scrollingBG:GetVar("spriteName"):SetString("gfx/menu/bg_symbols_stickers")
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
end
function CardAlbum.PagePanel.AlbumList:onInit()
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 0 * game.windowScaleY(),
    padding = 0 * game.windowScaleY()
  })
  self:V("Refresh"):SetInt(0)
end
function CardAlbum:onTick(dt)
  local secsRemaining = self.cardAlbumEvent:timeRemainingSec()
  if secsRemaining > 0 then
    self.AlbumPanel.Timer.Text:V("text"):SetString(game.timeToString(secsRemaining))
  elseif game.topPopUp() == self and self.eventOver == false then
    self.eventOver = true
    self:close()
  end
  for _, tickable in ipairs(self.tickables) do
    if tickable.Tick then
      tickable:Tick(dt)
    end
  end
end
function CardAlbum.PagePanel.AlbumList:onTick(dt)
  ScrollingListHelper.ListTick(self, dt)
  if self:V("Refresh"):GetInt() == 1 then
    self.Swiper:refresh(self)
    self:V("Refresh"):SetInt(0)
  end
end
function CardAlbum.PagePanel.AlbumList:updateClipping()
  local clipX = self:absX()
  local clipY = self:absY() + 9 * game.windowScaleY()
  local clipW = self:absW()
  local clipH = self:absH() - 18 * game.windowScaleY()
  if self.clipX ~= clipX or self.clipY ~= clipY or self.clipW ~= clipW or self.clipH ~= clipH then
    self.clipX = clipX
    self.clipY = clipY
    self.clipW = clipW
    self.clipH = clipH
    MenuHelpers.ForEachEntry(self, function(entry)
      entry:SetClipping(clipX, clipY, clipW, clipH)
    end)
  end
end
function CardAlbum.PagePanel.AlbumList.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function CardAlbum.PagePanel.AlbumList.Swiper:onTick(element, dt)
  ScrollingListHelper.SwiperTick(self, element, dt)
end
function CardAlbum:queuePop()
  self:back()
end
function CardAlbum:populatePageEntries()
  local albumList = self.PagePanel.AlbumList
  local spacingX = 10 * game.windowScaleY()
  local spacingY = 10 * game.windowScaleY()
  local startY = spacingY
  local startX = spacingX * 0.5
  local offset = startY
  local offsetX = startX
  for i = 1, self.pages:size() do
    local item = menu:addTemplateElement("template_card_album_page_entry", "entry" .. i - 1, albumList)
    item:setOrientation(lua_sys.MenuOrientation(0, offset, -2, lua_sys.LEFT, lua_sys.TOP))
    item:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
    item("ItemId"):SetInt(i - 1)
    item:init()
    item.pageData = self.pages[i - 1]
    item.pageNum = i
    item:setPositionBroadcast(true)
    item:postInit()
    if i == 1 then
    elseif (i - 1) % ITEMS_PER_ROW == 0 then
      offset = offset + item:absH() + spacingY
      if albumList.minSize == 0 or item:absH() < albumList.minSize then
        albumList.minSize = item:absH()
      end
      offsetX = startX
    else
      offsetX = offsetX + item:absW() + spacingX
    end
    item("xOffset"):SetFloat(offsetX)
    item("listOffset"):SetFloat(offset)
    if i == self.pages:size() then
      offset = offset + item:absH() + spacingY
    end
    table.insert(self.pageEntries, item)
  end
  albumList("totalSize"):SetFloat(offset)
  albumList:V("Refresh"):SetInt(1)
end
local GetTestRewards = function()
  local rewards = {}
  table.insert(rewards, {
    id = 0,
    type = 4,
    amount = 500
  })
  table.insert(rewards, {
    type = 13,
    id = 23,
    amount = 1
  })
  return rewards
end
function CardAlbum:populateAlbumRewards(rewards, options, rewardElements)
  rewards = rewards or GetTestRewards()
  options = options or {}
  local numRewards
  if type(rewards) == "table" then
    numRewards = #rewards
  else
    numRewards = rewards:size()
  end
  local index = 0
  if type(rewards) == "table" then
    index = index + 1
  end
  for i = 1, #rewardElements do
    if i <= numRewards then
      local rewardData = rewards[index]
      rewardElements[i]:Init(rewardData, i, options)
      index = index + 1
    end
  end
end
function CardAlbum:hidePages()
  self.AlbumPanel.Transition:Hide()
  self.PagePanel.Transition:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_stickerbook_whoosh.wav")
  for i = 1, #self.pageEntries do
    self.pageEntries[i]:disableTouch()
  end
  self.AlbumPanel.InfoButton:disable()
  self.AlbumPanel.StoreButton:disable()
  self.AlbumPanel.Bar.CollectButton:disable()
  if game.testCardAlbumEnabled() then
    self.TestButton:Hide()
    self.OpenPacksButton:Hide()
  end
  self.BackButton:Disable()
end
function CardAlbum:showPages()
  self:refreshAlbumCompletionState()
  self.AlbumPanel.Transition:Show()
  self.PagePanel.Transition:Show()
  lua_sys.playSoundFx("audio/sfx/menu_stickerbook_whoosh.wav")
  for i = 1, #self.pageEntries do
    self.pageEntries[i]:enableTouch()
  end
  self.AlbumPanel.InfoButton:enable()
  self.AlbumPanel.StoreButton:enable()
  if game.testCardAlbumEnabled() then
    self.TestButton:Show()
    self.OpenPacksButton:Show()
  end
end
function CardAlbum:showCards()
  self.Album.Anim:V("visible"):SetInt(1)
  self.Album.Anim("animation"):SetString("sticker_book_intro")
  self.openingAlbum = true
  lua_sys.playSoundFx("audio/sfx/menu_stickerbook_open.ogg")
  self.Album.Anim:Play()
end
function CardAlbum:hideCards()
  self.PageInfoFadeTransition:SetAlpha(0)
  lua_sys.playSoundFx("audio/sfx/menu_stickerbook_close.ogg")
  self.Album.Anim("animation"):SetString("sticker_book_outro")
  self.closingAlbum = true
end
function CardAlbum:showNextCardPage()
  if self.currentPageNum < self.pages:size() then
    self.currentPageNum = self.currentPageNum + 1
    self.currentPage = self.pages[self.currentPageNum - 1]
  else
    self.currentPage = self.pages[0]
    self.currentPageNum = 1
  end
  self:refreshPageCompletionState()
  self:refreshCardView()
  lua_sys.playSoundFx(string.format("audio/sfx/menu_stickerbook_pagechange_%02d.wav", math.random(1, 3)))
end
function CardAlbum:showPrevCardPage()
  if self.currentPageNum > 1 then
    self.currentPageNum = self.currentPageNum - 1
    self.currentPage = self.pages[self.currentPageNum - 1]
  else
    self.currentPage = self.pages[self.pages:size() - 1]
    self.currentPageNum = self.pages:size()
  end
  self:refreshCardView()
  lua_sys.playSoundFx(string.format("audio/sfx/menu_stickerbook_pagechange_%02d.wav", math.random(1, 3)))
end
function CardAlbum:selectPage(page)
  self.currentPage = page.pageData
  self.currentPageNum = page.pageNum
  self.cardView = true
  lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
  self:hidePages()
  self:refreshCardView()
  self.PageInfoFadeTransition:SetAlpha(0)
end
function CardAlbum:refresh()
  self.AlbumPanel.StoreButton:C("CurrencyText"):V("text"):SetString(self.playerCardAlbum:cardCurrency())
  local totalCards = self.cardAlbum:numCards()
  local totalCardsCollected = self.playerCardAlbum:numCardsCollected()
  local barText = totalCardsCollected .. "/" .. totalCards
  self.AlbumPanel.Bar.BarText:V("text"):SetString(barText)
  local percentage = totalCardsCollected / totalCards
  self.AlbumPanel.Bar.BarSprite:V("maskWidth"):SetFloat(self.AlbumPanel.Bar.BarSprite:V("FullMaskW"):GetInt() * clamp(percentage, 0, 1))
  if self.cardView then
    self:refreshCardView()
  else
    self:refreshAlbumCompletionState()
  end
end
function CardAlbum:refreshAlbumCompletionState()
  if self.playerCardAlbum:hasCollectedAlbumRewards() then
    self.AlbumPanel.Bar:setVisible(0)
    self.AlbumPanel.Bar.CollectButton:setInvisible()
    self.AlbumPanel.Bar.CollectButton:disable()
    self.AlbumPanel.Bar.Notification:V("visible"):SetInt(0)
    self.AlbumPanel.Bar.CollectedText:V("visible"):SetInt(1)
  elseif self.playerCardAlbum:isAlbumComplete() then
    self.AlbumPanel.Bar:setVisible(0)
    self.AlbumPanel.Bar.CollectButton:enable()
    self.AlbumPanel.Bar.CollectButton:setVisible()
    self.AlbumPanel.Bar.Notification:V("visible"):SetInt(1)
    self.AlbumPanel.Bar.CollectedText:V("visible"):SetInt(0)
  else
    self.AlbumPanel.Bar:setVisible(1)
    self.AlbumPanel.Bar.CollectButton:setInvisible()
    self.AlbumPanel.Bar.CollectButton:disable()
    self.AlbumPanel.Bar.Notification:V("visible"):SetInt(0)
    self.AlbumPanel.Bar.CollectedText:V("visible"):SetInt(0)
  end
  for i = 1, #self.pageEntries do
    self.pageEntries[i]:refresh()
  end
end
function CardAlbum:refreshPageCompletionState()
  if self.playerCardAlbum:hasCollectedPageRewards(self.currentPage:getId()) then
    self.PageInfoPanel.PageBar:setVisible(0)
    self.PageInfoPanel.PageBar.CollectButton:setInvisible()
    self.PageInfoPanel.PageBar.CollectButton:disable()
    self.PageInfoPanel.PageBar.Notification:V("visible"):SetInt(0)
    self.PageInfoPanel.PageBar.CollectedText:V("visible"):SetInt(1)
  elseif self.playerCardAlbum:isPageComplete(self.currentPage:getId()) then
    self.PageInfoPanel.PageBar:setVisible(0)
    self.PageInfoPanel.PageBar.CollectButton:enable()
    self.PageInfoPanel.PageBar.CollectButton:setVisible()
    self.PageInfoPanel.PageBar.Notification:V("visible"):SetInt(1)
    self.PageInfoPanel.PageBar.CollectedText:V("visible"):SetInt(0)
  else
    self.PageInfoPanel.PageBar:setVisible(1)
    self.PageInfoPanel.PageBar.CollectButton:setInvisible()
    self.PageInfoPanel.PageBar.CollectButton:disable()
    self.PageInfoPanel.PageBar.Notification:V("visible"):SetInt(0)
    self.PageInfoPanel.PageBar.CollectedText:V("visible"):SetInt(0)
  end
end
function CardAlbum.AlbumPanel:setVisible(visible)
  self.TitleFrame.Sprite:V("visible"):SetInt(visible)
  self.TitleText.Text:V("visible"):SetInt(visible)
  self.Timer.Text:V("visible"):SetInt(visible)
  self.Timer.Sprite:V("visible"):SetInt(visible)
  self.Banner.Sprite:V("visible"):SetInt(visible)
  self.RewardFrame.Sprite:V("visible"):SetInt(visible)
  self.RewardFrame.Text:V("visible"):SetInt(visible)
  for i = 1, #self.albumRewardElements do
    self.albumRewardElements[i]:setVisible(visible)
  end
  self.Bar:setVisible(visible)
end
function CardAlbum.AlbumPanel.Bar:setVisible(visible)
  self.BarText:V("visible"):SetInt(visible)
  self.BarSprite:V("visible"):SetInt(visible)
  self.BarBackingSprite:V("visible"):SetInt(visible)
  self.BarIcon:V("visible"):SetInt(visible)
end
function CardAlbum.PageInfoPanel.PageBar:setVisible(visible)
  self.BarText:V("visible"):SetInt(visible)
  self.BarSprite:V("visible"):SetInt(visible)
  self.BarBackingSprite:V("visible"):SetInt(visible)
end
function CardAlbum.PageInfoPanel.PageBar:setAlpha(alpha)
  self.BarText:V("alpha"):SetFloat(alpha)
  self.BarSprite:V("alpha"):SetFloat(alpha)
  self.BarBackingSprite:V("alpha"):SetFloat(alpha)
  self.CollectButton:V("alpha"):SetFloat(alpha)
  self.CollectButton:updateComponents()
  self.Notification:V("alpha"):SetInt(alpha)
  self.CollectedText:V("alpha"):SetFloat(alpha)
end
function CardAlbum:refreshCardView()
  self.PageNameText.Text:V("text"):SetString(game.localizedUpper(self.currentPage:getName()))
  local text = LOC("CARD_ALBUM_PAGE_NUM")
  text = text:gsub("%${NUM}", self.currentPageNum)
  self.PageNumText.Text:V("text"):SetString(text)
  local numCardsCollected = self.playerCardAlbum:numCardsCollectedOnPage(self.currentPage:getId())
  local totalCards = self.currentPage:getCards():size()
  self.PageInfoPanel.PageBar.BarText:V("text"):SetString(numCardsCollected .. "/" .. totalCards)
  local percentage = numCardsCollected / totalCards
  self.PageInfoPanel.PageBar.BarSprite:V("maskWidth"):SetFloat(self.PageInfoPanel.PageBar.BarSprite:V("FullMaskW"):GetInt() * clamp(percentage, 0, 1))
  self:populateAlbumRewards(self.currentPage:getRewards(), {}, self.pageRewardElements)
  self:refreshPageCompletionState()
  local cards = self.currentPage:getCards()
  self.numCards = cards:size()
  for i = 0, cards:size() - 1 do
    do
      local cardId = cards[i]
      local card = self.cardElements[i + 1]
      local isLocked = self.playerCardAlbum:hasCard(cardId) == false
      local cardData = game.getCardData(cardId)
      local isNew = isLocked == false and game.player():hasViewedCard(cardId) == false
      card:Setup(cardData, isNew, isLocked)
      if isLocked then
        card.Touch.onTouchUp = nil
      else
        function card.Touch.onTouchUp()
          self:selectCard(cardData)
        end
      end
      if isNew then
        game.player():setCardViewed(cardId)
      end
      card:setVisible()
    end
  end
  game.player():updateCardsViewed()
end
function CardAlbum:selectCard(cardData)
  local menu = game.pushPopUp("card_album_card_popup")
  menu:Setup(cardData)
end
function CardAlbum:back()
  if self.cardView then
    self:hideCards()
    self:showPages()
    self.cardView = false
    self:refresh()
  elseif self.exit == false then
    self.exit = true
    self:close()
  end
end
function CardAlbum:close()
  if self.cardView then
    self:hideCards()
  else
    self.AlbumPanel.Transition:Hide()
    self.PagePanel.Transition:Hide()
  end
  if self.BGFadeTransition then
    self.BGFadeTransition:Hide()
  end
  if self.startTime ~= nil then
    game.logEvent("card_album", "time_spent_secs", (game.serverTime() - self.startTime) / 1000, "cards_collected", self.playerCardAlbum:numCardsCollected())
    self.startTime = 0
    lua_sys.playSoundFx("audio/sfx/menu_stickers_close.ogg")
  end
end
function CardAlbum:testCardPack()
  game.testCardPack(game.CardPackType_Legendary)
end
function CardAlbum:openCardPacks()
  game.pushPopUp("open_card_pack")
end
function CardAlbum:collectAlbumReward()
  if game.getCurrentCardAlbumEvent() ~= nil then
    game.collectCardAlbumRewards(game.getCurrentCardAlbumEvent():getCardAlbumId())
    self.collectingReward = true
  end
end
function CardAlbum:collectPageReward()
  if game.getCurrentCardAlbumEvent() ~= nil then
    game.collectCardAlbumPageRewards(game.getCurrentCardAlbumEvent():getCardAlbumId(), self.currentPage:getId())
    self.collectingReward = true
  end
end
function CardAlbum:showStore()
  game.pushPopUp("card_album_store")
end
function CardAlbum:showInfo()
  game.pushPopUp("card_album_how_it_works")
end
function CardAlbum:gotMsgCardAlbumUpdated(msg)
  self:refresh()
end
function CardAlbum:gotMsgCardAbumRewardCollected(msg)
  if self.collectingReward then
    local popup = game.pushPopUp("popup_store_bundle_rewards")
    popup:Setup(msg:rewards())
    self.collectingReward = false
  end
end
function CardAlbum:gotMsgAnimationFinished(msg)
  if self.openingAlbum then
    self:refreshPageCompletionState()
    self.PageInfoFadeTransition:Show()
    self.openingAlbum = false
  elseif self.closingAlbum then
    self.closingAlbum = false
    if self.exit or self.eventOver then
      self:root():removePopUp(self:name())
      manager:setContext(manager:getDefaultContext())
    end
  end
end
return CardAlbum
