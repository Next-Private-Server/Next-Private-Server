local GetItNowAttune = {}
local GetItNowAttune = {transitionState = 1, transitionTime = 0}
function GetItNowAttune:onInit()
  self("CritterGene"):SetString("")
  self("IslandGene"):SetString("")
  lua_sys.playSoundFx("audio/sfx/structure_attunement_activate.wav")
end
function GetItNowAttune:onTick(dt)
  if self.transitionState ~= 0 then
    self:TickTransition()
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    if 1 < self.transitionTime then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
    elseif 0 > self.transitionTime then
      self:root():popPopUp()
    end
  end
end
function GetItNowAttune:update()
  local critterGene = self("CritterGene"):GetString()
  self.Parent.Critter.Sprite("spriteName"):SetString(game.critterSprite(critterGene))
  local islandGene = self("IslandGene"):GetString()
  local island = game.attunerGeneData(islandGene).islandId
  self.Parent.Island.Sprite("sheet"):SetString(game.islandIconSheetForId(island))
  self.Parent.Island.Sprite("spriteName"):SetString(game.islandIconSpriteForId(island))
  self.Parent.Island.Gene("spriteName"):SetString(game.geneFilename(islandGene))
  self.Time("update"):SetInt(1)
end
function GetItNowAttune:TickTransition()
  local frame = self:GetElement("bg")
  frame("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.FadedBG.Sprite("alpha"):SetFloat(self.transitionTime * 0.5)
  game.setClipping("Clipping", (frame:absX() + 10) * lua_sys.deviceScaleX(), (frame:absY() + 50 * game.hudScale()) * lua_sys.deviceScaleY(), (frame:absW() - 20) * lua_sys.deviceScaleX(), (frame:absH() - 50 * game.hudScale() - 10) * lua_sys.deviceScaleY())
end
function GetItNowAttune:queuePop()
  self.transitionState = 2
end
return GetItNowAttune
