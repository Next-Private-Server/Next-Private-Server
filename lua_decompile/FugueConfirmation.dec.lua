local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local FugueConfrimation = {
  messageID = "START_FUGUE",
  choice = "none",
  Faded = {
    Sprite = {}
  },
  bg = {},
  TitleFrame = {},
  TitleLabel = {
    Text = {}
  },
  Text = {
    Text = {}
  },
  YesButton = {},
  NoButton = {}
}
function FugueConfrimation:onInit()
  self.choice = "none"
end
function FugueConfrimation:onPostInit()
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startX = lua_sys.screenWidth() * -1,
    endX = 0 * game.menuScaleX(),
    duration = 0.33
  })
  MenuElementPositionOffsetTransition.OnInit(self:E("StarCounter"), {
    startX = lua_sys.screenWidth() * -1,
    startY = 10 * game.menuScaleX(),
    endX = 10 * game.menuScaleX(),
    endY = 10 * game.menuScaleX(),
    duration = 0.33
  })
  self:Show()
end
function FugueConfrimation:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      if self.choice == "true" then
        self:root():popPopUp()
        game.submitConfirmation(self.messageID, true)
      else
        self:root():popPopUp()
        game.submitConfirmation(self.messageID, false)
      end
    end
  }
  local starCounterOptions = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
  MenuElementPositionOffsetTransition.OnTick(self:E("StarCounter"), dt, starCounterOptions)
end
function FugueConfrimation:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  MenuElementPositionOffsetTransition.Show(self:E("StarCounter"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function FugueConfrimation:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  MenuElementPositionOffsetTransition.Hide(self:E("StarCounter"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function FugueConfrimation:queuePop()
  self:Hide()
end
function FugueConfrimation:setCost(cost)
  local msg = game.getLocalizedText("CONFIRMATION_START_FUGUING")
  msg = msg:gsub("%${AMOUNT}", tostring(cost))
  self.Text:C("Text"):V("text"):SetString(msg)
end
return FugueConfrimation
