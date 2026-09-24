local Genes = include("Genes")
local BOMUnownedAvail = {}
local e_MonsterTemplate, c_LimitedTimeLabelText, c_TimeRemainingText
local function onTickRemainingText(component, element, dt)
  if element("PrevTimedAvail"):GetInt() == 1 and element:parent()("levelLocked"):GetInt() == 0 then
    local monsterId = element:root():GetElement("SelectedMonsterView")("selectedMonst"):GetInt()
    if monsterId ~= -1 then
      local secsRemaining = game.timedAvailMonsterTimeRemaining(monsterId)
      if secsRemaining <= 0 then
        element("PrevTimedAvail"):SetInt(0)
        if e_MonsterTemplate ~= nil then
          e_MonsterTemplate:DoStoredScript("Refresh")
        end
        element:parent():DoStoredScript("queuePop")
      else
        component("text"):SetString("" .. game.timeToString(secsRemaining))
      end
    end
  end
end
local function initializeChildren(element)
  c_LimitedTimeLabelText = element:GetElement("LimitedTimeLabel"):GetComponent("Text")
  c_TimeRemainingText = element:GetElement("TimeRemaining"):GetComponent("Text")
  c_TimeRemainingText:addLuaFunction("onTick", onTickRemainingText)
end
function BOMUnownedAvail.onInit(element)
  initializeChildren(element)
  local monsterType = element:root():GetElement("SelectedMonsterView")("selectedMonst"):GetInt()
  element("selectedMonster"):SetInt(monsterType)
  collectgarbage("stop")
  element("levelLocked"):SetInt(game.playerLevel() < game.monsterUnlockLevel(monsterType) and 1 or 0)
  if element("levelLocked"):GetInt() == 1 then
    local numGenes = game.monsterTypeNumGenes(monsterType)
    element("numGenes"):SetInt(numGenes)
    Genes.InitForMonsterId(monsterType, element:GetElement("ImageFrame"), {
      layer = "FrontPopUps",
      spacing = -2 * game.hudScale(),
      prefix = "geneItem",
      priority = -4,
      vAnchor = lua_sys.BOTTOM,
      offsetY = -4 * game.menuScaleY()
    })
  else
    element("numGenes"):SetInt(0)
  end
end
function BOMUnownedAvail.onPostInit(element)
  local monsterType = element:root():GetElement("SelectedMonsterView")("selectedMonst"):GetInt()
  if element("levelLocked"):GetInt() == 1 then
    element:DoStoredScript("setBuyInvis")
    element.Animation.Sprite:DoStoredScript("setLocked")
    element.InfoTitle.Title("text"):SetString("MISSING_MONSTER_TITLE")
    if game.getBookOfMonstersIslandType() ~= game.IslandType_GOLD then
      element.InfoContent.Text("text"):SetString("MYSTERY_MONSTER_LOCKED_DESC")
    end
    element.ImageFrame:DoStoredScript("showChains")
    element.InfoFrame:DoStoredScript("setLocked")
    element:GetElement("LimitedTimeLabel"):GetComponent("Text")("visible"):SetInt(0)
    element:GetElement("TimeRemaining"):GetComponent("Text")("visible"):SetInt(0)
    element:GetElement("GoodLuckLabel"):GetComponent("Text")("visible"):SetInt(0)
  end
  local book = element:parent()
  local monsterList = book:GetElement("MonsterList")
  local numMonsters = monsterList("NumMonsters"):GetInt()
  for i = 0, numMonsters - 1 do
    local monster = monsterList:GetElement("monsterEntry" .. i)
    if monster ~= nil and monster.MonsterID == monsterType then
      e_MonsterTemplate = monster
      break
    end
  end
end
return BOMUnownedAvail
