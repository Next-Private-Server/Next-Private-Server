local MenuHelpers = include("MenuHelpers")
local OffsetTransition = include("MenuElementPositionOffsetTransition")
local RetrySynthesis = {
  SynthesizeButton = {
    Label = {}
  },
  Cost = {
    BackingSprite = {},
    CurrencySprite = {},
    Text = {}
  },
  Attune = {
    Text = {},
    Overlay = {}
  }
}
function RetrySynthesis:onInit()
  self.lastSynthesisMonster = game.getLastSynthesisMonster()
  self.lastSynthesisGenes = game.getLastSynthesisGenes()
  self.monsterType = game.monsterTypeId(self.lastSynthesisMonster)
  self.monsterGenes = game.monsterTypeGenes(self.monsterType)
  self.numGenes = #self.monsterGenes + #self.lastSynthesisGenes
  self.isMonsterCombo = self.numGenes > 3
  OffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = 6 * game.hudScale(),
    duration = 0.66
  })
end
function RetrySynthesis:onPostInit()
  if game.hasRequiredCrittersForSynthesis(self.lastSynthesisGenes, self.lastSynthesisMonster) then
    local cost = game.synthersizerCost(self.numGenes)
    self:E("Cost"):C("Text"):V("text"):SetString(cost)
    self.Attune:Hide()
  else
    self:E("MonsterText"):C("Text"):V("text"):SetString("RETRY_SYNTHESIS_NOT_ENOUGH_CRITTERS")
    self:E("NoMonsterText"):C("Text"):V("text"):SetString("RETRY_SYNTHESIS_NOT_ENOUGH_CRITTERS")
    self.SynthesizeButton:Hide()
    self.Cost:Hide()
    self.Attune:Show()
  end
  self:Populate()
  self:Show()
end
function RetrySynthesis.SynthesizeButton:Hide()
  self:setInvisible()
  self.Label:V("visible"):SetInt(0)
end
function RetrySynthesis.Cost:Hide()
  self.BackingSprite:V("visible"):SetInt(0)
  self.CurrencySprite:V("visible"):SetInt(0)
  self.Text:V("visible"):SetInt(0)
end
function RetrySynthesis.Attune:Hide()
  self:setInvisible()
  self.Text:V("visible"):SetInt(0)
  self.Overlay:V("visible"):SetInt(0)
end
function RetrySynthesis.Attune:Show()
  self:setVisible()
  self.Text:V("visible"):SetInt(1)
  self.Overlay:V("visible"):SetInt(1)
end
function RetrySynthesis:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      manager:setContext("SYNTHESIZING_MENU")
    end
  }
  OffsetTransition.OnTick(self:E("bg"), dt, options)
end
function RetrySynthesis:Show()
  OffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function RetrySynthesis:Hide()
  OffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function RetrySynthesis:queuePop()
  self:Hide()
end
function RetrySynthesis:StartSynthesizing()
  local cost = game.synthersizerCost(self.numGenes)
  if game.clearPurchase(game.CurrencyType_Shards, cost, game.PurchaseType_START_SYNTHESIS, self.numGenes) then
    game.startSynthesizing(self.lastSynthesisGenes, self.lastSynthesisMonster)
    self:root():popPopUp()
  end
end
function RetrySynthesis:Populate()
  if self.isMonsterCombo then
    self:E("MonsterText"):C("Text"):V("visible"):SetInt(1)
    self:E("NoMonsterText"):C("Text"):V("visible"):SetInt(0)
    local monsterEntry = menu:addTemplateElement("template_monster_synthesizing_entry", "monsterEntry", self.Monster)
    monsterEntry:V("MonsterID"):SetInt(self.lastSynthesisMonster)
    monsterEntry:V("List"):SetString("SMP_LIST")
    monsterEntry:V("Layer"):SetString("MidPopUps")
    monsterEntry:V("selected"):SetInt(0)
    monsterEntry:setOrientation(lua_sys.MenuOrientation(5 * game.menuScaleX(), 0, -1, lua_sys.HCENTER, lua_sys.VCENTER))
    monsterEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    monsterEntry:init()
    monsterEntry:setPositionBroadcast(true)
    monsterEntry("touchDisabled"):SetInt(1)
  end
  self:ShowCritters()
end
function RetrySynthesis:ShowCritters()
  local offsetY = 0 * game.menuScaleY()
  local entries = {}
  local index = 0
  local genes = self.lastSynthesisGenes
  local element = self:E("NoMonsterGeneHolder")
  if self.isMonsterCombo then
    element = self:E("MonsterGeneHolder")
    genes = self.monsterGenes .. self.lastSynthesisGenes
  end
  for i = 1, #genes do
    if self.isMonsterCombo and i == #genes or self.isMonsterCombo == false and i > 1 then
      local plus = menu:addTemplateElement("template_plus", "plus" .. index, element)
      plus:relativeTo(element)
      plus:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      plus:setOrientation(lua_sys.MenuOrientation(0, offsetY, -1, lua_sys.LEFT, lua_sys.VCENTER))
      plus:V("Layer"):SetString("MidPopUps")
      plus:init()
      plus:setPositionBroadcast(true)
      table.insert(entries, plus)
    end
    local entry = menu:addTemplateElement("template_critter_slot_entry", "critter" .. index, element)
    table.insert(entries, entry)
    local gene = genes:sub(i, i)
    entry.gene = gene
    entry.num = game.numCrittersWithGene(gene)
    local required = game.synthesizerGenesRequired(#genes)
    if string.find(self.monsterGenes, gene) then
      required = required - 1
    end
    entry.required = required
    entry:relativeTo(element)
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    entry:setOrientation(lua_sys.MenuOrientation(0, offsetY, -1, lua_sys.LEFT, lua_sys.VCENTER))
    entry("Layer"):SetString("MidPopUps")
    entry:init()
    entry:setPositionBroadcast(true)
    entry:disableTouch()
    entry:update()
    index = index + 1
  end
  MenuHelpers.CenterHorizontally(entries)
end
return RetrySynthesis
