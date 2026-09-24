local OffsetTransition = include("MenuElementPositionOffsetTransition")
local GhostInfo = {
  FadedBG = {},
  InfoFrame = {
    Sprite = {}
  },
  InfoContent = {
    Text = {}
  },
  Animation = {
    Sprite = {}
  },
  ImageTitle = {
    Text = {}
  }
}
function GhostInfo:onInit()
  self.infoFrameEndX = -300 * game.windowScaleX()
  self.infoFrameEndY = -1.1 * lua_sys.deviceMarginY()
  local overlapHorz = self.InfoFrame:absW() / lua_sys.screenWidth() > 0.44
  local contextBarHeight = game.contextBarHeight()
  local availableSpace = lua_sys.screenHeight() - contextBarHeight - contextBarHeight
  local overlapVert = availableSpace <= self.InfoFrame:absH()
  if overlapHorz and overlapVert then
    self.infoFrameEndY = (self.InfoFrame:absH() - availableSpace) / -2 + lua_sys.deviceMarginY()
  end
  self.ImageFrame:Init()
  self.ImageFrame.onDoneHide = nil
  local imageFrameTransition = self.ImageFrame.OffsetTransition
  imageFrameTransition.delayOnStart = 0.5
  imageFrameTransition.duration = 0.25
  imageFrameTransition.startX = 30 * game.hudScale()
  imageFrameTransition.startY = self.infoFrameEndY
  imageFrameTransition.endX = -160 * game.windowScaleX()
  imageFrameTransition.endY = self.infoFrameEndY
  imageFrameTransition.ease = lua_sys.Linear_EaseNone
  OffsetTransition.OnInit(self.InfoFrame, {
    delayOnStart = 0.6,
    duration = 0.3,
    startX = 0,
    startY = self.infoFrameEndY,
    endX = self.infoFrameEndX,
    endY = self.infoFrameEndY
  })
  local selectedObject = game.SelectedObject()
  if selectedObject and selectedObject:isMonster() and selectedObject:data():isModal() then
    local currentMode = game.player():getActiveIsland():islandMode()
    local animFile = selectedObject:data():animationFile()
    self.Animation.Sprite("animationName"):SetString("xml_bin/" .. animFile)
    if currentMode == 0 then
      self.Animation.Sprite("animation"):SetString("Store")
    else
      self.Animation.Sprite("animation"):SetString("Store_MIN")
    end
    self.Animation.Sprite:setScale(lua_sys.Vector2(0.7 * game.menuScaleX(), 0.7 * game.menuScaleX()))
    self.Animation.Sprite("offsetCenter"):SetInt(1)
    self.Animation.Sprite("layer"):SetString("PopUps")
  end
end
function GhostInfo:onPostInit()
  self.ImageFrame:Show()
  OffsetTransition.Show(self.InfoFrame)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  transitionState = 1
end
function GhostInfo:onTick(dt)
  OffsetTransition.OnTick(self.InfoFrame, dt, {
    ease = lua_sys.Linear_EaseNone
  })
end
function GhostInfo:queuePop()
  manager:hideContextBar()
  transitionState = 2
  self.FadedBG:Hide()
  self.ImageFrame:Hide()
  OffsetTransition.Hide(self.InfoFrame)
end
function GhostInfo.FadedBG:onDoneHide()
  self.Touch:V("enabled"):SetInt(0)
  self:root():popPopUp()
  manager:setContext(manager:reserveState())
end
function GhostInfo.InfoFrame.Sprite:onInit(element)
  self("topHeight"):SetFloat(50)
  self("bottomHeight"):SetFloat(50)
  self("leftWidth"):SetFloat(50)
  self("rightWidth"):SetFloat(50)
  self("size"):SetFloat(0.5 * game.menuScaleX())
  self("includeBorder"):SetInt(1)
  self("spriteName"):SetString("gfx/menu/Black9SFrame50")
  self("layer"):SetString("PopUps")
end
return GhostInfo
