local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local CardAlbumEventOver = {
  bg = {},
  ExitButton = {
    Touch = {}
  },
  CardsBar = {
    BarText = {},
    BarSprite = {}
  },
  PagesBar = {
    BarText = {},
    BarSprite = {}
  }
}
function CardAlbumEventOver:onPostInit()
  self:V("cardsCollected"):SetInt(0)
  self:V("totalCards"):SetInt(0)
  self:V("pagesComplete"):SetInt(0)
  self:V("totalPages"):SetInt(0)
  MenuElementPositionOffsetTransition.OnInit(self.bg, {
    startY = lua_sys.screenHeight() * 1,
    endY = -20 * game.menuScaleX(),
    duration = 0.33
  })
  MenuElementPositionOffsetTransition.Show(self.bg)
  lua_sys.playSoundFx("audio/sfx/encore_event_over.ogg")
end
function CardAlbumEventOver:queuePop()
  self:root():popPopUp()
end
function CardAlbumEventOver:updateProgressBar()
  local totalCardsCollected = self:V("cardsCollected"):GetInt()
  local totalCards = self:V("totalCards"):GetInt()
  local barText = totalCardsCollected .. "/" .. totalCards
  self.CardsBar.BarText:V("text"):SetString(barText)
  local percentage = totalCardsCollected / totalCards
  self.CardsBar.BarSprite:V("maskWidth"):SetFloat(self.CardsBar.BarSprite:V("FullMaskW"):GetInt() * clamp(percentage, 0, 1))
  local pageComplete = self:V("pagesComplete"):GetInt()
  local totalPages = self:V("totalPages"):GetInt()
  local pagesBarText = pageComplete .. "/" .. totalPages
  self.PagesBar.BarText:V("text"):SetString(pagesBarText)
  local percentage = pageComplete / totalPages
  self.PagesBar.BarSprite:V("maskWidth"):SetFloat(self.PagesBar.BarSprite:V("FullMaskW"):GetInt() * clamp(percentage, 0, 1))
end
function CardAlbumEventOver:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      manager:setContext(manager:getDefaultContext())
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self.bg, dt, options)
end
function CardAlbumEventOver.ExitButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element)
  element:C("Overlay"):setColor(1, 1, 1)
  MenuElementPositionOffsetTransition.Hide(element:parent().bg)
  self:parent():Disable()
end
return CardAlbumEventOver
