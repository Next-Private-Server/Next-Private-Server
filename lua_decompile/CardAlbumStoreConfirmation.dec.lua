local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local MenuHelpers = include("MenuHelpers")
local CardAlbumStoreConfirmation = {
  bg = {},
  Text = {},
  RewardList = {},
  YesButton = {},
  NoButton = {}
}
function CardAlbumStoreConfirmation:onPostInit()
  self.hiding = false
  self.cardAlbumEvent = game.getCurrentCardAlbumEvent()
  MenuElementPositionOffsetTransition.OnInit(self.bg, {
    startY = lua_sys.screenHeight() * 1,
    endY = -20 * game.menuScaleX(),
    duration = 0.33
  })
end
function CardAlbumStoreConfirmation:SetStoreItem(storeItemData)
  self:populateRewards(storeItemData.contents, {})
  local txt = game.getLocalizedText("CONFIRMATION_BUY_CARD_ALBUM_ITEM")
  txt = txt:gsub("%${NAME}", LOC(storeItemData.name))
  txt = txt:gsub("%${COST}", storeItemData.cost)
  self.Text:C("Text"):V("text"):SetString(txt)
  MenuElementPositionOffsetTransition.Show(self.bg)
end
function CardAlbumStoreConfirmation:queuePop()
  if self.hiding == false then
    MenuElementPositionOffsetTransition.Hide(self.bg)
    self.hiding = true
  end
end
function CardAlbumStoreConfirmation:onTick(dt)
  local secsRemaining = self.cardAlbumEvent:timeRemainingSec()
  if secsRemaining <= 0 and game.topPopUp() == self and self.hiding == false then
    game.popPopUp()
  end
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():removePopUp(self:name())
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self.bg, dt, options)
end
function CardAlbumStoreConfirmation:populateRewards(rewards, options)
  self.rewards = {}
  options = options or {}
  for i = 0, rewards:size() - 1 do
    local vars = {
      layer = "FrontPopUps",
      scale = 0.6 * game.windowScaleY()
    }
    local item = menu:addTemplateElementEx("template_card_album_reward", "entry" .. i - 1, self.RewardList, vars)
    item:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    item:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.LEFT, lua_sys.VCENTER))
    item:init()
    item:setPositionBroadcast(true)
    item:postInit()
    item:Init(rewards[i], i, options)
    table.insert(self.rewards, item)
  end
  MenuHelpers.CenterHorizontally(self.rewards)
end
function CardAlbumStoreConfirmation:SubmitConfirmation(confirm)
  self.YesButton:disable()
  self.NoButton:disable()
  self:queuePop()
  game.submitConfirmation("BUY_CARD_ALBUM_ITEM", confirm, "")
end
return CardAlbumStoreConfirmation
