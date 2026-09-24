local Coroutines = include("Coroutines")
local template_ClubStageEdEntry = {
  Sprite = {},
  Icon = {
    Sprite = {}
  },
  VariantControlButton = {
    Sprite = {},
    Text = {},
    Touch = {}
  },
  Alert = {
    Sprite = {},
    coroutineId = nil,
    flash_on_sec = 1.25,
    flash_off_sec = 1.25
  },
  buttonId = -1,
  activeVariantInd = -1,
  disabled = 0
}
function template_ClubStageEdEntry:onPostInit()
  if self.buttonId ~= -1 then
    self.activeVariantInd = game.getStageEditorActiveVariant(self.buttonId)
    if self:isUnlocked() then
      self:enable()
    else
      self:disable()
    end
  else
    self:disable()
  end
end
function template_ClubStageEdEntry:isUnlocked()
  if self.buttonId ~= -1 then
    local curVariant = self:parent().activeVariantInd
    local maxNum = game.getStageEditorNumVariants(self.buttonId, false)
    if maxNum > 0 then
      return true
    end
  end
  return false
end
function template_ClubStageEdEntry:disable()
  self.disabled = 1
  self.VariantControlButton:disable()
end
function template_ClubStageEdEntry:enable()
  if self:isUnlocked() then
    self.disabled = 0
    self.VariantControlButton:enable()
  end
end
function template_ClubStageEdEntry:SetInvisible()
  self.Icon.Sprite("visible"):SetInt(0)
  self.VariantControlButton.Sprite("visible"):SetInt(0)
  self.VariantControlButton.Text("visible"):SetInt(0)
  self.VariantControlButton.Touch("enabled"):SetInt(0)
end
function template_ClubStageEdEntry:SetVisible()
  self.Icon.Sprite("visible"):SetInt(1)
  self.VariantControlButton.Sprite("visible"):SetInt(1)
  self.VariantControlButton.Text("visible"):SetInt(1)
  self.VariantControlButton.Touch("enabled"):SetInt(1)
end
function template_ClubStageEdEntry:updateVariantNumber()
  self.VariantControlButton:updateVariantNumber()
end
function template_ClubStageEdEntry.VariantControlButton:updateVariantNumber()
  if self:parent().disabled == 0 then
    if self:parent().activeVariantInd == -1 then
      self.VariantControlButton.Text("text"):SetString(1)
    elseif self:parent().activeVariantInd == 0 then
      self.VariantControlButton.Text("text"):SetString(0)
    else
      self.VariantControlButton.Text("text"):SetString(self:parent().activeVariantInd + 1)
    end
    if self:parent().Alert.coroutineId then
      self.VariantControlButton.Text("text"):SetString("!")
    end
  else
    self.VariantControlButton.Text("text"):SetString("-")
  end
end
function template_ClubStageEdEntry.VariantControlButton:disable()
  self.Sprite("spriteName"):SetString(self:templateVars().buttonDisabledSpriteName)
  self.Sprite("sheetName"):SetString(self:templateVars().buttonSpriteSheet)
  self.VariantControlButton:updateVariantNumber()
end
function template_ClubStageEdEntry.VariantControlButton:enable()
  self.Sprite("spriteName"):SetString(self:templateVars().buttonSpriteName)
  self.Sprite("sheetName"):SetString(self:templateVars().buttonSpriteSheet)
  self.VariantControlButton:updateVariantNumber()
end
function template_ClubStageEdEntry.VariantControlButton.Touch:onTouchUp(element, x, y)
  if element:parent().disabled == 0 then
    element:parent().Alert:StopAlert()
    element.Sprite("spriteName"):SetString(element:templateVars().buttonSpriteName)
    element.Sprite("sheetName"):SetString(element:templateVars().buttonSpriteSheet)
    local selectedPropControl = element:parent()
    if selectedPropControl ~= nil then
      local curVariant = element:parent().activeVariantInd
      local maxNum = game.getStageEditorNumVariants(selectedPropControl.buttonId)
      if curVariant == 0 then
        curVariant = -1
      elseif curVariant == -1 then
        curVariant = 1
      else
        curVariant = curVariant + 1
      end
      while true do
        if curVariant ~= -1 then
        elseif not (maxNum > curVariant) or game.getStageEdButtonUnlocked(selectedPropControl.buttonId, curVariant) == true then
          break
        end
        curVariant = curVariant + 1
      end
      if maxNum <= curVariant then
        curVariant = 0
      end
      lua_sys.playSoundFx("audio/sfx/clubbox_menu_tap_select.wav")
      game.activateStageEdVariant(selectedPropControl.buttonId, curVariant)
      element:parent().activeVariantInd = curVariant
      element:parent():updateVariantNumber()
    end
  else
    element.Sprite("spriteName"):SetString(element:templateVars().buttonDisabledSpriteName)
    element.Sprite("sheetName"):SetString(element:templateVars().buttonSpriteSheet)
  end
  element.Text("yOffset"):SetInt(element.Text("originalYOffset"):GetInt() * element.Text("originalScale"):GetInt())
end
function template_ClubStageEdEntry.VariantControlButton.Touch:onTouchDown(element, x, y)
  if element:parent().disabled == 0 then
    element:parent().Alert:StopAlert()
    element.Sprite("spriteName"):SetString(element:templateVars().buttonDownSpriteName)
    element.Sprite("sheetName"):SetString(element:templateVars().buttonSpriteSheet)
  else
    element.Sprite("spriteName"):SetString(element:templateVars().buttonDisabledDownSpriteName)
    element.Sprite("sheetName"):SetString(element:templateVars().buttonSpriteSheet)
  end
  element.Text("yOffset"):SetInt((element.Text("originalYOffset"):GetInt() + 2) * element.Text("originalScale"):GetInt())
end
function template_ClubStageEdEntry.VariantControlButton.Touch:onTouchRelease(element, x, y)
  if element:parent().disabled == 0 then
    element:parent().Alert:StopAlert()
    element.Sprite("spriteName"):SetString(element:templateVars().buttonSpriteName)
    element.Sprite("sheetName"):SetString(element:templateVars().buttonSpriteSheet)
  else
    element.Sprite("spriteName"):SetString(element:templateVars().buttonDisabledSpriteName)
    element.Sprite("sheetName"):SetString(element:templateVars().buttonSpriteSheet)
  end
  element.Text("yOffset"):SetInt(element.Text("originalYOffset"):GetInt() * element.Text("originalScale"):GetInt())
end
function StartAlertCo(element)
  if not coroutine.running() then
    print("need to run as a coroutine!")
    return
  end
  while true do
    element:parent().VariantControlButton.Sprite("spriteName"):SetString(element:parent().VariantControlButton:templateVars().buttonSpriteName)
    element:parent().VariantControlButton.Sprite("sheetName"):SetString(element:parent().VariantControlButton:templateVars().buttonSpriteSheet)
    Coroutines.WaitForSeconds(element.flash_on_sec)
    element:parent().VariantControlButton.Sprite("spriteName"):SetString(element:parent().VariantControlButton:templateVars().buttonDisabledSpriteName)
    element:parent().VariantControlButton.Sprite("sheetName"):SetString(element:parent().VariantControlButton:templateVars().buttonSpriteSheet)
    Coroutines.WaitForSeconds(element.flash_off_sec)
  end
end
function template_ClubStageEdEntry.Alert:StartAlert()
  self:parent().VariantControlButton.Text("text"):SetString("!")
  self.coroutineId = RunIndyCoroutine(StartAlertCo, self)
end
function template_ClubStageEdEntry.Alert:StopAlert()
  if self.coroutineId then
    KillCoroutine(self.coroutineId)
    self.coroutineId = nil
  end
end
function template_ClubStageEdEntry.Alert:onDestroy()
  if self.coroutineId then
    KillCoroutine(self.coroutineId)
    self.coroutineId = nil
  end
end
return template_ClubStageEdEntry
