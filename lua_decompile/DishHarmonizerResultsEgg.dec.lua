local MenuHelpers = require("MenuHelpers")
local Genes = include("Genes")
local DishHarmonizerResultsEgg = {
  Sprite = {},
  MysteryEgg = {},
  TapParticles = {},
  Touch = {},
  Genes = {}
}
function DishHarmonizerResultsEgg:onInit()
  self.numRevealedGenes = 0
  self.meebAnimationTimer = 0
  self.numGenes = 0
end
function DishHarmonizerResultsEgg:onPostInit()
  local monsterData = game.getMonsterData(self("MonsterId"):GetInt())
  self.MysteryEgg:V("spriteName"):SetString("gfx/" .. monsterData:spore())
  self.MysteryEgg:V("visible"):SetInt(0)
  self:populateGenes(true, true)
  local targetSheet = "meeb_cluster_" .. game.GetIsletPrimaryGeneName(game.currentIsland()) .. "_sheet.xml"
  game.remapMenuAnim(self.Sprite, "meeb_cluster_plasma_sheet.xml", targetSheet)
  game.remapMenuAnim(self.TapParticles, "meeb_cluster_plasma_sheet.xml", targetSheet)
  local tapParticles = self:GetComponent("TapParticles")
  tapParticles:addLuaFunction("play", function(component)
    component("visible"):SetInt(1)
    component("animation"):SetString("tap effcts 0" .. math.random(4))
    component:Play()
  end)
  local sprite = self:GetComponent("Sprite")
  sprite:addLuaFunction("final", function(component)
    component("animation"):SetString("final")
    component:Play()
  end)
end
function DishHarmonizerResultsEgg:populateGenes(showOverride, areHidden)
  local infos = {}
  if showOverride and self:V("GeneMonsterId"):GetInt() ~= 0 then
    infos = Genes.GetGeneInfosForMonsterId(self:V("GeneMonsterId"):GetInt())
  else
    infos = Genes.GetGeneInfosForMonsterId(self("MonsterId"):GetInt())
  end
  for i = 1, self.numGenes do
    local entry = self:E("entry" .. i)
    self:RemoveElement(entry)
  end
  if infos then
    local items = {}
    for i = 1, #infos do
      local entry = menu:addTemplateElement("template_mystery_gene", "entry" .. i, self)
      entry:V("SpriteName"):SetString(infos[i].sprite)
      entry:V("SheetName"):SetString(infos[i].sheet)
      entry:V("Size"):SetFloat(0.35 * game.hudScale())
      entry:V("Layer"):SetString("FrontPopUps")
      entry:relativeTo(self)
      entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      entry:setOrientation(lua_sys.MenuOrientation(0, -20 * game.hudScale(), -5, lua_sys.LEFT, lua_sys.TOP))
      entry:init()
      if areHidden == false then
        entry:DoStoredScript("Reveal")
      end
      entry:setPositionBroadcast(true)
      table.insert(items, entry)
    end
    MenuHelpers.CenterHorizontally(items)
  end
  self.numGenes = #infos
  if areHidden == false then
    self.numRevealedGenes = self.numGenes
  end
end
function DishHarmonizerResultsEgg:revealNextGene()
  if self.numRevealedGenes < self.numGenes then
    self.numRevealedGenes = self.numRevealedGenes + 1
    local nextGene = "entry" .. self.numRevealedGenes
    self:E(nextGene):DoStoredScript("Reveal")
    if self.numRevealedGenes == self.numGenes then
      self.TapParticles:DoStoredScript("play")
      self.Sprite:DoStoredScript("final")
      self.MysteryEgg:V("visible"):SetInt(1)
    else
      self.Sprite("animation"):SetString("tap")
      self.meebAnimationTimer = 0.35
      self.TapParticles:DoStoredScript("play")
    end
    return self:E(nextGene):V("SpriteName"):GetString()
  end
  return nil
end
function DishHarmonizerResultsEgg:isRevealComplete()
  if self.numRevealedGenes == self.numGenes then
    return true
  end
  return false
end
function DishHarmonizerResultsEgg.Touch:onTouchUp(element, component)
  element:parent():TouchedEgg(element)
end
function DishHarmonizerResultsEgg:onTick(dt)
  if self.meebAnimationTimer > 0 and self:isRevealComplete() == false then
    self.meebAnimationTimer = self.meebAnimationTimer - dt
    if self.meebAnimationTimer <= 0 then
      self.Sprite("animation"):SetString("idle")
    end
  end
end
return DishHarmonizerResultsEgg
