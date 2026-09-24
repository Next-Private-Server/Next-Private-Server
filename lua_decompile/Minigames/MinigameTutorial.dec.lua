MinigameTutorial = {
  Dialog = {}
}
function MinigameTutorial:onPostInit()
  local dialogSteps = {
    {
      Avatar = "gfx/menu/minigames/minigame_alcordion_01",
      Dialog = "Make a tutorial bro",
      HowToState = HowItWorksDialog.HOW_TO_STATE.NONE
    }
  }
  local minigameContext = game.minigameContext()
  if minigameContext then
    if minigameContext:minigameId() == game.MinigameId_DIPSTER_DIG then
      self.Dialog:SetLeftInfo("xml_bin/mini_game_dip_info.bin", "mini_game_dip_info_01")
      self.Dialog:SetCenterInfo("xml_bin/mini_game_dip_info.bin", "mini_game_dip_info_02")
      self.Dialog:SetRightInfo("xml_bin/mini_game_dip_info.bin", "mini_game_dip_info_03")
      dialogSteps = {
        {
          Avatar = "gfx/menu/minigames/minigame_alcordion_01",
          Dialog = "TUTORIAL_DIPSTER_01",
          HowToState = HowItWorksDialog.HOW_TO_STATE.NONE
        },
        {
          Avatar = "gfx/menu/minigames/minigame_alcordion_02",
          Dialog = "TUTORIAL_DIPSTER_02",
          HowToState = HowItWorksDialog.HOW_TO_STATE.NONE
        },
        {
          Avatar = "",
          Dialog = "TUTORIAL_DIPSTER_03",
          HowToState = HowItWorksDialog.HOW_TO_STATE.FIRST_PANEL
        },
        {
          Avatar = "",
          Dialog = "TUTORIAL_DIPSTER_04",
          HowToState = HowItWorksDialog.HOW_TO_STATE.FIRST_PANEL
        },
        {
          Avatar = "",
          Dialog = "TUTORIAL_DIPSTER_05",
          HowToState = HowItWorksDialog.HOW_TO_STATE.SECOND_PANEL
        },
        {
          Avatar = "",
          Dialog = "TUTORIAL_DIPSTER_06",
          HowToState = HowItWorksDialog.HOW_TO_STATE.SECOND_PANEL
        },
        {
          Avatar = "",
          Dialog = "TUTORIAL_DIPSTER_07",
          HowToState = HowItWorksDialog.HOW_TO_STATE.THIRD_PANEL
        },
        {
          Avatar = "",
          Dialog = "TUTORIAL_DIPSTER_08",
          HowToState = HowItWorksDialog.HOW_TO_STATE.THIRD_PANEL
        },
        {
          Avatar = "gfx/menu/minigames/minigame_alcordion_03",
          Dialog = "TUTORIAL_DIPSTER_09",
          HowToState = HowItWorksDialog.HOW_TO_STATE.NONE
        }
      }
    else
      print("minigame_how_it_works: UNSUPPORTED MINIGAME", minigameContext:minigameId())
    end
    minigameContext:hideContextBar()
  end
  local minigameTopPrizes = self:root():GetElement("MinigameTopPrizes")
  if minigameTopPrizes and minigameTopPrizes.Hide then
    minigameTopPrizes:Hide()
  end
  function self.Dialog.onAllDialogsCompleted(e)
    game.minigameContext():markMinigameTutorialSeen()
    local minigameTopPrizes = self:root():GetElement("MinigameTopPrizes")
    if minigameTopPrizes and minigameTopPrizes.Show then
      minigameTopPrizes:Show()
    end
    game.minigameContext():showContextBar()
    self:root():popPopUp()
  end
  self.Dialog:Setup(dialogSteps)
end
return MinigameTutorial
