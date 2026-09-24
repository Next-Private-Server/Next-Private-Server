local HowItWorks = {
  FadedBG = {
    Sprite = {},
    Touch = {}
  },
  TitleFrame = {
    Sprite = {},
    Text = {}
  },
  Left = {
    Sprite = {},
    Text = {}
  },
  LeftArrow = {},
  Center = {
    Sprite = {},
    Text = {}
  },
  RightArrow = {},
  Right = {
    Sprite = {},
    Text = {}
  },
  CloseButton = {
    Touch = {}
  }
}
function HowItWorks:SetTitleText(text)
  self.TitleFrame.Text("text"):SetString(text)
end
function HowItWorks:SetLeftInfo(animationName, animation, text)
  self.Left.Sprite("animationName"):SetString(animationName)
  self.Left.Sprite("animation"):SetString(animation)
  self.Left.Text("text"):SetString(text)
end
function HowItWorks:SetCenterInfo(animationName, animation, text)
  self.Center.Sprite("animationName"):SetString(animationName)
  self.Center.Sprite("animation"):SetString(animation)
  self.Center.Text("text"):SetString(text)
end
function HowItWorks:SetRightInfo(animationName, animation, text)
  self.Right.Sprite("animationName"):SetString(animationName)
  self.Right.Sprite("animation"):SetString(animation)
  self.Right.Text("text"):SetString(text)
end
function HowItWorks:Hide()
  self.FadedBG.Sprite("visible"):SetInt(0)
  self.TitleFrame.Sprite("visible"):SetInt(0)
  self.TitleFrame.Text("visible"):SetInt(0)
  self.Left.Sprite("visible"):SetInt(0)
  self.Left.Text("visible"):SetInt(0)
  self.LeftArrow("visible"):SetInt(0)
  self.Center.Sprite("visible"):SetInt(0)
  self.Center.Text("visible"):SetInt(0)
  self.RightArrow("visible"):SetInt(0)
  self.Right.Sprite("visible"):SetInt(0)
  self.Right.Text("visible"):SetInt(0)
  self.CloseButton:DoStoredScript("setInvisible")
end
function HowItWorks:Show()
  self.FadedBG.Sprite("visible"):SetInt(1)
  self.TitleFrame.Sprite("visible"):SetInt(1)
  self.TitleFrame.Text("visible"):SetInt(1)
  self.Left.Sprite("visible"):SetInt(1)
  self.Left.Text("visible"):SetInt(1)
  self.LeftArrow("visible"):SetInt(1)
  self.Center.Sprite("visible"):SetInt(1)
  self.Center.Text("visible"):SetInt(1)
  self.RightArrow("visible"):SetInt(1)
  self.Right.Sprite("visible"):SetInt(1)
  self.Right.Text("visible"):SetInt(1)
  self.CloseButton:DoStoredScript("setVisible")
end
return HowItWorks
