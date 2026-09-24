local BoxInventoryEggList = include("BoxInventoryEggList")
local ZapInventoryEggList = BoxInventoryEggList:new()
function ZapInventoryEggList:populateEggsRequired(boxMonsterId)
  self.eggIdsRequired = game.getRequiredUnderlingMonsterEggs(boxMonsterId)
end
function ZapInventoryEggList:populateEggsPossessed(boxMonsterId)
  self.eggIdsPossessed = game.getEggsInInactiveUnderlingMonster(boxMonsterId)
end
function ZapInventoryEggList:onInit()
  local defaultTemplateToUse = "template_underlinginventoryentry"
  self:buildEntries(self:parent():V("monsterUid"):GetInt(), defaultTemplateToUse, true)
end
return ZapInventoryEggList
