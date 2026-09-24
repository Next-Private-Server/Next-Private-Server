local template_underlingEntry = {}
function template_underlingEntry:onInit()
  self("expired"):SetInt(0)
  self("locked"):SetInt(0)
  self("infTime"):SetInt(0)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function template_underlingEntry:onPostInit()
  if game.isUnderlingExpired(self("ID"):GetInt()) then
    self("expired"):SetInt(1)
    self:DoStoredScript("disable")
    self.TimeRemainingFrame.Text("text"):SetString("ZAP_MONSTER_EXPIRED")
  elseif game.isUnderlingLocked(self("ID"):GetInt()) then
    self("locked"):SetInt(1)
    self.Lock.Sprite("visible"):SetInt(1)
    self:DoStoredScript("disable")
    self.ZapItButton:disable()
  else
    local timeLeft = game.underlingTime(self("ID"):GetInt())
    if timeLeft <= 0 and self("expired"):GetInt() == 0 then
      self("infTime"):SetInt(1)
      self.TimeRemainingFrame.Text("visible"):SetInt(0)
    elseif timeLeft > 0 then
      self.TimeRemainingFrame.Text("visible"):SetInt(1)
      self.TimeRemainingFrame.Text("text"):SetString(game.timeToString(timeLeft))
    end
  end
end
function template_underlingEntry:highlight()
  self.Anim.Sprite:setColor(1, 1, 1)
  self.NameFrame.Text:setColor(1, 1, 1)
  self.TimeRemainingFrame.Text:setColor(1, 1, 1)
  self.InventoryButton:DoStoredScript("enable")
end
function template_underlingEntry:disable()
  self.Anim.Sprite:setColor(0.33, 0.33, 0.33)
  self.NameFrame.Text:setColor(0.33, 0.33, 0.33)
  self.TimeRemainingFrame.Text:setColor(1, 0.33, 0.33)
  self.InventoryButton:DoStoredScript("disable")
  self.Touch("enabled"):SetInt(1)
end
function template_underlingEntry:unlock()
  self("locked"):SetInt(0)
  self.Anim.Sprite:setColor(1, 1, 1)
  self.NameFrame.Text:setColor(1, 1, 1)
  self.Lock.Sprite("visible"):SetInt(0)
  self.InventoryButton:enable()
  self.ZapItButton:enable()
  self.Touch("enabled"):SetInt(1)
end
function template_underlingEntry:onTick(dt)
  if self("infTime"):GetInt() == 0 then
    local timeLeft = game.underlingTime(self("ID"):GetInt())
    if timeLeft < 0 then
      timeLeft = 0
    end
    if timeLeft == 0 and self("expired"):GetInt() == 0 then
      self.TimeRemainingFrame.Text("visible"):SetInt(0)
    else
      local timeString = game.timeToString(timeLeft)
      if timeString ~= self.TimeRemainingFrame.Text("text"):GetString() then
        self.TimeRemainingFrame.Text("visible"):SetInt(1)
        if timeLeft <= 0 then
          if self("expired"):GetInt() == 0 then
            self("expired"):SetInt(1)
            self:DoStoredScript("disable")
            self.TimeRemainingFrame.Text("text"):SetString("ZAP_MONSTER_EXPIRED")
          end
        else
          self.TimeRemainingFrame.Text("text"):SetString(timeString)
        end
      end
    end
  end
end
function template_underlingEntry:selectEntry()
  if self("expired"):GetInt() == 1 then
    game.displayNotification(game.zapExpiredStr(self("Island"):GetInt(), self("ID"):GetInt()))
  elseif self("locked"):GetInt() == 1 then
    game.confEvolveUnlockWublin(self("ID"):GetInt())
  else
    local numCostumes = 0
    local eggList = game.getEggsInInactiveUnderlingMonster(self("ID"):GetInt())
    local hasEgg = false
    for eggInd = 0, eggList:size() - 1 do
      if eggList[eggInd] == 1 then
        hasEgg = true
        break
      end
    end
    if not hasEgg then
      numCostumes = game.numPurchasedCostumes(self("ID"):GetInt(), self("Island"):GetInt())
    end
    if numCostumes > 0 then
      local txt = game.getLocalizedText("ZAP_TO_MONSTER_WITH_COSTUMES")
      txt = txt:gsub("%${NUM_COSTUMES}", numCostumes)
      game.displayConfirmation("ZAP_TO_MONSTER" .. self("ID"):GetInt(), txt)
    else
      self:confirmZap()
    end
  end
end
function template_underlingEntry:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "ZAP_TO_MONSTER" .. self("ID"):GetInt() and msg.choice == true then
    self:confirmZap()
  end
end
function template_underlingEntry:confirmZap()
  game.boxEggToUnderlingIsland(self("ID"):GetString())
end
return template_underlingEntry
