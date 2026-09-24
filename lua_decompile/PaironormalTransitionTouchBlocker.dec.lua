local PaironormalTransitionTouchBlocker = {
  TouchBlocker = {
    Touch = {}
  }
}
function PaironormalTransitionTouchBlocker:onPostInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgIslandModeChangeComplete", "gotMsgIslandModeChangeComplete")
end
function PaironormalTransitionTouchBlocker:gotMsgIslandModeChangeComplete(msg)
  self:root():popPopUp()
end
return PaironormalTransitionTouchBlocker
