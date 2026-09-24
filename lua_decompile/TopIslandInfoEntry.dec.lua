local TopIslandInfoEntry = {}
TopIslandInfoEntry.topIslandInfo = nil
TopIslandInfoEntry.isComposer = false
TopIslandInfoEntry.isTribal = false
TopIslandInfoEntry.tribalIndex = 0
function TopIslandInfoEntry.onInit(element)
end
function TopIslandInfoEntry.SetIslandInfo(element, islandInfo, isComposer)
  TopIslandInfoEntry.topIslandInfo = islandInfo
  TopIslandInfoEntry.isComposer = isComposer
  TopIslandInfoEntry.isTribal = false
  element:C("bg")("spriteName"):SetString("gfx/menu/friendPurple" .. math.fmod(islandInfo:rank(), 2))
  element:C("Rank")("text"):SetString(islandInfo:rank())
  element:C("UserName")("text"):SetString(islandInfo:userName())
  element:C("IslandName")("text"):SetString(game.islandName(islandInfo:islandTypeId()))
  element:C("TribeSprite")("visible"):SetInt(0)
  local islandIcon = element:C("IslandSprite")
  if isComposer then
    islandIcon("spriteName"):SetString(game.islandIconSpriteForId(11))
    islandIcon("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(11))
  else
    islandIcon("spriteName"):SetString(game.islandIconSpriteForId(islandInfo:islandTypeId()))
    islandIcon("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(islandInfo:islandTypeId()))
  end
end
function TopIslandInfoEntry.SetTribalIslandInfo(element, tribalIndex)
  TopIslandInfoEntry.topIslandInfo = nil
  TopIslandInfoEntry.isComposer = false
  TopIslandInfoEntry.isTribal = true
  TopIslandInfoEntry.tribalIndex = tribalIndex
  element:C("bg")("spriteName"):SetString("gfx/menu/friendPurple" .. math.fmod(tribalIndex + 1, 2))
  element:C("Rank")("text"):SetString(tribalIndex + 1)
  element:C("UserName")("text"):SetString(game.getTopTribeName(tribalIndex))
  element:C("IslandName")("text"):SetString(game.getLocalizedText("FRIEND_LEVEL_ABBREV_TAG") .. " " .. game.getTopTribeRank(tribalIndex))
  element:C("IslandSprite")("visible"):SetInt(0)
  element:C("TribeSprite")("spriteName"):SetString(game.getTribeMonsterPic(game.getTopTribeChiefMonster(tribalIndex)))
end
function TopIslandInfoEntry.OnVisitButton(element)
  if TopIslandInfoEntry.isComposer then
    game.visitRankedComposerIsland(TopIslandInfoEntry.topIslandInfo:rank())
  elseif TopIslandInfoEntry.isTribal then
    game.visitTribalIsland(game.getTopTribeID(TopIslandInfoEntry.tribalIndex), true)
  else
    game.visitRankedIsland(TopIslandInfoEntry.topIslandInfo:rank())
  end
  element:root():popPopUp()
end
return TopIslandInfoEntry
