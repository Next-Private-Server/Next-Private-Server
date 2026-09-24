local MinigameNewLevelOverlay = {
  TransitionHole = {},
  GoButton = {}
}
function MinigameNewLevelOverlay:onPostInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::minigame::MsgMinigameNextLevelResult", "gotMsgMinigameNextLevelResult")
  self.TransitionHole:Setup({
    transitionDuration = 1,
    holeEndSize = 0.001,
    gradientImage = "gfx/menu/gradient_bg_minigame",
    patternImage = "gfx/menu/bg_symbols_minigame",
    layer = "Loading",
    onComplete = function(state)
      if state == 1 then
        game.minigameContext():loadNextLevel()
      elseif state == 2 then
        self:root():removePopUp(self:name())
      end
    end
  })
end
function MinigameNewLevelOverlay:gotMsgMinigameNextLevelResult(msg)
  self.TransitionHole:Hide(true)
  lua_sys.playSoundFx("audio/sfx/minigame01-leveltransition_out.ogg")
end
function MinigameNewLevelOverlay:onTick(dt)
  self.TransitionHole:Tick(dt)
end
function MinigameNewLevelOverlay:nextLevel()
  self.GoButton:setInvisible()
  self.TransitionHole:Show(true)
  lua_sys.playSoundFx("audio/sfx/minigame01-leveltransition_in.ogg")
end
return MinigameNewLevelOverlay
