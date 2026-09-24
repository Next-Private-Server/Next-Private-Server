HowItWorksDialog = {
  FadedBG = {
    Sprite = {},
    Touch = {}
  },
  Dialog = {},
  Left = {
    Sprite = {}
  },
  Center = {
    Sprite = {}
  },
  Right = {
    Sprite = {}
  }
}
HowItWorksDialog.HOW_TO_STATE = {
  NONE = 0,
  FIRST_PANEL = 1,
  SECOND_PANEL = 2,
  THIRD_PANEL = 3,
  ALL = 4
}
HowItWorksDialog.HowItWorksDialogStep = {
  HowToState = HowItWorksDialog.HOW_TO_STATE.NONE
}
function HowItWorksDialog:onInit()
  self.dialogSteps = {}
  function self.Dialog.onDialogChanged(e, dialogIndex)
    self:showStep(dialogIndex)
  end
  function self.Dialog.onAllDialogsCompleted(e)
    if self.onAllDialogsCompleted then
      self:onAllDialogsCompleted()
    end
  end
end
function HowItWorksDialog:SetLeftInfo(animationName, animation)
  self.Left.Sprite("animationName"):SetString(animationName)
  self.Left.Sprite("animation"):SetString(animation)
end
function HowItWorksDialog:SetCenterInfo(animationName, animation)
  self.Center.Sprite("animationName"):SetString(animationName)
  self.Center.Sprite("animation"):SetString(animation)
end
function HowItWorksDialog:SetRightInfo(animationName, animation)
  self.Right.Sprite("animationName"):SetString(animationName)
  self.Right.Sprite("animation"):SetString(animation)
end
function HowItWorksDialog:Setup(dialogSteps)
  self.dialogSteps = dialogSteps
  self.Dialog:SetDialogs(self.dialogSteps)
end
function HowItWorksDialog:showStep(stepNum)
  if self.dialogSteps[stepNum].HowToState == HowItWorksDialog.HOW_TO_STATE.NONE then
    self.FadedBG.Sprite("visible"):SetInt(0)
    self.Left.Sprite("visible"):SetInt(0)
    self.Center.Sprite("visible"):SetInt(0)
    self.Right.Sprite("visible"):SetInt(0)
  else
    self.FadedBG.Sprite("visible"):SetInt(1)
    self.Left.Sprite("visible"):SetInt(1)
    self.Center.Sprite("visible"):SetInt(1)
    self.Right.Sprite("visible"):SetInt(1)
    self.Left.Sprite:setOrientationPriority(10)
    self.Center.Sprite:setOrientationPriority(10)
    self.Right.Sprite:setOrientationPriority(10)
    if self.dialogSteps[stepNum].HowToState == HowItWorksDialog.HOW_TO_STATE.FIRST_PANEL or self.dialogSteps[stepNum].HowToState == HowItWorksDialog.HOW_TO_STATE.ALL then
      self.Left.Sprite:setOrientationPriority(-1)
    end
    if self.dialogSteps[stepNum].HowToState == HowItWorksDialog.HOW_TO_STATE.SECOND_PANEL or self.dialogSteps[stepNum].HowToState == HowItWorksDialog.HOW_TO_STATE.ALL then
      self.Center.Sprite:setOrientationPriority(-1)
    end
    if self.dialogSteps[stepNum].HowToState == HowItWorksDialog.HOW_TO_STATE.THIRD_PANEL or self.dialogSteps[stepNum].HowToState == HowItWorksDialog.HOW_TO_STATE.ALL then
      self.Right.Sprite:setOrientationPriority(-1)
    end
  end
end
return HowItWorksDialog
