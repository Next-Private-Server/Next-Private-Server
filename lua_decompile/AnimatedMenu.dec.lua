local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local AnimatedMenu = {}
AnimatedMenu.__index = AnimatedMenu
function AnimatedMenu.Create()
  local animatedMenu = {AnimatedMenu = AnimatedMenu}
  setmetatable(animatedMenu, AnimatedMenu)
  return animatedMenu
end
function AnimatedMenu:onInit()
  self.transitionState = 0
  local startX = -lua_sys.screenWidth()
  local startY = 0
  OffsetTransition.OnInit(self, {
    duration = 0.333,
    startX = startX,
    startY = startY,
    endX = 0,
    endY = 0
  })
  self.fader = self:E("FadedBG"):C("Sprite")
  self.fader.FadeTransition = FadeTransition:new({
    duration = 0.333,
    maxFade = 0.5,
    onUpdate = function(alpha)
      self.fader:GetVar("alpha"):SetFloat(alpha)
    end
  })
  self("xOffset"):SetFloat(startX)
  self("yOffset"):SetFloat(startY)
  self:updateClipping()
end
function AnimatedMenu:onPostInit()
  self.transitionState = 1
  OffsetTransition.Show(self)
  self.fader.FadeTransition:Show()
  lua_sys.playSoundFx("audio/sfx/quest_icon_open.wav")
end
function AnimatedMenu:onTick(dt)
  if self.transitionState ~= 0 then
    OffsetTransition.OnTick(self, dt, {
      onDoneShow = function(e)
        self.transitionState = 0
      end,
      onDoneHide = function(e)
        self.transitionState = 0
        self:root():popPopUp()
        if self.onClosed ~= nil then
          for _, v in ipairs(self.onClosed) do
            v()
          end
        end
      end
    })
    self.fader.FadeTransition:Tick(dt)
    self:updateClipping()
  end
end
function AnimatedMenu:updateClipping()
  local frame = self:E("bg")
  local titleFrame = self:E("TitleFrame")
  local clipX = (frame:absX() + 10) * lua_sys.deviceScaleX()
  local clipY = (titleFrame:absY() + titleFrame:absH() + 2) * lua_sys.deviceScaleY()
  local clipWidth = (frame:absW() - 20) * lua_sys.deviceScaleX()
  local clipHeight = (frame:absH() - 50 * game.hudScale()) * lua_sys.deviceScaleY()
  game.setClipping("Clipping", clipX, clipY, clipWidth, clipHeight)
end
function AnimatedMenu:queuePop()
  self.transitionState = 2
  OffsetTransition.Hide(self)
  self.fader.FadeTransition:Hide()
end
return AnimatedMenu
