local Newsflash = {
  MainBG = {
    MainImage = {},
    Touch = {},
    ActionButton1 = {
      Text = {},
      Sprite = {},
      Touch = {}
    },
    ActionButton2 = {
      Text = {},
      Sprite = {},
      Touch = {}
    },
    ActionButton3 = {
      Text = {},
      Sprite = {},
      Touch = {}
    }
  },
  CloseButton = {
    Touch = {}
  },
  TitleFrame = {
    Sprite = {},
    Text = {}
  },
  PageCounter = {
    Sprite = {},
    Text = {}
  },
  NextButton = {
    Touch = {}
  },
  BackButton = {
    Touch = {}
  },
  transitionState = 1,
  transitionTime = 0,
  btnTransitionState = 0,
  btnTransitionTime = 0,
  delayTime = 0,
  showCloseBtn = false,
  textSize1 = 0,
  textSize2 = 0,
  textSize3 = 0,
  width = 0,
  height = 0
}
function Newsflash:onInit()
  self:GetVar("index"):SetInt(0)
  self.CloseButton:disable()
  self.CloseButton:setInvisible()
end
function Newsflash:onTick(dt)
  local transitionState = self.transitionState
  if transitionState ~= 0 then
    local transitionTime = self.transitionTime
    self:TickTransition()
    if transitionState == 1 then
      transitionTime = transitionTime + dt * 3
    elseif transitionState == 2 then
      transitionTime = transitionTime - dt * 3
    end
    self.transitionTime = transitionTime
    if transitionTime > 1 then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
    elseif transitionTime < 0 then
      self:root():popPopUp()
    end
  end
  if os.time() >= self.delayTime and not self.showCloseBtn then
    self.CloseButton:enable()
    self.CloseButton:setVisible()
    self.showCloseBtn = true
  end
  if self.MainBG.ActionButton1.Text:GetVar("hasPulse"):GetInt() == 1 or self.MainBG.ActionButton2.Text:GetVar("hasPulse"):GetInt() == 1 or self.MainBG.ActionButton3.Text:GetVar("hasPulse"):GetInt() == 1 then
    local btnTransitionState = self.btnTransitionState
    local btnTransitionTime = self.btnTransitionTime
    if btnTransitionState == 0 then
      self.btnTransitionTime = btnTransitionTime + dt
      if btnTransitionState == 0 and btnTransitionTime >= 1 then
        self.btnTransitionState = 1
        self.btnTransitionTime = 1
      end
    elseif btnTransitionState ~= 0 and dt <= 0.5 then
      if self.MainBG.ActionButton1.Text:GetVar("hasPulse"):GetInt() == 1 then
        self.MainBG.ActionButton1.UpSprite:GetVar("width"):SetInt(self.width * btnTransitionTime)
        self.MainBG.ActionButton1.UpSprite:GetVar("height"):SetInt(self.height * btnTransitionTime)
        self.MainBG.ActionButton1.Text:GetVar("size"):SetFloat(self.textSize1 * btnTransitionTime)
      end
      if self.MainBG.ActionButton2.Text:GetVar("hasPulse"):GetInt() == 1 then
        self.MainBG.ActionButton2.UpSprite:GetVar("width"):SetInt(self.width * btnTransitionTime)
        self.MainBG.ActionButton2.UpSprite:GetVar("height"):SetInt(self.height * btnTransitionTime)
        self.MainBG.ActionButton2.Text:GetVar("size"):SetFloat(self.textSize2 * btnTransitionTime)
      end
      if self.MainBG.ActionButton3.Text:GetVar("hasPulse"):GetInt() == 1 then
        self.MainBG.ActionButton3.UpSprite:GetVar("width"):SetInt(self.width * btnTransitionTime)
        self.MainBG.ActionButton3.UpSprite:GetVar("height"):SetInt(self.height * btnTransitionTime)
        self.MainBG.ActionButton3.Text:GetVar("size"):SetFloat(self.textSize3 * btnTransitionTime)
      end
      if btnTransitionTime <= 1 then
        self.btnTransitionState = 1
      elseif btnTransitionTime >= 1.2 then
        self.btnTransitionState = 2
      end
      if btnTransitionState == 1 then
        self.btnTransitionTime = btnTransitionTime + dt / 2
      else
        self.btnTransitionTime = btnTransitionTime - dt / 2
        btnTransitionTime = btnTransitionTime - dt
        if btnTransitionTime <= 1 then
          self.btnTransitionState = 0
          self.btnTransitionTime = 0
        end
      end
    end
  end
end
function Newsflash:TickTransition()
  local transitionTime = self.transitionTime
  self.MainBG:GetVar("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / transitionTime))
  self.MainBG.MainImage:GetVar("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / transitionTime))
  self.FadedBG.Sprite("alpha"):SetFloat(self.transitionTime * 0.5)
end
function Newsflash:setMainImage()
  local mainImage = self.MainBG.MainImage
  local placement = game.nativePlacement(self:GetVar("placement"):GetString())
  if placement ~= nil then
    local index = self:GetVar("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil then
      self.MainBG.Touch:GetVar("enabled"):SetInt(1)
      if ad:hasMainImage() then
        ad:applyMainTo(mainImage)
        ad:reportImpression()
      else
        game.logEvent("newsflash_error", "error", "setMainImage image is null")
      end
    else
      game.logEvent("newsflash_error", "error", "setMainImage ad is null")
    end
  else
    game.logEvent("newsflash_error", "error", "setMainImage placement is null")
  end
end
function Newsflash:showCloseButton()
  local placement = game.nativePlacement(self:GetVar("placement"):GetString())
  if placement ~= nil then
    local index = self:GetVar("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil then
      local delay = ad:getCloseDelay()
      if delay ~= "" then
        self.delayTime = tonumber(os.time() + delay / 1000)
      else
        self.CloseButton:enable()
        self.CloseButton:setVisible()
        self.showCloseBtn = true
      end
    end
  end
end
function Newsflash.CloseButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
  local placement = game.nativePlacement(element:parent()("placement"):GetString())
  if placement ~= nil then
    placement:reportDismiss()
  end
  element:parent().transitionState = 2
end
function Newsflash:setTitleFrame()
  local sprite = self.TitleFrame.Sprite
  local text = self.TitleFrame.Text
  local placement = game.nativePlacement(self:GetVar("placement"):GetString())
  if placement ~= nil then
    local index = self:GetVar("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil and ad:getCarouselActive() then
      text:GetVar("visible"):SetInt(1)
      sprite:GetVar("visible"):SetInt(1)
      text:GetVar("text"):SetString(ad:getTitle())
    end
  end
end
function Newsflash:setPageCounter()
  local sprite = self.PageCounter.Sprite
  local text = self.PageCounter.Text
  local placement = game.nativePlacement(self:GetVar("placement"):GetString())
  if placement ~= nil then
    local index = self:GetVar("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil and ad:getShowCarouselCounter() then
      local numEntries = ad:getCarouselMaxAds()
      text:GetVar("text"):SetString("1/" .. tostring(numEntries))
      text:GetVar("visible"):SetInt(1)
      sprite:GetVar("visible"):SetInt(1)
    end
  end
end
function Newsflash:showActionButtons()
  local placement = game.nativePlacement(self:GetVar("placement"):GetString())
  if placement ~= nil then
    local index = self:GetVar("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil and ad:numButtons() ~= 0 then
      self.width = self.MainBG.ActionButton2.UpSprite("width"):GetInt()
      self.height = self.MainBG.ActionButton2.UpSprite("height"):GetInt()
      if ad:numButtons() == 1 then
        self.MainBG.ActionButton2:enable()
        self.MainBG.ActionButton2:setVisible()
        setButtonElements(self.MainBG.ActionButton2, ad, 0)
        self.textSize2 = self.MainBG.ActionButton2.Text("size"):GetFloat()
      elseif ad:numButtons() == 2 then
        self.MainBG.ActionButton1:enable()
        self.MainBG.ActionButton1:setVisible()
        setButtonElements(self.MainBG.ActionButton1, ad, 0)
        self.textSize1 = self.MainBG.ActionButton1.Text("size"):GetFloat()
        self.MainBG.ActionButton3:enable()
        self.MainBG.ActionButton3:setVisible()
        setButtonElements(self.MainBG.ActionButton3, ad, 1)
        self.textSize3 = self.MainBG.ActionButton3.Text("size"):GetFloat()
      else
        self.MainBG.ActionButton1:enable()
        self.MainBG.ActionButton1:setVisible()
        setButtonElements(self.MainBG.ActionButton1, ad, 0)
        self.textSize1 = self.MainBG.ActionButton1.Text("size"):GetFloat()
        self.MainBG.ActionButton2:enable()
        self.MainBG.ActionButton2:setVisible()
        setButtonElements(self.MainBG.ActionButton2, ad, 1)
        self.textSize2 = self.MainBG.ActionButton2.Text("size"):GetFloat()
        self.MainBG.ActionButton3:enable()
        self.MainBG.ActionButton3:setVisible()
        setButtonElements(self.MainBG.ActionButton3, ad, 2)
        self.textSize3 = self.MainBG.ActionButton3.Text("size"):GetFloat()
      end
    end
  end
end
function setButtonElements(button, ad, index)
  local textSet = false
  if ad:getProductID(index) ~= "" and lua_sys.getPlatformName() ~= "pc" then
    local price = game.getLocalizedPrice(ad:getGroupID(index), ad:getProductID(index))
    if price ~= "" then
      button.Text("text"):SetString(price)
      textSet = true
    end
  end
  if not textSet and ad:getLabel(index) ~= "" then
    button.Text("text"):SetString(ad:getLabel(index))
  end
  if ad:getLabelColor(index) ~= "" then
    local rgb = {
      hexToRGB(ad:getLabelColor(index))
    }
    button.Text:setColor(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
  end
  if ad:getCurrency(index) ~= "" then
    button.Sprite("spriteName"):SetString(ad:getCurrency(index))
    button.Sprite("sheetName"):SetString("xml_resources/hud01.xml")
    button.Text("xOffset"):SetFloat(12 * game.menuScaleX())
    button.Sprite("visible"):SetInt(1)
  end
  if ad:getAnimation(index) ~= "" and ad:getAnimation(index) == "pulse" then
    button.Text("hasPulse"):SetInt(1)
  end
end
function hexToRGB(hex)
  hex = hex:gsub("#", "")
  return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end
function Newsflash.MainBG.ActionButton1.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  local placement = game.nativePlacement(element:parent():parent()("placement"):GetString())
  if placement ~= nil then
    local index = element:parent():parent()("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil then
      lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
      ad:handleClick(0)
    end
    placement:reportDismiss()
  end
  element:root():popPopUp()
end
function Newsflash.MainBG.ActionButton2.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  local placement = game.nativePlacement(element:parent():parent()("placement"):GetString())
  if placement ~= nil then
    local index = element:parent():parent()("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil then
      lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
      if ad:numButtons() == 1 then
        ad:handleClick(0)
      else
        ad:handleClick(1)
      end
    end
    placement:reportDismiss()
  end
  element:root():popPopUp()
end
function Newsflash.MainBG.ActionButton3.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  local placement = game.nativePlacement(element:parent():parent()("placement"):GetString())
  if placement ~= nil then
    local index = element:parent():parent()("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil then
      lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
      if ad:numButtons() == 2 then
        ad:handleClick(1)
      elseif ad:numButtons() == 3 then
        ad:handleClick(2)
      end
    end
    placement:reportDismiss()
  end
  element:root():popPopUp()
end
function Newsflash:setNextButton()
  local placement = game.nativePlacement(self:GetVar("placement"):GetString())
  if placement ~= nil then
    local index = self:GetVar("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil and ad:getCarouselActive() then
      self.NextButton:enable()
      self.NextButton:setVisible()
    end
  end
end
function Newsflash.NextButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
  local backBtnVisible = element:parent().BackButton.isVisible
  if not backBtnVisible then
    element:parent().BackButton:enable()
    element:parent().BackButton:setVisible()
  end
  local placement = game.nativePlacement(element:parent()("placement"):GetString())
  if placement ~= nil then
    local index = element:parent()("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil then
      local numEntries = ad:getCarouselMaxAds()
      local nextIndex = index + 1
      if nextIndex <= numEntries - 1 then
        local nextAd = placement:getAd(nextIndex)
        if nextAd ~= nil and nextAd:hasMainImage() then
          nextAd:applyMainTo(element:parent().MainBG.MainImage)
        end
        element:parent().PageCounter.Text("text"):SetString(tostring(nextIndex + 1) .. "/" .. tostring(numEntries))
        element:parent()("index"):SetInt(nextIndex)
      end
      if nextIndex == numEntries - 1 then
        element:disable()
        element:setInvisible()
      end
    end
  end
end
function Newsflash.BackButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
  local nextBtnVisible = element:parent().NextButton.isVisible
  if not nextBtnVisible then
    element:parent().NextButton:enable()
    element:parent().NextButton:setVisible()
  end
  local placement = game.nativePlacement(element:parent()("placement"):GetString())
  if placement ~= nil then
    local index = element:parent()("index"):GetInt()
    local ad = placement:getAd(index)
    if ad ~= nil then
      local numEntries = ad:getCarouselMaxAds()
      local prevIndex = index - 1
      if prevIndex >= 0 then
        local prevAd = placement:getAd(prevIndex)
        if prevAd ~= nil and prevAd:hasMainImage() then
          prevAd:applyMainTo(element:parent().MainBG.MainImage)
        end
        element:parent().PageCounter.Text("text"):SetString(tostring(prevIndex + 1) .. "/" .. tostring(numEntries))
        element:parent()("index"):SetInt(prevIndex)
      end
      if prevIndex == 0 then
        element:disable()
        element:setInvisible()
      end
    end
  end
end
return Newsflash
