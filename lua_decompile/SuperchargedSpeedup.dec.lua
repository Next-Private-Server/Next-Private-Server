local SuperchargedSpeedup = {
  FadedBG = {
    Sprite = {}
  },
  bg = {},
  Icon = {
    Sprite = {},
    SheetSprite = {}
  },
  TimeText = {
    Text = {}
  },
  TimeRemaining = {
    CurrentTime = {},
    AdjustedTime = {}
  }
}
function SuperchargedSpeedup:onInit()
  self.transitionState = 1
  self.transitionTime = 0
  self.choice = "none"
  self.selectedObjectType = game.selectedObjType()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function SuperchargedSpeedup:onPostInit()
  if self.selectedObjectType == game.SpecificEntityType_BAKERY then
    local foodId = game.getCurrentBakeryFoodId()
    self.Icon.SheetSprite:V("visible"):SetInt(1)
    self.Icon.SheetSprite:V("spriteName"):SetString(game.bakeryItemSprite(foodId))
    self.Icon.SheetSprite:V("sheetName"):SetString(game.bakeryItemSpritesheet(foodId))
    self.Icon.SheetSprite:V("size"):SetFloat(0.5 * game.hudScale())
    self.TimeText.Text:V("text"):SetString(game.getLocalizedText("LABEL_BAKING_TIME") .. ": ")
  elseif self.selectedObjectType == game.SpecificEntityType_BREEDING then
    self.Icon.SheetSprite:V("visible"):SetInt(1)
    self.Icon.SheetSprite:V("spriteName"):SetString("collect_breeding_alone")
    self.Icon.SheetSprite:V("sheetName"):SetString("xml_resources/collect_stickers.xml")
    self.Icon.SheetSprite:V("size"):SetFloat(0.9 * game.hudScale())
    self.TimeText.Text:V("text"):SetString(game.getLocalizedText("LABEL_BREEDING_TIME") .. ": ")
  elseif self.selectedObjectType == game.SpecificEntityType_NURSERY then
    self.Icon.Sprite:V("visible"):SetInt(1)
    self.Icon.Sprite:V("spriteName"):SetString("gfx/" .. game.getEggGraphic())
    self.Icon.Sprite:V("size"):SetFloat(0.3 * game.hudScale())
    self.TimeText.Text:V("text"):SetString(game.getLocalizedText("LABEL_INCUBATION_TIME") .. ": ")
  else
    print("Supercharge not supported for this object")
    self:root():popPopUp()
  end
end
function SuperchargedSpeedup:onTick(dt)
  if self.transitionState ~= 0 then
    self.bg:V("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() / self.transitionTime)
    self.FadedBG.Sprite:V("alpha"):SetFloat(self.transitionTime * 0.5)
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    self.transitionTime = clamp(self.transitionTime, 0, 1)
    if self.transitionTime >= 1 then
      self.transitionState = 0
      self.transitionTime = 1
      self.bg:V("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() / self.transitionTime)
      self.FadedBG.Sprite:V("alpha"):SetFloat(self.transitionTime * 0.5)
    elseif 0 >= self.transitionTime then
      self:root():popPopUp()
      if self.selectedObjectType == game.SpecificEntityType_BAKERY then
        game.submitConfirmation("FINISH_BAKING_SPEEDUP_VIDEO_SUPERCHARGE", self.choice == "watch")
      elseif self.selectedObjectType == game.SpecificEntityType_BREEDING then
        game.submitConfirmation("FINISH_BREEDING_SPEEDUP_VIDEO_SUPERCHARGE", self.choice == "watch")
      elseif self.selectedObjectType == game.SpecificEntityType_NURSERY then
        game.submitConfirmation("HATCH_EGG_SPEEDUP_VIDEO_SUPERCHARGE", self.choice == "watch")
      else
        print("Supercharge not supported for this object")
        self:root():popPopUp()
      end
    end
  end
  self:updateText()
end
function SuperchargedSpeedup:updateText()
  local timeRemaining = game.timeLeftOnStruct()
  self.TimeRemaining.CurrentTime:V("text"):SetString(game.timeToString(timeRemaining))
  self.TimeRemaining.AdjustedTime:V("text"):SetString(game.timeToString(math.max(timeRemaining - game.getSuperchargedSpeedUpTime(), 0)))
end
function SuperchargedSpeedup:onSuperchargeClicked()
  self.transitionState = 2
  self.choice = "watch"
end
function SuperchargedSpeedup:onNoClicked()
  self.transitionState = 2
  self.choice = "wait"
end
return SuperchargedSpeedup
