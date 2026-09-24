local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local SoulLink = {}
local raritySets = {
  "Common",
  "Rare",
  "Epic"
}
local raritySetsAnim = {
  "CommonAnim",
  "RareAnim",
  "EpicAnim"
}
function SoulLink:onInit()
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = 6 * game.hudScale(),
    duration = 0.66
  })
end
function SoulLink:onPostInit()
  self:ShowMonsterSelectPopup(0)
  self:refresh()
  self:Show()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgSoulLinkAdded", "gotMsgSoulLinkAdded")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgSoulLinkRemoved", "gotMsgSoulLinkRemoved")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function SoulLink:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
end
function SoulLink:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function SoulLink:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function SoulLink:EnableSlots()
  for i = 1, #raritySets do
    local set = self:E(raritySets[i])
    local titansoul = game.SelectedObject()
    if titansoul:isRarityUnlocked(tonumber(set:templateVars().setRarity)) then
      set:Enable()
    end
  end
end
function SoulLink:DisableSlots()
  for i = 1, #raritySets do
    local set = self:E(raritySets[i])
    set:Disable()
  end
end
function SoulLink:queuePop()
  self:Hide()
end
function SoulLink:refresh()
  for i = 1, #raritySets do
    local set = self:E(raritySets[i])
    set:refresh()
    local raritySetAnim = self:E(raritySetsAnim[i]):C("Sprite")
    local rarityEnum = tonumber(set:templateVars().setRarity)
    local titansoul = game.SelectedObject()
    local soulLinks = titansoul:getSoulLinks(tonumber(rarityEnum))
    local numLinks = soulLinks:size()
    if numLinks == 0 then
      raritySetAnim:V("visible"):SetInt(0)
    else
      raritySetAnim:V("visible"):SetInt(1)
      local rarity = "common"
      if rarityEnum == game.MonsterRarity_Rare then
        rarity = "rare"
      elseif rarityEnum == game.MonsterRarity_Epic then
        rarity = "epic"
      end
      raritySetAnim:V("animation"):SetString("soulink_" .. rarity .. "_0" .. tostring(numLinks))
      raritySetAnim:calculatePosition()
    end
  end
  self:updateMeter()
end
function SoulLink:SoulLinkSlotSelected(slot)
  self.lastSlotSelected = slot
  self.selectedMonsterId = slot.monsterId
  if slot.monsterId == 0 then
    local rarity = tonumber(slot:templateVars().rarity)
    self.MonsterSelectPopup:V("Rarity"):SetInt(rarity)
    self.MonsterSelectPopup.Panel.List:DoStoredScript("populate")
    if self.MonsterSelectPopup:V("numMonsters"):GetInt() == 0 then
      local rarityText = "RARITY_COMMON"
      if rarity == game.MonsterRarity_Rare then
        rarityText = "RARITY_RARE"
      elseif rarity == game.MonsterRarity_Epic then
        rarityText = "RARITY_EPIC"
      end
      local text = LOC("NO_LINKABLE_MONSTERS_AVAILABLE")
      text = text:gsub("%${RARITY}", LOC(rarityText))
      game.displayNotification(text)
    else
      self:ShowMonsterSelectPopup(1)
      lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
      lua_sys.playSoundFx("audio/sfx/menu_titansoul_open.ogg")
    end
  else
    game.pushPopUp("titansoul_link_confirmation")
    local popup = game.topPopUp()
    popup:DoStoredScript("showUnlink")
  end
end
function SoulLink:ShowMonsterSelectPopup(show)
  if show == 1 then
    self.MonsterSelectPopup:DoStoredScript("show")
  else
    self.MonsterSelectPopup:DoStoredScript("hide")
  end
end
function SoulLink:MonsterSelected(monsterId)
  self.selectedMonsterId = monsterId
  game.pushPopUp("titansoul_link_confirmation")
  local popup = game.topPopUp()
  popup:DoStoredScript("showLink")
end
function SoulLink:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "CONFIRM_SOUL_LINK" and msg.choice == true then
    self:DisableSlots()
    game.AddSoulLink(self.selectedMonsterId)
  elseif msg.messageID == "CONFIRM_SOUL_UNLINK" and msg.choice == true then
    self:DisableSlots()
    game.RemoveSoulLink(self.selectedMonsterId)
  else
    self:EnableSlots()
  end
end
function SoulLink:gotMsgSoulLinkAdded(msg)
  self.lastSlotSelected:addMonster(msg.userMonsterId)
  lua_sys.playSoundFx("audio/sfx/menu_titansoul_link.ogg")
  self:EnableSlots()
  self:refresh()
end
function SoulLink:gotMsgSoulLinkRemoved(msg)
  self.lastSlotSelected:removeMonster()
  self:EnableSlots()
  self:refresh()
end
function SoulLink:updateMeter()
  local titansoul = game.SelectedObject()
  if titansoul then
    local unlockLevels = game.Titansoul_getSongUnlockLevels()
    local levelData = titansoul:getLevelData()
    local power = titansoul:power()
    local meterBuffer = 0.1
    for i = 0, unlockLevels:size() - 1 do
      local meter = self:E("Meter" .. i + 1):C("Sprite")
      local completeSprite = self:E("Flame" .. i + 1):C("Sprite")
      local percent = 0
      local prevLevelPowerReq = 0
      local levelPower = power
      local levelPowerReq = unlockLevels[i].power
      if i > 0 then
        prevLevelPowerReq = unlockLevels[i - 1].power
        levelPower = power - prevLevelPowerReq
        levelPowerReq = unlockLevels[i].power - prevLevelPowerReq
      end
      if levelData.level >= unlockLevels[i].level then
        percent = 1
        completeSprite:V("visible"):SetInt(1)
      else
        completeSprite:V("visible"):SetInt(0)
      end
      if levelData.level < unlockLevels[i].level and power > prevLevelPowerReq and levelPower > 0 then
        percent = levelPower / levelPowerReq
        percent = math.min(1, percent)
        percent = meterBuffer + (1 - 2 * meterBuffer) * percent
      end
      local width = meter("FullMaskW"):GetInt()
      meter("maskWidth"):SetFloat(width * percent)
    end
  end
end
return SoulLink
