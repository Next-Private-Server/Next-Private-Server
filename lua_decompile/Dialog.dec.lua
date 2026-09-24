local Dialog = {
  Avatar = {
    Sprite = {}
  },
  Dialog = {
    Sprite = {},
    Text = {}
  },
  Name = {
    Sprite = {},
    Text = {}
  },
  PreviousButton = {},
  NextButton = {}
}
local DialogStep = {
  Avatar = "",
  Dialog = "",
  SFX = ""
}
local SECONDS_PER_CHARACTER = 0.022222222222222223
local PAUSE_DELAYS = {
  ["."] = 0.4,
  ["..."] = 0.05,
  ["?"] = 0.4,
  ["!"] = 0.4,
  [","] = 0.1,
  [";"] = 0.2,
  [":"] = 0.2
}
local PULSE_DELAY = 0.4
local PULSE_SPEED = 4
local PULSE_SIZE = 0.1
local EST_CHAR_SIZE = 25 * (0.25 * game.windowScaleY())
function Dialog:onInit()
  self.currentText = ""
  self.targetText = ""
  self.lastLetterTime = 0
  self.dialogSteps = {}
  self.currentDialogIndex = 1
  self.inColorTag = false
  self.startOfWordForNewLinePos = nil
  self.PreviousButton:DoStoredScript("setInvisible")
  self.NextButton:DoStoredScript("setInvisible")
  self.textSize = 380 * game.windowScaleY()
  local maxWidth = screenWidth() * 0.8
  if maxWidth < self.Dialog:absW() then
    self.Dialog.Sprite("width"):SetFloat(maxWidth)
    self.textSize = maxWidth - 40 * game.windowScaleY()
    self.Dialog.Text:setSize(Vector2(self.textSize, self.Dialog.Text:absH()))
  end
end
function Dialog:onPostInit()
end
function Dialog:onTick(dt)
  self.lastLetterTime = self.lastLetterTime + dt
  if self.currentText ~= self.targetText and self.lastLetterTime >= SECONDS_PER_CHARACTER then
    self.lastLetterTime = 0
    local nextLetter = self.targetText:sub(#self.currentText + 1, #self.currentText + 1)
    if nextLetter == "<" then
      repeat
        self.currentText = self.currentText .. nextLetter
        nextLetter = self.targetText:sub(#self.currentText + 1, #self.currentText + 1)
      until nextLetter == ">"
      self.currentText = self.currentText .. nextLetter
      nextLetter = self.targetText:sub(#self.currentText + 1, #self.currentText + 1)
      self.inColorTag = not self.inColorTag
    end
    if PAUSE_DELAYS[nextLetter] then
      self.lastLetterTime = -PAUSE_DELAYS[nextLetter]
      if nextLetter == "." and #self.currentText + 2 <= #self.targetText and self.targetText:sub(#self.currentText + 2, #self.currentText + 2) == "." then
        self.lastLetterTime = -PAUSE_DELAYS["..."]
      end
    end
    if not self.startOfWordForNewLinePos and #self.currentText > 1 and string.sub(self.currentText, -1) == " " and not nextLetter:match("[%s<]") then
      local startIndex = #self.currentText + 1
      local word = self.targetText:sub(startIndex):match("^([^%s<]+)")
      local currentWordLength = word and #word or 0
      local currentWidth = self.Dialog.Text:absW()
      local estFinalWidth = currentWidth + (currentWordLength + 1) * EST_CHAR_SIZE
      if currentWidth < self.textSize and estFinalWidth > self.textSize then
        self.startOfWordForNewLinePos = #self.currentText
      end
    end
    self.currentText = self.currentText .. nextLetter
    if self.startOfWordForNewLinePos and #self.currentText > self.startOfWordForNewLinePos then
      self.Dialog.Text("text"):SetString(string.sub(self.currentText, 1, self.startOfWordForNewLinePos - 1) .. "\n" .. string.sub(self.currentText, self.startOfWordForNewLinePos) .. (self.inColorTag and "</c>" or ""))
    else
      self.Dialog.Text("text"):SetString(self.currentText .. (self.inColorTag and "</c>" or ""))
    end
    if self:IsTextComplete() and self.onTextComplete then
      self:onTextComplete()
    end
  end
  if self.lastLetterTime > PULSE_DELAY then
    local scale = (1 - math.cos((PULSE_DELAY - self.lastLetterTime) * PULSE_SPEED)) * PULSE_SIZE
    self.NextButton.UpSprite("size"):SetFloat(self.NextButton.spriteScale + scale)
  end
end
function Dialog:SetAvatar(sprite)
  self.Avatar.Sprite("spriteName"):SetString(sprite)
end
function Dialog:SetText(text, instant)
  local localizedText = LOC(text)
  if self.targetText == localizedText then
    return
  end
  instant = true
  self.lastLetterTime = 0
  if instant then
    self.currentText = localizedText
    if self.onTextComplete then
      self:onTextComplete()
    end
  else
    self.currentText = ""
  end
  self.targetText = localizedText
  self.inColorTag = false
  self.startOfWordForNewLinePos = nil
  self.Dialog.Text("text"):SetString(self.currentText)
end
function Dialog:CompleteText()
  self.currentText = self.targetText
  self.Dialog.Text("text"):SetString(self.currentText)
  if self.onTextComplete then
    self:onTextComplete()
  end
end
function Dialog:IsTextComplete()
  return self.currentText == self.targetText
end
function Dialog:SetDialogs(dialogSteps)
  self.dialogSteps = dialogSteps
  self.currentDialogIndex = 1
  if #dialogSteps > 0 then
    self.NextButton:DoStoredScript("setVisible")
  end
  self:showDialog(self.currentDialogIndex)
end
function Dialog:PreviousDialog()
  self.currentDialogIndex = self.currentDialogIndex - 1
  if self.currentDialogIndex <= 1 then
    self.currentDialogIndex = 1
  end
  self:showDialog(self.currentDialogIndex)
end
function Dialog:NextDialog()
  if not self:IsTextComplete() then
    self:CompleteText()
    return
  end
  self.currentDialogIndex = self.currentDialogIndex + 1
  if self.currentDialogIndex > #self.dialogSteps then
    if self.onAllDialogsCompleted then
      self:onAllDialogsCompleted()
    end
    return
  end
  self:showDialog(self.currentDialogIndex)
end
function Dialog:showDialog(dialogIndex)
  self:SetAvatar(self.dialogSteps[dialogIndex].Avatar)
  self:SetText(self.dialogSteps[dialogIndex].Dialog, false)
  if self.dialogSteps[dialogIndex].SFX then
    lua_sys.playSoundFx(self.dialogSteps[dialogIndex].SFX)
  end
  if self.onDialogChanged then
    self:onDialogChanged(dialogIndex)
  end
  if dialogIndex <= 1 then
    self.PreviousButton:DoStoredScript("setInvisible")
  else
    self.PreviousButton:DoStoredScript("setVisible")
  end
end
return Dialog
