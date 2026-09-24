local MenuHelpers = include("MenuHelpers")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local DishHarmonzierResults = {
  bg = {
    Touch = {}
  },
  Description = {},
  EggLeft = {
    Sprite = {},
    Touch = {}
  },
  EggRight = {
    Sprite = {},
    Touch = {}
  },
  GeneCounters = {},
  TargetMeters = {},
  SkipButton = {
    Touch = {}
  }
}
local revealSounds = {}
revealSounds[1] = "structure_dishharmonizer_reveal_seq_01"
revealSounds[2] = "structure_dishharmonizer_reveal_seq_02"
revealSounds[3] = "structure_dishharmonizer_reveal_seq_03"
local monsterSoundData = {}
monsterSoundData[50] = {
  id = 50,
  sfx = "structure_dishharmonizer_reveal_tap_monster-G"
}
monsterSoundData[51] = {
  id = 51,
  sfx = "structure_dishharmonizer_reveal_tap_monster-K"
}
monsterSoundData[54] = {
  id = 54,
  sfx = "structure_dishharmonizer_reveal_tap_monster-J"
}
monsterSoundData[55] = {
  id = 55,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GK"
}
monsterSoundData[56] = {
  id = 56,
  sfx = "structure_dishharmonizer_reveal_tap_monster-JK"
}
monsterSoundData[57] = {
  id = 57,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GJ"
}
monsterSoundData[59] = {
  id = 59,
  sfx = "structure_dishharmonizer_reveal_tap_monster-JL"
}
monsterSoundData[75] = {
  id = 75,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GL"
}
monsterSoundData[77] = {
  id = 77,
  sfx = "structure_dishharmonizer_reveal_tap_monster-JM"
}
monsterSoundData[78] = {
  id = 78,
  sfx = "structure_dishharmonizer_reveal_tap_monster-KL"
}
monsterSoundData[79] = {
  id = 79,
  sfx = "structure_dishharmonizer_reveal_tap_monster-KM"
}
monsterSoundData[80] = {
  id = 80,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GM"
}
monsterSoundData[682] = {
  id = 682,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GJK"
}
monsterSoundData[683] = {
  id = 683,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GJM"
}
monsterSoundData[684] = {
  id = 684,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GKM"
}
monsterSoundData[685] = {
  id = 685,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GJL"
}
monsterSoundData[686] = {
  id = 686,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GKL"
}
monsterSoundData[708] = {
  id = 708,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GJKL"
}
monsterSoundData[736] = {
  id = 736,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GLM"
}
monsterSoundData[737] = {
  id = 737,
  sfx = "structure_dishharmonizer_reveal_tap_monster-JKL"
}
monsterSoundData[757] = {
  id = 757,
  sfx = "structure_dishharmonizer_reveal_tap_monster-JKM"
}
monsterSoundData[758] = {
  id = 758,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GJKM"
}
monsterSoundData[777] = {
  id = 777,
  sfx = "structure_dishharmonizer_reveal_tap_monster-JLM"
}
monsterSoundData[778] = {
  id = 778,
  sfx = "structure_dishharmonizer_reveal_tap_monster-GJLM"
}
monsterSoundData[796] = {
  id = 796,
  sfx = "structure_dishharmonizer_reveal_tap_monster-KLM"
}
monsterSoundData[856] = {
  id = 856,
  sfx = "structure_dishharmonizer_reveal_tap_monster-B0"
}
monsterSoundData[890] = {
  id = 890,
  sfx = "structure_dishharmonizer_reveal_tap_monster-B1"
}
monsterSoundData[946] = {
  id = 946,
  sfx = "structure_dishharmonizer_reveal_tap_monster-PRM_02"
}
function DishHarmonzierResults:onInit()
  self.geneNumbers = {
    4,
    3,
    2
  }
  self.maxNumGenes = 1
  self.numTaps = 0
  self.revealComplete = false
  self.pauseBeforeIntroTimer = 0.5
  self.doingPauseBeforeIntro = false
  self.introTimer = 1
  self.doingIntro = false
  self.outroTimer = 1
  self.doingOutro = false
  local dishHarmonizer = game.SelectedObject()
  self.genes = dishHarmonizer:getBaseGenes() .. dishHarmonizer:getMissingGene() .. dishHarmonizer:getPrimaryGene()
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = -10 * game.menuScaleY(),
    duration = 0.66
  })
  self:Show()
  self.Description.FadeTransition = FadeTransition:new({
    duration = 0.5,
    maxFade = 1,
    onDoneShow = function()
    end,
    onUpdate = function(alpha)
      self.Description:C("Text"):GetVar("alpha"):SetFloat(alpha)
    end
  })
  self.Description.FadeTransition:SetAlpha(0)
  game.setMidiFade(0.5, 1)
end
function DishHarmonzierResults:onPostInit()
  self:populateGeneCounters()
  self:populateTargetMeters()
  local dishHarmonizer = game.SelectedObject()
  local monsters = dishHarmonizer:monsterResults()
  self:initEgg(self.EggLeft, monsters[0].id)
  if monsters:size() > 1 then
    self:initEgg(self.EggRight, monsters[1].id)
  else
    self:initEgg(self.EggRight, monsters[0].id)
    self.EggRight.Sprite:V("visible"):SetInt(0)
  end
  self.bg.Touch:V("enabled"):SetInt(0)
end
function DishHarmonzierResults:initEgg(eggElement, id)
  local dishHarmonizer = game.SelectedObject()
  local monsterId = dishHarmonizer:getMonsterResultType(id)
  local monsterData = game.getMonsterData(monsterId)
  eggElement:V("MonsterId"):SetInt(monsterId)
  eggElement:V("GeneMonsterId"):SetInt(0)
  eggElement:V("MonsterResultId"):SetInt(id)
  if monsterData:isPrimordial() then
    local monsters = game.creatableMonstersWithGenes(dishHarmonizer:getPrimaryGene() .. dishHarmonizer:getBaseGenes(), 4, true)
    eggElement:V("GeneMonsterId"):SetInt(monsters[0])
    self.maxNumGenes = 4
    self.revealingPrimordial = true
  elseif #monsterData:unsortedGenes() > self.maxNumGenes then
    self.maxNumGenes = #monsterData:unsortedGenes()
  end
end
function DishHarmonzierResults:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneShow = function(e)
      self.doingPauseBeforeIntro = true
    end,
    onDoneHide = function(e)
      e:root():popPopUp()
      game.setMidiFade(1, 1)
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self.bg, dt, options)
  if self.doingPauseBeforeIntro then
    self.pauseBeforeIntroTimer = self.pauseBeforeIntroTimer - dt
    if self.pauseBeforeIntroTimer <= 0 then
      self:doIntro()
      self.doingPauseBeforeIntro = false
    end
  end
  if self.doingIntro then
    self.introTimer = self.introTimer - dt
    if 0 >= self.introTimer then
      self.doingIntro = false
      self.Description.FadeTransition:Show()
      self.bg.Touch:V("enabled"):SetInt(1)
    end
  end
  if self.doingOutro then
    self.outroTimer = self.outroTimer - dt
    if 0 >= self.outroTimer then
      self.doingOutro = false
      self.Description.Text:V("text"):SetString("DISH_HARMONIZING_REVEAL_COMPLETE_DESC")
      self.Description.FadeTransition:Show()
      self.revealComplete = true
    end
  end
  self.Description.FadeTransition:Tick(dt)
end
function DishHarmonzierResults:doIntro()
  self.doingIntro = true
  local dishHarmonizer = game.SelectedObject()
  local gotGene = false
  local gotMissingGene = false
  for i = 1, #self.genes do
    local gene = self.genes:sub(i, i)
    local entry = self.GeneCounters:E("counter_" .. gene)
    local numMonsterGenes = self:numGeneUsedToMakeMonster(gene)
    local geneResult = dishHarmonizer:getGeneResult(gene)
    if gene ~= dishHarmonizer:getPrimaryGene() then
      entry:setCounter(dishHarmonizer:getNumGenes(gene) + numMonsterGenes)
    end
    if geneResult > 0 then
      entry:fadeInOutColor(0.43, 0.98, 0.02, 0, 0.33, 0.33, 0.33)
      gotGene = true
      if gene == dishHarmonizer:getMissingGene() then
        entry:playAnimation()
        gotMissingGene = true
      end
    elseif geneResult < 0 then
      entry:fadeInOutColor(1, 0, 0, 0, 0.33, 0.33, 0.33)
    end
  end
  if gotMissingGene then
    lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_gaingenes_withunlock.ogg")
  elseif gotGene then
    lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_gaingenes.ogg")
  end
  for i = 1, #self.geneNumbers do
    local numGenes = self.geneNumbers[i]
    if dishHarmonizer:getMonsterTarget(numGenes) ~= 0 then
      local entry = self.TargetMeters:E("meter_" .. numGenes)
      if entry then
        entry:fillTo(dishHarmonizer:getMonsterTargetPercentage(numGenes), 0.5, 0.5)
      end
    end
  end
end
function DishHarmonzierResults:numGeneUsedToMakeMonster(gene)
  local dishHarmonizer = game.SelectedObject()
  local monsters = dishHarmonizer:monsterResults()
  local primaryGene = dishHarmonizer:getPrimaryGene()
  local numMonsterGenes = 0
  if primaryGene ~= gene then
    for j = 0, monsters:size() - 1 do
      local monsterId = monsters[j].monsterId
      local monsterData = game.getMonsterData(monsterId)
      if monsterData:isPrimordial() then
        numMonsterGenes = numMonsterGenes + dishHarmonizer:getMonsterResultCost(monsters[j].id, gene)
      else
        local monsterGenes = monsterData:unsortedGenes()
        if monsterGenes ~= nil and string.find(monsterGenes, gene) then
          numMonsterGenes = numMonsterGenes + dishHarmonizer:getMonsterResultCost(monsters[j].id, gene)
        end
      end
    end
  end
  return numMonsterGenes
end
function DishHarmonzierResults:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_menu_open.ogg")
end
function DishHarmonzierResults:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function DishHarmonzierResults:queuePop()
  self:Hide()
end
function DishHarmonzierResults:TouchedEgg(element)
  if self.revealComplete then
    self:ShowIncubateEgg(element:V("MonsterId"):GetInt(), element:V("MonsterResultId"):GetInt())
  end
end
function DishHarmonzierResults:ShowIncubateEgg(monster, monsterResultId)
  self:root():popPopUp()
  game.pushPopUp("popup_dish_harmonizer_incubate_egg")
  game.topPopUp():V("monster"):SetInt(monster)
  game.topPopUp():V("monsterResultId"):SetInt(monsterResultId)
  game.topPopUp():DoStoredScript("update")
  game.setMidiFade(1, 1)
end
function DishHarmonzierResults:tap()
  if self.numTaps < self.maxNumGenes then
    self.numTaps = self.numTaps + 1
    local lastTap = self.numTaps == self.maxNumGenes
    self:updateBasedOnEgg(self.EggLeft, self.numTaps % 2 == 1 or lastTap)
    self:updateBasedOnEgg(self.EggRight, self.numTaps % 2 == 0 or lastTap)
    if lastTap then
      self.bg.Touch:V("enabled"):SetInt(0)
      self.Description.FadeTransition:Hide()
      self.SkipButton:setInvisible()
      self.doingOutro = true
      lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_reveal_seq_end.ogg")
    else
      lua_sys.playSoundFx("audio/sfx/" .. revealSounds[self.numTaps] .. ".ogg")
    end
  end
end
function DishHarmonzierResults:updateBasedOnEgg(egg, doPlaySound)
  local gene = egg:revealNextGene()
  if gene == nil then
    return
  end
  local dishHarmonizer = game.SelectedObject()
  local eggMonster = egg:V("MonsterId"):GetInt()
  local monsterResultId = egg:V("MonsterResultId"):GetInt()
  local monsterData = game.getMonsterData(eggMonster)
  self:updateCounter(gene, monsterResultId)
  if egg:isRevealComplete() then
    if monsterData:isPrimordial() then
      self:updatePrimordialCounters(monsterResultId)
      egg:populateGenes(false, false)
      local component = egg.Sprite
      game.playEffect("particles/Structures/DishHarmonizer/FX_PrimordialReveal.efkefc", component:absX(), component:absY(), component("layer"):GetString(), 0.001, 8 * game.hudScale())
    end
    if monsterData:isRareMonster() then
      local component = egg.Sprite
      game.playEffect("particles/Structures/DishHarmonizer/FX_RareReveal.efkefc", component:absX(), component:absY(), component("layer"):GetString(), 0.001, 8 * game.hudScale())
    end
    local target = dishHarmonizer:getMonsterTarget(egg.numGenes)
    if target == eggMonster then
      local meter = self.TargetMeters:E("meter_" .. egg.numGenes)
      if meter then
        meter:fillTo(0, 0, 0.5)
      end
    end
  elseif monsterData:isPrimordial() and monsterSoundData[egg:V("GeneMonsterId"):GetInt()] then
    monsterSound = monsterSoundData[egg:V("GeneMonsterId"):GetInt()].sfx
  end
  if doPlaySound and monsterSoundData[eggMonster] then
    lua_sys.playSoundFx("audio/sfx/" .. monsterSoundData[eggMonster].sfx .. ".ogg")
  end
end
function DishHarmonzierResults:updatePrimordialCounters(monsterResultId)
  local dishHarmonizer = game.SelectedObject()
  local genes = dishHarmonizer:getBaseGenes() .. dishHarmonizer:getMissingGene()
  for i = 1, #genes do
    local gene = genes:sub(i, i)
    local entry = self.GeneCounters:E("counter_" .. gene)
    entry:fadeInOutColor(1, 0, 0, 0, 0.33, 0.33, 0.33)
    local amount = dishHarmonizer:getMonsterResultCost(monsterResultId, gene)
    if gene ~= dishHarmonizer:getMissingGene() then
      amount = amount - 1
    end
    local newCount = entry:V("Count"):GetInt() - amount
    entry:setCounter(newCount)
  end
end
function DishHarmonzierResults:updateCounter(imageName, monsterResultId)
  local dishHarmonizer = game.SelectedObject()
  local monsterData = game.getMonsterData(dishHarmonizer:getMonsterResultType(monsterResultId))
  for i = 1, #self.genes do
    local gene = self.genes:sub(i, i)
    local amount = dishHarmonizer:getMonsterResultCost(monsterResultId, gene)
    if monsterData:isPrimordial() then
      amount = 1
    end
    if amount ~= 0 and game.SelectedObject():getPrimaryGene() ~= gene and imageName == game.geneFilename(gene) then
      local entry = self.GeneCounters:E("counter_" .. gene)
      entry:fadeInOutColor(1, 0, 0, 0, 0.33, 0.33, 0.33)
      local newCount = entry:V("Count"):GetInt() - amount
      entry:setCounter(newCount)
    end
  end
end
function DishHarmonzierResults.bg.Touch:onTouchUp(element, component)
  element:parent():tap()
end
function DishHarmonzierResults:populateGeneCounters()
  local root = self.GeneCounters
  local entries = {}
  local dishHarmonizer = game.SelectedObject()
  for i = 1, #self.genes do
    local gene = self.genes:sub(i, i)
    local vars = {
      spriteName = game.critterSprite(gene),
      layer = "FrontPopUps"
    }
    local entry = menu:addTemplateElementEx("template_dish_harmonizer_gene_counter", "counter_" .. gene, root, vars)
    table.insert(entries, entry)
    entry:relativeTo(root)
    entry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
    entry:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.LEFT, lua_sys.TOP))
    entry:init()
    local numMonsterGenes = self:numGeneUsedToMakeMonster(gene)
    entry:setPositionBroadcast(true)
    entry:postInit()
    local geneResult = dishHarmonizer:getGeneResult(gene)
    if gene == dishHarmonizer:getPrimaryGene() then
      entry:setInfinite()
    else
      entry:setCounter(dishHarmonizer:getNumGenes(gene) + numMonsterGenes - geneResult)
    end
  end
  MenuHelpers.CenterVertically(entries)
end
function DishHarmonzierResults:populateTargetMeters()
  local root = self.TargetMeters
  local offsetY = 0 * game.hudScale()
  local entries = {}
  local dishHarmonizer = game.SelectedObject()
  for i = 1, #self.geneNumbers do
    local numGenes = self.geneNumbers[i]
    local showMeter = false
    local monsterResults = dishHarmonizer:monsterResults()
    for j = 0, monsterResults:size() - 1 do
      local monsterData = game.getMonsterData(monsterResults[j].monsterId)
      if string.len(monsterData:unsortedGenes()) == numGenes or string.len(monsterData:unsortedGenes()) == 0 and numGenes == 4 then
        showMeter = dishHarmonizer:getMonsterTarget(numGenes) ~= 0 and dishHarmonizer:getMonsterTargetResultPercentage(numGenes) ~= 0
        break
      end
    end
    if showMeter then
      if #entries > 0 then
        table.insert(entries, MenuHelpers.CreateSpacer(0, 10 * game.hudScale()))
      end
      local vars = {
        numGenes = numGenes,
        layer = "FrontPopUps",
        scale = 0.7 * game.hudScale()
      }
      local entry = menu:addTemplateElementEx("template_dish_harmonizer_target_meter", "meter_" .. numGenes, root, vars)
      table.insert(entries, entry)
      entry:relativeTo(root)
      entry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      entry:setOrientation(lua_sys.MenuOrientation(0, offsetY, -1, lua_sys.LEFT, lua_sys.TOP))
      entry:init()
      local fill = dishHarmonizer:getMonsterTargetPercentage(numGenes) - dishHarmonizer:getMonsterTargetResultPercentage(numGenes)
      entry:setFill(fill)
      entry:setPositionBroadcast(true)
    end
  end
  MenuHelpers.CenterVertically(entries)
end
function DishHarmonzierResults:skip()
  self:root():popPopUp()
  game.deselectSelectedObject()
  manager:setContext(manager:getDefaultContext())
  game.setMidiFade(1, 1)
end
function DishHarmonzierResults.SkipButton.Touch:onTouchUp(element, component)
  element:parent():skip()
end
return DishHarmonzierResults
