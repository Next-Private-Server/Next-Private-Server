local MenuHelpers = include("MenuHelpers")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local Tweener = include("Tweener")
local Nucleus = {}
local showBOM = false
local rarityBOM = game.COMMON
local numGenesBOM = game.NO_MONSTER_FILTER
function Nucleus:onPostInit()
  self:Show()
  if game.maxNucleusMonsterSetRarity() < game.MonsterRarity_Rare then
    self.Rare:setLocked()
  end
  if game.maxNucleusMonsterSetRarity() < game.MonsterRarity_Epic then
    self.Epic:setLocked()
  end
end
function Nucleus:onInit()
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = 6 * game.hudScale(),
    duration = 0.66
  })
end
function Nucleus:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      if self.showBOM then
        game.setBookOfMonstersIslandId(game.currentIsland())
        game.setBookOfMonstersRarityFilter(self.rarityBOM)
        game.setBookOfMonstersFilter(self.numGenesBOM)
        game.pushPopUp("book_o_monsters")
        local top = game.topPopUp()
        top("FromWorld"):SetInt(1)
      end
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
end
function Nucleus:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Nucleus:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Nucleus:queuePop()
  self:Hide()
end
function Nucleus:gotoBOM(rarity, numGenes)
  self.showBOM = true
  self.rarityBOM = rarity
  if rarity == "common" then
    self.rarityBOM = game.COMMON
  elseif rarity == "rare" then
    self.rarityBOM = game.RARE
  elseif rarity == "epic" then
    self.rarityBOM = game.EPIC
  end
  if numGenes == 1 then
    self.numGenesBOM = game.ONE_GENE_FILTER
  elseif numGenes == 2 then
    self.numGenesBOM = game.TWO_GENE_FILTER
  elseif numGenes == 3 then
    self.numGenesBOM = game.THREE_GENE_FILTER
  elseif numGenes == 4 then
    self.numGenesBOM = game.FOUR_GENE_FILTER
  end
  game.popPopUp()
  manager:setContext("BLANK")
  game.deselectSelectedObject()
end
return Nucleus
