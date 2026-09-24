local StoreCategorySelect = {
  bg = {
    Sprite = {},
    Touch = {}
  },
  TitleFrame = {
    Sprite = {},
    Text = {},
    LeftEnd = {},
    RightEnd = {}
  },
  MonstersButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  CostumesButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  StructuresButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  DecorationsButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  CurrencyButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  StarpowerButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  IslandsButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  WebstoreButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  AdButton = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  BackButton = {
    Touch = {},
    Overlay = {},
    Text = {}
  },
  RemoveAdsLabel = {
    Text = {}
  }
}
local root
function StoreCategorySelect:onInit()
  root = self
  self.ButtonStatus = {
    monsters = true,
    costumes = true,
    structures = true,
    decorations = true,
    currency = true,
    starpower = true,
    islands = true,
    webstore = true,
    ad = true
  }
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfo", "gotMsgPlacementInfo")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfoFail", "gotMsgPlacementInfoFail")
  game.loadNewsFlash("market_xwebstore_button")
end
function StoreCategorySelect:gotMsgPlacementInfo(msg)
  if msg.name == "market_xwebstore_button" then
    local placement = game.nativePlacement(msg.name)
    if placement ~= nil then
      local ad = placement:getAd(0)
      if ad ~= nil then
        ad:reportImpression()
        self:GetVar("placement"):SetString(msg.name)
        ad:applyMainTo(self.WebstoreButton.Sprite)
        if ad:getAction() ~= "" then
          self.WebstoreButton.Text:GetVar("text"):SetString(ad:getAction())
        else
          self.WebstoreButton.Text:GetVar("text"):SetString(ad:getTitle())
        end
        self.IslandsButton:setInvisible()
        self.WebstoreButton:setVisible()
        local clickUrl = ad:getClickURL(0)
        if clickUrl ~= nil then
          local saleTag = clickUrl:find("saletag=1")
          if saleTag ~= nil then
            self.WebstoreButton:attachSaleIndicator()
          end
        end
        self.IslandsButton:setInvisible()
        self.WebstoreButton:setVisible()
      end
    end
  end
end
function StoreCategorySelect:gotMsgPlacementInfoFail(msg)
  if msg.name == "market_xwebstore_button" then
    self.WebstoreButton:setInvisible()
    self.IslandsButton:setVisible()
  end
end
function StoreCategorySelect:onPostInit()
  self:UpdateButtonStatus()
end
function StoreCategorySelect:RefreshButtons()
  local initButton = function(button, label, spriteName, enabled, buttonActionEnabled, buttonActionDisabled, canAttachTemplate)
    button.Text:GetVar("text"):SetString(label)
    button.Sprite:GetVar("spriteName"):SetString("gfx/menu/" .. spriteName)
    button.buttonEnabled = enabled
    if enabled then
      button:enable()
    else
      button:disable(false)
    end
    button.buttonActionEnabled = buttonActionEnabled
    button.buttonActionDisabled = buttonActionDisabled
    button.canAttachTemplate = canAttachTemplate
    button:attachSaleIndicator()
  end
  initButton(self.MonstersButton, "STORE_MONSTER", "store_button_monsters", self.ButtonStatus.monsters, function()
    self:onStoreButtonPressed(game.StoreCategories_TYPE_MONSTER)
  end, nil, function()
    return game.activeEventForCategory(game.StoreCategories_TYPE_MONSTER)
  end)
  initButton(self.CostumesButton, "STORE_COSTUMES", "store_button_costumes", self.ButtonStatus.costumes, function()
    self:onStoreButtonPressed(game.StoreCategories_TYPE_COSTUMES)
  end, function()
    self:displayCostumesLockedPopup()
  end, function()
    return game.activeEventForCategory(game.StoreCategories_TYPE_COSTUMES)
  end)
  initButton(self.StructuresButton, "STORE_STRUCTURES", "store_button_structures", self.ButtonStatus.structures, function()
    self:onStoreButtonPressed(game.StoreCategories_TYPE_STRUCTURE)
  end, function()
    self:displayStructuresLockedPopup()
  end, function()
    return game.activeEventForCategory(game.StoreCategories_TYPE_STRUCTURE)
  end)
  initButton(self.DecorationsButton, "STORE_DECORATIONS", "store_button_decorations", self.ButtonStatus.decorations, function()
    self:onStoreButtonPressed(game.StoreCategories_TYPE_DECORATION)
  end, function()
    self:displayDecorationsLockedPopup()
  end, function()
    return game.activeEventForCategory(game.StoreCategories_TYPE_DECORATION)
  end)
  initButton(self.CurrencyButton, "STORE_CURRENCY", "store_button_currency", self.ButtonStatus.currency, function()
    self:onStoreButtonPressed(game.StoreCategories_TYPE_CURRENCY)
  end, nil, function()
    return game.activeEventForCategory(game.StoreCategories_TYPE_CURRENCY)
  end)
  initButton(self.StarpowerButton, "STORE_STARPOWER", "store_button_starshop", self.ButtonStatus.starpower, function()
    self:onStoreButtonPressed(game.StoreCategories_TYPE_STARPOWER)
  end, function()
    self:displayStarpowerLockedPopup()
  end, function()
    return game.activeEventForCategory(game.StoreCategories_TYPE_STARPOWER)
  end)
  initButton(self.IslandsButton, "STORE_ISLANDS", "store_button_islands", self.ButtonStatus.islands, function()
    self:onStoreButtonPressed(game.StoreCategories_TYPE_ISLAND)
  end, nil, function()
    return game.activeEventForCategory(game.StoreCategories_TYPE_ISLAND)
  end)
  if not self.ButtonStatus.costumes then
    self.CostumesButton:detachSaleIndicator()
  end
  if game.playerLevel() < 4 then
    self.DecorationsButton:disable()
    self.CurrencyButton:disable()
    self.IslandsButton:disable()
  end
end
function StoreCategorySelect:UpdateButtonStatus()
  if game.playerLevel() < 10 and game.numIslands() == 1 or game.isComposerIsland() or game.isCelestialIsland() or game.isAmberIsland() or game.isEtherealAtelierIsland() or game.isBattleIsland() or game.isMagicalNexusIsland() or game.isEtherealIslet() then
    self.ButtonStatus.starpower = false
  end
  if game.isComposerIsland() or game.isBattleIsland() or game.isMagicalNexusIsland() or game.isEtherealIslet() or game.isPaironormalIsland() then
    self.ButtonStatus.structures = game.isAdmin()
  end
  if game.playerLevel() < 4 or game.isComposerIsland() or game.isMagicalNexusIsland() or game.isEtherealIslet() then
    self.ButtonStatus.decorations = false
  end
  if game.playerLevel() < 4 then
    self.ButtonStatus.currency = false
  end
  local numCostumesAvail = game.getPurchaseableCostumesForActiveIsland()
  self.CostumesButton:GetVar("numCostumes"):SetInt(numCostumesAvail)
  if numCostumesAvail == 0 or not game.teleportingUnlocked() or game.battleTutActive() then
    self.ButtonStatus.costumes = false
  end
  self:RefreshButtons()
end
function StoreCategorySelect:onStoreButtonPressed(storeCategory)
  playSoundFx("audio/sfx/menu_click_small.wav")
  store:SelectCategory(storeCategory)
  store:SetMenuState(game.StoreContext_IDLE)
  self:dismissMarketButton()
  menu:popPopUp()
end
function StoreCategorySelect:displayStructuresLockedPopup()
  if game.isComposerIsland() then
    game.displayNotification(game.getLocalizedText("COMPOSER_STRUCTURE_CATEGORY_LOCKED"))
  elseif game.isBattleIsland() then
    game.displayNotification(game.getLocalizedText("BATTLE_STRUCTURE_CATEGORY_LOCKED"))
  elseif game.isMagicalNexusIsland() then
    game.displayNotification(game.getLocalizedText("NEXUS_STRUCTURE_CATEGORY_LOCKED"))
  elseif game.isEtherealIslet() then
    game.displayNotification(game.getLocalizedText("ISLET_STRUCTURE_CATEGORY_LOCKED"))
  elseif game.isPaironormalIsland() then
    game.displayNotification(game.getLocalizedText("PAIRONORMAL_STRUCTURE_CATEGORY_LOCKED"))
  end
end
function StoreCategorySelect:displayDecorationsLockedPopup()
  if game.isComposerIsland() then
    game.displayNotification(game.getLocalizedText("COMPOSER_DECORATION_CATEGORY_LOCKED"))
  elseif game.isMagicalNexusIsland() then
    game.displayNotification(game.getLocalizedText("NEXUS_DECORATION_CATEGORY_LOCKED"))
  elseif game.isEtherealIslet() then
    game.displayNotification(game.getLocalizedText("ISLET_DECORATION_CATEGORY_LOCKED"))
  end
end
function StoreCategorySelect:displayCostumesLockedPopup()
  if self.CostumesButton:GetVar("numCostumes"):GetInt() == 0 then
    game.displayNotification(game.getLocalizedText("COSTUME_CATEGORY_NO_COSTUMES"))
  else
    game.displayNotification(game.getLocalizedText("COSTUME_CATEGORY_LOCKED"))
  end
end
function StoreCategorySelect:displayStarpowerLockedPopup()
  if game.numIslands() == 1 and game.playerLevel() < 10 then
    game.displayNotification(game.getLocalizedText("STARPOWER_CATEGORY_LOCKED"))
  elseif self.ButtonStatus.starpower == false then
    game.displayNotification(game.getLocalizedText("STARPOWER_CATEGORY_ISLAND_LOCKED"))
  end
end
function StoreCategorySelect:dismissMarketButton()
  local placement = game.nativePlacement("market_xpromo_button")
  if placement ~= nil then
    placement:reportDismiss()
  end
end
function StoreCategorySelect:disableBackButtons()
  self.BackButton:disable()
end
function StoreCategorySelect:disableBackButtonOnly()
end
function StoreCategorySelect.TitleFrame:InitEnds(component, flip)
  if flip == nil then
    flip = false
  end
  local hFlip = flip and 1 or 0
  component:GetVar("spriteName"):SetString("bookend_market")
  component:GetVar("sheetName"):SetString("xml_resources/store_elements.xml")
  component:GetVar("hFlip"):SetInt(hFlip)
  component:GetVar("size"):SetFloat(0.5 * game.windowScaleMin())
  component:GetVar("layer"):SetString("FrontPopUps")
end
function StoreCategorySelect.WebstoreButton.Sprite:onInit(element)
  self:GetVar("spriteName"):SetString("gfx/menu/store_button_webstore")
  self:GetVar("size"):SetFloat(0.45 * game.windowScaleMin())
  self:GetVar("layer"):SetString("FrontPopUps")
  element:GetComponent("Touch")("enabled"):SetInt(0)
  self:GetVar("visible"):SetInt(0)
end
function StoreCategorySelect.WebstoreButton.Text:onInit(element)
  self:GetVar("multiline"):SetInt(0)
  self:GetVar("autoScaleFactor"):SetFloat(0.01)
  self:GetVar("autoScale"):SetInt(1)
  self:GetVar("font"):Set(game.getTextFont())
  self:GetVar("size"):SetFloat(0.23 * game.windowScaleMin())
  self:GetVar("alignment"):SetInt(MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self:GetVar("text"):SetString("WEBSTORE_TEXT")
  self:GetVar("layer"):SetString("FrontPopUps")
  self:GetVar("visible"):SetInt(0)
end
function StoreCategorySelect.WebstoreButton:setVisible()
  self.Sprite:GetVar("visible"):SetInt(1)
  self.Touch:GetVar("enabled"):SetInt(1)
  self.Text:GetVar("visible"):SetInt(1)
  if self:GetElement("attachedTemplate") ~= nil then
    self:GetElement("attachedTemplate"):SetVisible()
  end
end
function StoreCategorySelect.WebstoreButton:setInvisible()
  self.Sprite:GetVar("visible"):SetInt(0)
  self.Touch:GetVar("enabled"):SetInt(0)
  self.Text:GetVar("visible"):SetInt(0)
  if self:GetElement("attachedTemplate") ~= nil then
    self:GetElement("attachedTemplate"):SetInvisible()
  end
end
function StoreCategorySelect.WebstoreButton.Touch:onTouchDown(element)
  element.Sprite:setColor(0.5, 0.5, 0.5)
  element.Text:setColor(0.5, 0.5, 0.5)
end
function StoreCategorySelect.WebstoreButton.Touch:onTouchUp(element)
  element.Sprite:setColor(1, 1, 1)
  element.Text:setColor(1, 1, 1)
  playSoundFx("audio/sfx/menu_click_small.wav")
  game.checkGamePermission("WEB_STORE", "popup_permission_web_store")
end
function StoreCategorySelect.WebstoreButton.Touch:onTouchRelease(element)
  element.Sprite:setColor(1, 1, 1)
  element.Text:setColor(1, 1, 1)
end
function StoreCategorySelect.WebstoreButton:disable(disableTouch)
  if disableTouch == nil or disableTouch ~= false then
    self.Touch:GetVar("enabled"):SetInt(0)
  end
  self.Sprite:setColor(0.5, 0.5, 0.5)
  self.Text:setColor(0.5, 0.5, 0.5)
end
function StoreCategorySelect.WebstoreButton:attachSaleIndicator()
  if self:GetElement("attachedTemplate") == nil then
    local attachedTemplate = menu:addTemplateElement("template_saleindicator", "attachedTemplate", self)
    attachedTemplate:setParent(self)
    attachedTemplate:setOrientation(MenuOrientation(0, -6 * game.windowScaleMin(), -3, HCENTER, VCENTER))
    attachedTemplate:setRelativeObjectAnchors(HCENTER, BOTTOM)
    attachedTemplate:init()
    attachedTemplate("setNewScale"):SetFloat(game.windowScaleMin())
    attachedTemplate.Text("layer"):SetString("FrontPopUps")
    attachedTemplate.Tag("layer"):SetString("FrontPopUps")
    attachedTemplate:setPositionBroadcast(true)
    attachedTemplate:postInit()
    self:calculatePosition()
  end
end
function StoreCategorySelect.WebstoreButton:detachSaleIndicator()
  if self:GetElement("attachedTemplate") ~= nil then
    self:RemoveElement(self:GetElement("attachedTemplate"))
  end
end
function StoreCategorySelect.AdButton:onInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfo", "gotMsgPlacementInfo")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfoFail", "gotMsgPlacementInfoFail")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPermission", "gotMsgPermission")
end
function StoreCategorySelect.AdButton:setVisible()
  self.Sprite:GetVar("visible"):SetInt(1)
  self.Touch:GetVar("enabled"):SetInt(1)
  self.Text:GetVar("visible"):SetInt(1)
end
function StoreCategorySelect.AdButton:setInvisible()
  self.Sprite:GetVar("visible"):SetInt(0)
  self.Touch:GetVar("enabled"):SetInt(0)
  self.Text:GetVar("visible"):SetInt(0)
end
function StoreCategorySelect.AdButton:gotMsgPlacementInfo(msg)
  if msg.name == "market_xpromo_button" then
    local placement = game.nativePlacement(msg.name)
    if placement ~= nil then
      local ad = placement:getAd(0)
      if ad ~= nil then
        ad:reportImpression()
        self:GetVar("placement"):SetString(msg.name)
        ad:applyMainTo(self.Sprite)
        if ad:getAction() ~= "" then
          self.Text:GetVar("text"):SetString(ad:getAction())
        else
          self.Text:GetVar("text"):SetString(ad:getTitle())
        end
        self.Text:GetVar("visible"):SetInt(1)
        self.Touch:GetVar("enabled"):SetInt(1)
      else
        self.Sprite:GetVar("spriteName"):SetString("gfx/menu/store_button_square_crosspromo")
        self.Sprite:GetVar("size"):SetFloat(0.45 * game.windowScaleMin())
      end
    else
      self.Sprite:GetVar("spriteName"):SetString("gfx/menu/store_button_square_crosspromo")
      self.Sprite:GetVar("size"):SetFloat(0.45 * game.windowScaleMin())
    end
  end
end
function StoreCategorySelect.AdButton:gotMsgPlacementInfoFail(msg)
  if msg.name == "market_xpromo_button" then
    self:setInvisible()
  end
end
function StoreCategorySelect.AdButton:gotMsgPermission(msg)
  if msg.name == "MORE_GAMES" and msg.allowed then
    game.logEvent("market_link_click", "game", "moregames_list")
    if lua_sys.getPlatformName() == "pc" then
      local placement = game.nativePlacement("market_xpromo_button")
      if placement ~= nil then
        local ad = placement:getAd(0)
        if ad ~= nil then
          ad:reportClick()
        end
      end
    else
      store:SelectCategory(game.StoreCategories_TYPE_CROSSPROMO)
      store:SetMenuState(game.StoreContext_IDLE)
      root:dismissMarketButton()
      menu:popPopUp()
    end
  elseif msg.name == "WEB_STORE" and msg.allowed then
    local placement = game.nativePlacement("market_xwebstore_button")
    if placement ~= nil then
      local ad = placement:getAd(0)
      if ad ~= nil then
        ad:reportClick()
      end
    end
  end
end
function StoreCategorySelect.AdButton.Sprite:onInit(element)
  if getSubPlatformName() ~= "aftb" then
    game.loadNewsFlash("market_xpromo_button")
  end
  self:GetVar("spriteName"):SetString("gfx/menu/store_button_square_crosspromo")
  self:GetVar("size"):SetFloat(0.45 * game.windowScaleMin())
  self:GetVar("layer"):SetString("FrontPopUps")
  element:GetComponent("Touch")("enabled"):SetInt(0)
  if getSubPlatformName() == "aftb" then
    self:GetVar("visible"):SetInt(0)
  end
end
function StoreCategorySelect.AdButton.Sprite:imageSet(element)
  local placement = game.nativePlacement(element("placement"):GetString())
  if placement ~= nil then
    local native = placement:getAd(0)
    if native ~= nil and native:hasMainImage() then
      native:applyMainTo(self)
      self:GetVar("size"):SetFloat(0.45 * game.windowScaleMin())
    end
  end
end
function StoreCategorySelect.AdButton.Text:onInit(element)
  self:GetVar("multiline"):SetInt(0)
  self:GetVar("autoScaleFactor"):SetFloat(0.01)
  self:GetVar("autoScale"):SetInt(1)
  self:GetVar("font"):Set(game.getTextFont())
  self:GetVar("size"):SetFloat(0.23 * game.windowScaleMin())
  self:GetVar("alignment"):SetInt(MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self:GetVar("text"):SetString("MARKET_AD_TEXT")
  self:GetVar("layer"):SetString("FrontPopUps")
  if getSubPlatformName() == "aftb" then
    self:GetVar("visible"):SetInt(0)
  end
end
function StoreCategorySelect.AdButton.Touch:onTouchDown(element)
  element.Sprite:setColor(0.5, 0.5, 0.5)
  element.Text:setColor(0.5, 0.5, 0.5)
end
function StoreCategorySelect.AdButton.Touch:onTouchUp(element)
  element.Sprite:setColor(1, 1, 1)
  element.Text:setColor(1, 1, 1)
  playSoundFx("audio/sfx/menu_click_small.wav")
  game.checkGamePermission("MORE_GAMES", "popup_permission_more_games")
end
function StoreCategorySelect.AdButton.Touch:onTouchRelease(element)
  element.Sprite:setColor(1, 1, 1)
  element.Text:setColor(1, 1, 1)
end
function StoreCategorySelect.AdButton:enable(enableTouch)
  if enableTouch == nil or enableTouch ~= false then
    self.Touch:GetVar("enabled"):SetInt(1)
  end
  self.Sprite:setColor(1, 1, 1)
  self.Text:setColor(1, 1, 1)
end
function StoreCategorySelect.AdButton:disable(disableTouch)
  if disableTouch == nil or disableTouch ~= false then
    self.Touch:GetVar("enabled"):SetInt(0)
  end
  self.Sprite:setColor(0.5, 0.5, 0.5)
  self.Text:setColor(0.5, 0.5, 0.5)
end
return StoreCategorySelect
