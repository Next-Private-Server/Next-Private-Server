local Coroutines = {}
function Coroutines.WaitForSeconds(seconds)
  if not coroutine.running() then
    print("WaitForSeconds not called in a coroutine!")
    return
  end
  seconds = seconds or 1
  local elapsed = 0
  while seconds > elapsed do
    coroutine.yield({
      game.engineReceiver(),
      game.M_MsgUpdate_GetMsgTypeId(),
      function(m)
        local t = math.min(m.time, 0.033)
        elapsed = elapsed + t
        return true
      end
    })
  end
end
function Coroutines.WaitForAnimation(receiver)
  if not coroutine.running() then
    print("WaitForAnimation not called in a coroutine!")
    return
  end
  coroutine.yield({
    receiver,
    game.M_MsgAnimationFinished_GetMsgTypeId(),
    function(m)
      print("Got MsgAnimationFinished!")
      return true
    end
  })
end
function Coroutines.RunTransition(transition)
  if not coroutine.running() then
    print("RunTransition not called in a coroutine!")
    return
  end
  local deltaTime = 0
  while 0 < transition:GetTransitionTime() do
    transition:Tick(deltaTime)
    coroutine.yield({
      game.engineReceiver(),
      game.M_MsgUpdate_GetMsgTypeId(),
      function(m)
        deltaTime = m.time
        return true
      end
    })
  end
end
function Coroutines.RunTweener(tweener)
  if not coroutine.running() then
    print("RunTweener not called in a coroutine!")
    return
  end
  local deltaTime = 0
  while tweener:isActive() do
    tweener:Tick(deltaTime)
    coroutine.yield({
      game.engineReceiver(),
      game.M_MsgUpdate_GetMsgTypeId(),
      function(m)
        deltaTime = m.time
        return true
      end
    })
  end
end
return Coroutines
