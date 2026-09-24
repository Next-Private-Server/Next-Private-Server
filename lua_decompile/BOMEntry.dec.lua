local BOMEntry = {}
BOMEntry.pulsing = nil
BOMEntry.secondsElapsedDuringEase = 0
BOMEntry.highlighted = 0
BOMEntry.MonsterID = 0
BOMEntry.visible = true
BOMEntry.MonsterRarity = nil
BOMEntry.FilteredOut = false
function BOMEntry:onInit()
  self.visible = true
  self.pulsing = 0
  self.secondsElapsedDuringEase = 0
end
function BOMEntry:onPostInit()
  self.pulsing = nil
  self:Refresh()
end
function BOMEntry:Refresh()
  if self.visible == true then
    if game.hasOrHasEverHadMonsterOnBookOfMonstersIsland(self.MonsterID) == true then
      self.highlighted = 1
      self:E("CharacterImage"):C("Sprite"):V("visible"):SetInt(1)
      self:E("Silhouette"):C("Sprite"):V("visible"):SetInt(0)
      self.pulsing = 0
    else
      self.highlighted = 0
      self:E("Silhouette"):C("Sprite"):V("visible"):SetInt(1)
      if not game.monsterIsAvail(self.MonsterID, false) and not game.monsterIsAvail(self.MonsterID, true) then
        self:E("CharacterImage"):C("Sprite"):V("visible"):SetInt(0)
        self.pulsing = 0
      elseif self.FilteredOut then
        self:E("CharacterImage"):C("Sprite"):V("visible"):SetInt(1)
        local shader
        if self.pulsing ~= 0 then
          self.pulsing = 0
          shader = include("ShaderDesaturateAndFade")
          if shader then
            shader:getUniform("blackIntensity"):setFloat(1)
          end
        end
        shader = include("ShaderDesaturateAlpha")
        if shader then
          shader:getUniform("blackIntensity"):setFloat(0.75)
          shader:getUniform("alpha"):setFloat(0.25)
          self:E("CharacterImage"):C("Sprite"):setShader(shader)
        end
      elseif game.playerLevel() >= game.monsterUnlockLevel(self.MonsterID) then
        if game.getBookOfMonstersIslandType() == game.IslandType_GOLD or game.getBookOfMonstersIslandType() == game.IslandType_MAGICAL_NEXUS or not game.monsterLimitedAvailability(self.MonsterID, false) and not game.monsterLimitedAvailability(self.MonsterID, true) and not game.attunerLimitedAvailability(self.MonsterID) then
          self:E("CharacterImage"):C("Sprite"):V("visible"):SetInt(1)
          if self.pulsing ~= 0 then
            self.pulsing = 0
          end
          local shader = include("ShaderDesaturate")
          if shader then
            shader:getUniform("blackIntensity"):setFloat(0.5)
            self:E("CharacterImage"):C("Sprite"):setShader(shader)
          end
        else
          local shader = include("ShaderDesaturateAndFade")
          if self.pulsing ~= 1 then
            self.pulsing = 1
            if shader then
              shader:getUniform("blackIntensity"):setFloat(0.5)
              self:E("CharacterImage"):C("Sprite"):setShader(shader)
            end
          end
          self:E("CharacterImage"):C("Sprite"):V("visible"):SetInt(1)
        end
      else
        self:E("CharacterImage"):C("Sprite"):V("visible"):SetInt(0)
      end
      if game.isSeasonal(self.MonsterID) then
        self:E("Silhouette"):C("Sprite"):setColor(0.859, 0.529, 0.49)
      elseif game.isEpic(self.MonsterID) then
        self:E("Silhouette"):C("Sprite"):setColor(0.984, 0.78, 0.373)
      elseif game.isRare(self.MonsterID) then
        self:E("Silhouette"):C("Sprite"):setColor(0.529, 0.89, 0.757)
      end
    end
  else
    self:E("CharacterImage"):C("Sprite"):V("visible"):SetInt(0)
    self:E("Silhouette"):C("Sprite"):V("visible"):SetInt(0)
  end
end
function BOMEntry:touch()
  lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
  local monsterId = self.MonsterID
  self:parent():parent():E("SelectedMonsterView"):V("selectedMonst"):SetInt(monsterId)
  self:parent():parent():E("MonsterList"):C("Camera"):V("enabled"):SetInt(0)
  if game.hasOrHasEverHadMonsterOnBookOfMonstersIslandIgnoreParanomal(monsterId) then
    if game.getPopUp() ~= "monster_book_info_owned" then
      game.playMonsterBookSelectSound(monsterId, 0)
      game.pushPopUp("monster_book_info_owned")
    end
  elseif game.monsterIsAvail(monsterId, false) or game.monsterIsAvail(monsterId, true) then
    if game.getPopUp() ~= "monster_book_info_unowned_avail" then
      game.pushPopUp("monster_book_info_unowned_avail")
    end
  elseif game.getPopUp() ~= "monster_book_info_unowned_unavail" then
    game.pushPopUp("monster_book_info_unowned_unavail")
  end
end
return BOMEntry
