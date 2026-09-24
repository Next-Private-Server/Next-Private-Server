local MenuHelpers = include("MenuHelpers")
local AttuningComplete = {
  AttunedCritter = {
    Arrow = {},
    Text = {},
    Critter = {},
    CritterBefore = {}
  },
  ReattunedMonster = {
    Arrow = {
      Sprite = {}
    },
    Desc = {
      Text = {}
    },
    MonsterBefore = {},
    MonsterAfter = {}
  }
}
function AttuningComplete:onInit()
  lua_sys.playSoundFx("audio/sfx/structure_attunement_collect.wav")
  self.pauseBeforeShowReattunedGenesTimer = 0.5
  self.doPauseBeforeShowReattunedGenes = false
end
function AttuningComplete:onPostInit()
  self.AttunedCritter.isVisible = true
  self.ReattunedMonster.isVisible = false
  local attuner = game.FindAttuner()
  self.critterGene = attuner:getEndGene()
  self.AttunedCritter.Critter.Sprite("spriteName"):SetString(game.critterSprite(self.critterGene))
  local critterGeneBefore = attuner:getStartGene()
  self.AttunedCritter.CritterBefore.Sprite("spriteName"):SetString(game.critterSprite(critterGeneBefore))
  local partiallyReattuneMonster = 0
  if attuner:hasAttuningReattunedMonster() then
    local reattuningMonster = attuner:reattuningMonster()
    local monster = game.GetMonster(reattuningMonster)
    if #monster:reattunedGenes() < #monster:data():unsortedGenes() then
      partiallyReattuneMonster = reattuningMonster
    end
  end
  if partiallyReattuneMonster ~= 0 then
    self.ReattunedMonster.isVisible = true
    local monster = game.GetMonster(partiallyReattuneMonster)
    local genes = monster:reattunedGenes()
    genes = genes:gsub(self.critterGene, "")
    self.ReattunedMonster.Arrow.Sprite("visible"):SetInt(1)
    self.ReattunedMonster.Desc.Text("visible"):SetInt(1)
    self.ReattunedMonster.MonsterBefore("visible"):SetInt(1)
    self.ReattunedMonster.MonsterBefore("spriteName"):SetString("gfx/breeding/" .. game.getPortraitName(partiallyReattuneMonster))
    self.ReattunedMonster.GenesBefore("UserMonsterId"):SetInt(partiallyReattuneMonster)
    self.ReattunedMonster.GenesBefore("OverrideReattunedGenes"):SetString(genes)
    self.ReattunedMonster.GenesBefore:DoStoredScript("populate")
    self.ReattunedMonster.MonsterAfter("visible"):SetInt(1)
    self.ReattunedMonster.MonsterAfter("spriteName"):SetString("gfx/breeding/" .. game.getPortraitName(partiallyReattuneMonster))
    self.ReattunedMonster.GenesAfter("UserMonsterId"):SetInt(partiallyReattuneMonster)
    self.ReattunedMonster.GenesAfter:DoStoredScript("populate")
    local monsterData = game.getMonsterData(monster:monsterTypeId())
    self.numMonsterGenes = #monsterData:unsortedGenes()
    for i = 0, self.numMonsterGenes - 1 do
      local entry = self.ReattunedMonster.GenesAfter:E("entry" .. i)
      if entry:V("Reattuned"):GetInt() == 1 and string.find(self.critterGene, entry:V("Gene"):GetString()) then
        entry:HideRarity()
      end
    end
    self.doPauseBeforeShowReattunedGenes = true
  end
  self:updateLayout()
end
function AttuningComplete:onTick(dt)
  if self.doPauseBeforeShowReattunedGenes then
    self.pauseBeforeShowReattunedGenesTimer = self.pauseBeforeShowReattunedGenesTimer - dt
    if self.pauseBeforeShowReattunedGenesTimer <= 0 then
      self:showReattunedGenes()
      self.doPauseBeforeShowReattunedGenes = false
    end
  end
end
function AttuningComplete:updateLayout()
  local spacer = MenuHelpers.CreateSpacer(0, 4 * game.hudScale())
  local numItems = 0
  local items = {}
  local function addIfVisible(item)
    if item.isVisible then
      if numItems > 0 then
        table.insert(items, spacer)
      end
      table.insert(items, item)
      numItems = numItems + 1
    end
  end
  addIfVisible(self.AttunedCritter)
  addIfVisible(self.ReattunedMonster)
  MenuHelpers.CenterVertically(items)
end
function AttuningComplete:showReattunedGenes()
  for i = 0, self.numMonsterGenes - 1 do
    local entry = self.ReattunedMonster.GenesAfter:E("entry" .. i)
    if entry:V("Reattuned"):GetInt() == 1 and string.find(self.critterGene, entry:V("Gene"):GetString()) then
      entry:ShowRarityReveal()
    end
  end
end
function AttuningComplete:queuePop()
  self:root():popPopUp()
end
return AttuningComplete
