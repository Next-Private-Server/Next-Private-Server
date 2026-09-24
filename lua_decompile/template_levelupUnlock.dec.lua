local DeviceCaps = include("DeviceCaps")
local template_levelupUnlock = {}
function template_levelupUnlock:onPostInit()
  self:setInvisible()
end
function template_levelupUnlock:setVisible()
  self.Anim.Sprite("visible"):SetInt(1)
  self.BattleQuestIcon.Sprite("visible"):SetInt(self.CostumeId == 0 and 0 or 1)
  self.NameFrame.Text("visible"):SetInt(1)
  if DeviceCaps.supportEffek() then
    self.Anim.Effect:start()
  end
  lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
end
function template_levelupUnlock:setInvisible()
  self.Anim.Sprite("visible"):SetInt(0)
  self.BattleQuestIcon.Sprite("visible"):SetInt(0)
  self.NameFrame.Text("visible"):SetInt(0)
  self.Touch("enabled"):SetInt(0)
end
function template_levelupUnlock:reenableTouch()
  self.Touch("enabled"):SetInt(1)
end
return template_levelupUnlock
