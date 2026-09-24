local OffsetTransition = include("MenuElementPositionOffsetTransition")
local ScrollingListHelperV2 = include("ScrollingListHelperV2")
local ClubboxWorldInfo = {
  FadedBG = {},
  InfoFrame = {
    Sprite = {}
  },
  InfoContent = {
    Touch = {},
    Swiper = {},
    Text = {}
  },
  Animation = {
    Sprite = {}
  },
  ImageTitle = {
    Text = {}
  },
  ScrollBar = {
    Sprite = {}
  },
  ScrollMarker = {
    Marker = {},
    Touch = {}
  }
}
function ClubboxWorldInfo:onInit()
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
  self.Animation.Sprite("animationName"):SetString("xml_bin/island_clubbox.bin")
  local prestigeLevel = game.currentClubboxPrestigeLevel()
  if prestigeLevel > 0 then
    local animUtil = game.AnimUtil(self.Animation.Sprite)
    animUtil:addSheetRemap("island_clubbox_sheet.xml", "island_clubbox_prestige_sheet.xml")
  end
  local pctComplete = game.currentClubboxPercentComplete()
  if pctComplete < 0.25 then
    self.Animation.Sprite("animation"):SetString("hype_0")
  elseif pctComplete < 0.5 then
    self.Animation.Sprite("animation"):SetString("hype_1")
  elseif pctComplete < 0.75 then
    self.Animation.Sprite("animation"):SetString("hype_2")
  else
    self.Animation.Sprite("animation"):SetString("hype_3")
  end
  self.Animation.Sprite:setScale(lua_sys.Vector2(0.25 * game.windowScaleY(), 0.25 * game.windowScaleY()))
  self.Animation.Sprite("offsetCenter"):SetInt(1)
  self.Animation.Sprite("yOffset"):SetFloat(32 * game.windowScaleY())
  self.Animation.Sprite("layer"):SetString("PopUps")
  self.Animation.Sprite("hFlip"):SetInt(1)
end
function ClubboxWorldInfo:onPostInit()
  self.scrollingList = ScrollingListHelperV2:new({
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    listenToEntryTouches = true,
    Element = self.InfoContent,
    entries = {
      self.InfoContent.Text
    }
  })
  self.scrollingList:Tick(0)
  local shouldShowScrollBar = self.scrollingList:GetContentSize() > self.scrollingList:GetViewSize()
  if not shouldShowScrollBar then
    self.ScrollBar.Sprite:V("visible"):SetInt(0)
    self.ScrollMarker.Marker:V("visible"):SetInt(0)
    self.ScrollMarker.Touch:V("enabled"):SetInt(0)
  end
  self.ImageFrame:Show()
  OffsetTransition.Show(self.InfoFrame)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  transitionState = 1
end
function ClubboxWorldInfo:onTick(dt)
  OffsetTransition.OnTick(self.InfoFrame, dt, {
    ease = lua_sys.Linear_EaseNone
  })
  if self.scrollingList then
    self.scrollingList:Tick(dt)
  end
  local clipE = self.InfoContent
  self.InfoContent.Text:setClipRect(clipE:absX(), clipE:absY(), clipE:absW(), clipE:absH())
  self:UpdateScrollMarker()
end
function ClubboxWorldInfo:UpdateScrollMarker()
  local markerBookend = self.ScrollMarker.originalYOffset
  local markerMovementHeight = self.ScrollBar:absH() - 2 * markerBookend - self.ScrollMarker:absH()
  local scrollMarkerYOffset = 0
  if 0 < self.scrollingList:GetScrollSize() then
    scrollMarkerYOffset = -(self.scrollingList:GetCurrentOffset() / self.scrollingList:GetScrollSize()) * markerMovementHeight
  end
  scrollMarkerYOffset = clamp(scrollMarkerYOffset, 0, markerMovementHeight)
  self.ScrollMarker:V("yOffset"):SetInt(markerBookend + scrollMarkerYOffset)
end
function ClubboxWorldInfo:queuePop()
  manager:hideContextBar()
  transitionState = 2
  self.FadedBG:Hide()
  self.ImageFrame:Hide()
  OffsetTransition.Hide(self.InfoFrame)
end
function ClubboxWorldInfo.FadedBG:onDoneHide()
  self.Touch:V("enabled"):SetInt(0)
  self:root():popPopUp()
  manager:setContext(manager:reserveState())
end
function ClubboxWorldInfo.InfoFrame.Sprite:onInit(element)
  self("topHeight"):SetFloat(50)
  self("bottomHeight"):SetFloat(50)
  self("leftWidth"):SetFloat(50)
  self("rightWidth"):SetFloat(50)
  self("size"):SetFloat(0.5 * game.hudScale())
  self("includeBorder"):SetInt(1)
  self("spriteName"):SetString("gfx/menu/Black9SFrame50")
  self("layer"):SetString("PopUps")
end
function ClubboxWorldInfo.ScrollMarker.Touch:onTouchDrag(element, x, y)
  local scrollBar = element:parent().ScrollBar
  local fromTopOfMarkerRange = y - scrollBar:absY() - element.originalYOffset
  local markerBookend = element.originalYOffset
  local scrollSize = element:parent().scrollingList:GetScrollSize()
  local scrollOffset = -(fromTopOfMarkerRange - markerBookend) / (scrollBar:absH() - 2 * markerBookend - element:absH()) * scrollSize
  scrollOffset = clamp(scrollOffset, -scrollSize, 0)
  element:parent().scrollingList:SetCurrentOffset(scrollOffset)
end
return ClubboxWorldInfo
