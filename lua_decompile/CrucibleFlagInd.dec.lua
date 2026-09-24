local CrucibleFlagInd = {}
local c_Touch, c_Sprite
local onInitTouch = function(component, element)
  if not game.isQABuild() then
    component("enabled"):SetInt(0)
  end
end
local function onTouchUp(component, element)
  if element("QABuildActive"):GetInt() == 0 then
    element("QABuildActive"):SetInt(1)
    c_Sprite:setColor(1, 1, 1)
  else
    element("QABuildActive"):SetInt(0)
    c_Sprite:setColor(0.25, 0.25, 0.25)
  end
  local entryParent = element:parent():parent().LeftMonsterList
  local numEntries = entryParent("NumEntries"):GetInt()
  for i = 0, numEntries - 1 do
    local entry = entryParent:GetElement("crucibleEntry" .. i)
    local genes = entry.Genes
    local monsterType = genes("MonsterId"):GetInt()
    local numGenes = game.monsterTypeNumGenes(monsterType)
    for i = 0, numGenes - 1 do
      local geneEntry = genes:GetElement("entry" .. i)
      if geneEntry ~= nil then
        geneEntry("QABuildActive"):SetInt(element("QABuildActive"):GetInt())
        if not game.QAmonsterTypeGeneFlagged(monsterType, i) or entry("disabled"):GetInt() == 1 then
          geneEntry.Sprite:setColor(0.25, 0.25, 0.25)
        else
          geneEntry.Sprite:setColor(1, 1, 1)
        end
      end
    end
  end
end
local checkActive = function(component, element)
  local active = false
  if not game.isQABuild() then
    active = game.flagActive(element("flagInd"):GetInt(), true)
  else
    active = element("QABuildActive"):GetInt() ~= 0
  end
  if not active then
    component:setColor(0.25, 0.25, 0.25)
  end
end
local function initializeChildren(element)
  c_Touch = element:GetComponent("Touch")
  c_Touch:addLuaFunction("onInit", onInitTouch)
  c_Touch:addLuaFunction("onTouchUp", onTouchUp)
  c_Sprite = element:GetComponent("Sprite")
  c_Sprite:addLuaFunction("checkActive", checkActive)
end
function CrucibleFlagInd.onInit(element)
  element:DoStoredScript("initTemplateVar")
  initializeChildren(element)
  element("QABuildActive"):SetInt(0)
end
return CrucibleFlagInd
