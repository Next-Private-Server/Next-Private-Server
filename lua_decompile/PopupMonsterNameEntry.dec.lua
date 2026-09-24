local MenuHelpers = include("MenuHelpers")
local PopupMonsterNameEntry = {
  text = "",
  messageID = "",
  transitionState = 1,
  transitionTime = 0,
  choice = "none",
  locked = false,
  activated = true,
  cursorVisible = true,
  cursorTime = 0,
  cursorShowTime = 0.5,
  cursorHideTime = 0.2,
  lastKey = -1,
  lastModKey = 0,
  charLimit = 20,
  bg = {},
  FadedBG = {
    Sprite = {}
  },
  TitleLabel = {
    Text = {}
  },
  Description = {
    Text = {}
  },
  TextEntry = {
    Text = {},
    Cursor = {}
  }
}
function PopupMonsterNameEntry:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function PopupMonsterNameEntry:onInit()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  self:setPositionBroadcast(true)
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgKeyDown", "gotMsgKeyDown")
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgKeyUp", "gotMsgKeyUp")
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgKeyRepeat", "gotMsgKeyRepeat")
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgKeyChar", "gotMsgKeyChar")
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgKeyboardEntryResult", "gotMsgKeyboardEntryResult")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgTextEntrySubmission", "gotMsgTextEntrySubmission")
end
function PopupMonsterNameEntry:onPostInit()
  self.text = self.TextEntry.Text:GetVar("text"):GetString()
  self.TextEntry.Cursor:GetVar("size"):SetFloat(self.TextEntry.Text:GetVar("size"):GetFloat())
  self:adjustCursorPosition()
end
function PopupMonsterNameEntry:setup(entryID, titleText, descText, defaultText, maxChars)
  self.messageID = entryID
  self.charLimit = maxChars
  self.text = defaultText
  self.TitleLabel.Text:GetVar("text"):SetString(titleText)
  self.Description.Text:GetVar("text"):SetString(descText)
  self.TextEntry.Text:GetVar("autoScale"):SetInt(0)
  self.TextEntry.Text:GetVar("noTranslate"):SetInt(1)
  self.TextEntry.Text:GetVar("text"):SetString(defaultText)
  self.TextEntry.Text:GetVar("autoScale"):SetInt(1)
  self:adjustCursorPosition()
end
function PopupMonsterNameEntry:gotMsgKeyboardEntryResult(msg)
  if not msg.cancelled then
    self:updateName(msg.text)
  end
end
function PopupMonsterNameEntry:gotMsgTextEntrySubmission(msg)
  if msg.messageID == "MONSTER_NAME" and msg.choice == true then
    self:updateName(msg.text)
  end
end
function PopupMonsterNameEntry:onTick(dt)
  if self.transitionState ~= 0 then
    self:TickTransition()
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    self.transitionTime = lua_sys.clamp(self.transitionTime, 0, 1)
    if 1 <= self.transitionTime then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
    elseif 0 >= self.transitionTime then
      if self.choice == "true" then
        self:root():popPopUp()
        game.setMonsterName(self.text)
      else
        self:root():popPopUp()
      end
    end
  end
  if self.activated then
    self.cursorTime = self.cursorTime + dt
    if self.cursorVisible then
      if self.cursorTime >= self.cursorShowTime then
        self.cursorVisible = false
        self.cursorTime = 0
        self.TextEntry.Cursor:GetVar("visible"):SetInt(0)
      end
    elseif self.cursorTime >= self.cursorHideTime then
      self.cursorVisible = true
      self.cursorTime = 0
      self.TextEntry.Cursor:GetVar("visible"):SetInt(1)
    end
  end
end
function PopupMonsterNameEntry:TickTransition()
  self.bg:GetVar("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.FadedBG.Sprite:GetVar("alpha"):SetFloat(self.transitionTime * 0.5)
end
function PopupMonsterNameEntry:queuePop()
  self.transitionState = 2
end
function PopupMonsterNameEntry:gotMsgKeyDown(msg)
  if self.activated then
    self.lastKey = msg.key.val
    self.lastModKey = msg.modKey.val
    self:doKeyActions()
  end
end
function PopupMonsterNameEntry:gotMsgKeyUp(msg)
  if self.activated then
    self.lastKey = 0
    self.lastModKey = 0
  end
end
function PopupMonsterNameEntry:gotMsgKeyRepeat(msg)
  if self.activated then
    self.lastKey = msg.key.val
    self.lastModKey = msg.modKey.val
    self:doKeyActions()
  end
end
function PopupMonsterNameEntry:gotMsgKeyChar(msg)
  if self.activated then
    local newChar = msg.inputChar
    if game.wcharCount(self.text) < self.charLimit and game.validInput(newChar) then
      self.text = self.text .. newChar
      self.TextEntry.Text:GetVar("text"):SetString(self.text)
      self.cursorVisible = true
      self.TextEntry.Cursor:GetVar("visible"):SetInt(1)
      self.cursorTime = 0
      self.TextEntry.Cursor:GetVar("size"):SetFloat(self.TextEntry.Text:GetVar("size"):GetFloat())
      self:adjustCursorPosition()
    end
  end
end
function PopupMonsterNameEntry:doKeyActions()
  if self.activated then
    if self.lastKey == game.BackSpace and game.wcharCount(self.text) > 0 then
      self.text = game.removeWchar(self.text)
      self.TextEntry.Text:GetVar("text"):SetString(self.text)
      self.cursorVisible = true
      self.TextEntry.Cursor:GetVar("visible"):SetInt(1)
      self.cursorTime = 0
      self.TextEntry.Cursor:GetVar("size"):SetFloat(self.TextEntry.Text:GetVar("size"):GetFloat())
      self:adjustCursorPosition()
    elseif self.lastKey == game.Enter then
      self.activated = false
      self.transitionState = 2
      self.choice = "true"
    elseif self.lastKey == game.V and self.lastModKey == game.Control then
      self.text = game.addClipboardText(self.text, self.charLimit)
      self.TextEntry.Text("text"):SetString(self.text)
      self.cursorVisible = true
      self.TextEntry.Cursor:GetVar("visible"):SetInt(1)
      self.cursorTime = 0
      self.TextEntry.Cursor:GetVar("size"):SetFloat(self.TextEntry.Text:GetVar("size"):GetFloat())
      self:adjustCursorPosition()
    end
  end
end
function PopupMonsterNameEntry:adjustCursorPosition()
  local numEndSpaces = 0
  for i = #self.text, 1, -1 do
    local char = self.text:sub(i, i)
    if char == " " then
      numEndSpaces = numEndSpaces + 1
    else
      break
    end
  end
  local perceptibles = {
    self.TextEntry.Text,
    MenuHelpers.CreateSpacer(numEndSpaces * 8, 0),
    self.TextEntry.Cursor
  }
  MenuHelpers.CenterHorizontally(perceptibles)
  local cursorX = self.TextEntry.Cursor:GetVar("xOffset"):GetFloat() - 4
  self.TextEntry.Cursor:GetVar("xOffset"):SetFloat(cursorX)
end
function PopupMonsterNameEntry:getRandomName()
  self:updateName(game.getRandomAutoname(game.selectedMonster(), self.text))
end
function PopupMonsterNameEntry:updateName(name)
  self.text = name
  self.TextEntry.Text:GetVar("autoScale"):SetInt(0)
  self.TextEntry.Text:GetVar("noTranslate"):SetInt(1)
  self.TextEntry.Text:GetVar("text"):SetString(name)
  self.TextEntry.Text:GetVar("autoScale"):SetInt(1)
  self:adjustCursorPosition()
end
return PopupMonsterNameEntry
