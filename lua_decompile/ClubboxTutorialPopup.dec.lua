local ClubboxTutorialPopup = {
  FadedBG = {},
  DJWordsLabel = {
    Text = {}
  },
  ContinueButton = {
    Touch = {}
  }
}
function ClubboxTutorialPopup:onInit()
  self("transitionState"):SetInt(1)
  self("transitionTime"):SetFloat(0)
  playSoundFx("audio/sfx/menu_slide.wav")
  manager:setContext("BLANK")
end
function ClubboxTutorialPopup:onPostInit()
  self:refreshView()
end
function ClubboxTutorialPopup:refreshView()
end
function ClubboxTutorialPopup.DJWordsLabel:populate(words)
  self.DJWordsLabel.Text("autoScale"):SetInt(0)
  self.DJWordsLabel.Text("size"):SetFloat(0.2 * (screenHeight() / 320))
  self.DJWordsLabel.Text("text"):SetString(words)
  self.DJWordsLabel.Text("autoScale"):SetInt(1)
end
return ClubboxTutorialPopup
