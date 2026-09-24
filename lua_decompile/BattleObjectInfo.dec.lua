local OffsetTransition = include("MenuElementPositionOffsetTransition")
local SharedObjectInfo = include("SharedObjectInfo")
local Genes = include("Genes")
local BattleObjectInfo = SharedObjectInfo:new({
  MovesList = {NumEntries = 0},
  MovesButton = {
    Label = {},
    Touch = {}
  }
})
local infoFrameEndY = -26 * game.menuScaleY()
local function _initGenes(element)
  if game.selectedObjIsMonster() then
    local monsterId = game.monsterTypeId(game.selectedMonsterId())
    Genes.InitForMonsterId(monsterId, element, {
      layer = "PopUps",
      spacing = -2 * game.hudScale(),
      prefix = "geneItem",
      priority = -4,
      vAnchor = lua_sys.BOTTOM,
      offsetY = -4 * game.menuScaleY()
    })
  end
end
function BattleObjectInfo:onInit()
  self.ImageFrame:Init()
  self.ImageFrame.onDoneHide = nil
  local imageFrameTransition = self.ImageFrame.OffsetTransition
  imageFrameTransition.delayOnStart = 0.5
  imageFrameTransition.duration = 0.25
  imageFrameTransition.startX = 30 * game.hudScale()
  imageFrameTransition.startY = infoFrameEndY
  imageFrameTransition.endX = -160 * game.windowScaleX()
  imageFrameTransition.endY = infoFrameEndY
  imageFrameTransition.ease = lua_sys.Linear_EaseNone
  OffsetTransition.OnInit(self.InfoFrame, {
    delayOnStart = 0.6,
    duration = 0.3,
    startX = 0,
    startY = infoFrameEndY,
    endX = self.infoFrameEndX,
    endY = infoFrameEndY
  })
  _initGenes(self.ImageFrame)
  collectgarbage("stop")
end
function BattleObjectInfo:initCurrentView()
  self.currentView = 0
end
function BattleObjectInfo:refreshView()
  print("Refresh Current View:", self.currentView)
  if self.currentView == 0 then
    print("Show Bio")
    self.InfoContent.Text:V("visible"):SetInt(1)
    self.InfoFrame.Touch:V("enabled"):SetInt(1)
    self.BioButton:enable()
    self.BioButton.Touch:V("enabled"):SetInt(0)
    if self.InfoContent.Text:absH() > self.InfoContent:absH() then
      self.ScrollBar.Sprite:V("visible"):SetInt(1)
      self.ScrollMarker.Marker:V("visible"):SetInt(1)
    end
  else
    self.BioButton:disable()
    self.BioButton.Touch:V("enabled"):SetInt(1)
    self.InfoContent.Text:V("visible"):SetInt(0)
    self.InfoFrame.Touch:V("enabled"):SetInt(0)
    self.ScrollBar.Sprite:V("visible"):SetInt(0)
    self.ScrollMarker.Marker:V("visible"):SetInt(0)
  end
  if self.currentView == 1 then
    self.StatsButton:enable()
    self.StatsButton.Touch:V("enabled"):SetInt(0)
    self.StatsList:showStats()
  else
    self.StatsButton:disable()
    self.StatsButton.Touch:V("enabled"):SetInt(1)
    self.StatsList:hideStats()
  end
  if self.currentView == 2 then
    self.MovesButton:enable()
    self.MovesButton.Touch("enabled"):SetInt(0)
    self.MovesList:showMoves()
  else
    self.MovesButton:disable()
    self.MovesButton.Touch("enabled"):SetInt(1)
    self.MovesList:hideMoves()
  end
end
function BattleObjectInfo.BlackCover:onPostInit()
  local helpers = include("MenuHelpers")
  helpers.CenterHorizontally({
    self:parent().BioButton,
    self:parent().StatsButton,
    self:parent().MovesButton
  })
end
function BattleObjectInfo.Animation:onInit()
  local component = self.Sprite
  component("animationName"):SetString("xml_bin/" .. game.objectAnim())
  if game.selectedObjectIsActiveBoxMonster() then
    component("animation"):SetString("Activate")
    component:setScale(Vector2(0.3 * game.menuScaleX(), 0.3 * game.menuScaleX()))
    component("pingpong"):SetInt(1)
    self:setOrientationPosition(Vector2(component:size().x / 2, component:size().y / 2 + component:size().y / 4))
  else
    component("animation"):SetString(game.objectStoreAnim())
    component:setScale(Vector2(0.75 * game.menuScaleX(), 0.75 * game.menuScaleX()))
    self:setOrientationPosition(Vector2(component:size().x / 2, component:size().y / 2 + 15 * game.hudScale()))
  end
  local selectedMonsterId = game.selectedMonsterId()
  local equippedCostume = game.getEquippedCostumeForMonster(selectedMonsterId)
  game.applyCostumeToAnimComponent(component, equippedCostume)
  component("visible"):SetInt(0)
  component("layer"):SetString("PopUps")
end
return BattleObjectInfo
