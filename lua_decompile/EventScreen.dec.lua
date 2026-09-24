local EventScreen = {
  bg = {
    Sprite = {},
    TopLeft = {},
    TopRight = {},
    BottomRight = {}
  },
  TitleImage = {
    Sprite = {}
  },
  Subtitle = {
    Text = {},
    Sprite = {}
  },
  Glow = {
    Sprite = {}
  },
  Platform = {
    Sprite = {}
  },
  Monster = {
    Sprite = {}
  },
  MainImage = {
    Sprite = {}
  },
  Description1 = {
    Text = {}
  },
  Description2 = {
    Text = {}
  },
  CloseButton = {}
}
function EventScreen:onInit()
end
function EventScreen:onPostInit()
  if game.currentLanguage() ~= "en" then
    self.Subtitle.Text("visible"):SetInt(1)
    self.Subtitle.Sprite("visible"):SetInt(1)
  else
    self.Subtitle.Text("visible"):SetInt(0)
    self.Subtitle.Sprite("visible"):SetInt(0)
  end
end
function EventScreen:onContinueButton()
  self:root():popPopUp()
  if self.onContinue then
    self:onContinue()
  end
end
function EventScreen:onCloseButton()
  self:root():popPopUp()
  if self.onClose then
    self:onClose()
  end
  self:root():GetReceiver():Send(game.MsgEventScreenClosed())
end
return EventScreen
