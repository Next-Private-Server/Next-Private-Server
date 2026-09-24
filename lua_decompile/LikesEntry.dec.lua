local Touch = {}
local LikesEntry = {Touch = Touch}
function Touch:onInit(element)
  self.dragging = 0
  self.touchStart = 0
end
function Touch:onTouchDown(element, x, y)
  element:buttonDown()
  self.touchStart = x
end
function Touch:onTouchDrag(element, x, y, relX, relY, dx, dy)
  self.dragging = self.dragging + math.abs(x - self.touchStart)
  self.touchStart = x
end
function Touch:onTouchUp(element)
  element:buttonUp()
  if self:absX() + self:absW() >= self:parent():absX() + 16 * game.menuScaleX() and self:absX() <= self:parent():absX() + self:parent():absW() - 16 * game.menuScaleX() then
    if self.dragging < 10 then
      self:parent():touch()
    end
    self.dragging = 0
    self.touchStart = 0
  end
end
function Touch:onTouchRelease(element)
  element:buttonUp()
  self.dragging = 0
  self.touchStart = 0
end
function LikesEntry:touch()
  if game.playerLevel() >= game.entityUnlockLevel(self.EntityId) then
    if game.IsBoxFromEntityId(self.EntityId) and not game.hasRoomForBoxMonsterEgg(self.EntityId) then
      game.displayNotification("NOTIFICATION_ALREADY_INACTIVE_BOX")
    elseif game.viewInMarket(self.EntityId) or game.viewInStarMarket(self.EntityId) then
      game.pushPopUp("ingame_buy")
      game.setPurchaseEntityId(self.EntityId)
    elseif game.IsEvolvedMonsterFromEntityId(self.EntityId) then
      if game.isEtherealIslet() then
        game.displayNotification("MONSTER_OBTAIN_HOW_TO_OBTAIN_ISLET")
      else
        game.displayNotification("MYSTERY_MONSTER_WUB_EVOLVE_DESC")
      end
    elseif game.IsDipsterDigDipsterFromEntityId(self.EntityId) then
      if game.getInventoryAmount(self.EntityId) > 0 then
        game.pushPopUp("ingame_buy")
        game.setPurchaseEntityId(self.EntityId)
      else
        game.displayNotification("NOTIFICATION_EARN_FROM_DIPSTER_DIG")
      end
    else
      game.displayNotification("NOT_AVAILABLE_IN_MARKET")
    end
  else
    local txt = game.getLocalizedText("NOTIFICATION_UNLOCKS_AT_LEVEL")
    txt = select(1, txt:gsub("xxx", game.entityUnlockLevel(self.EntityId)))
    game.displayNotification(txt)
  end
end
return LikesEntry
