local ScheduledEvent = {}
function ScheduledEvent.OnInit(perceptible, options)
  options = options or {}
  local duration = options.duration or 0
  perceptible("scheduledEventRemainingTime"):SetFloat(0)
  perceptible("scheduledEventTotalTime"):SetFloat(duration)
end
function ScheduledEvent.OnTick(perceptible, dt, options)
  local remainingTime = perceptible("scheduledEventRemainingTime"):GetFloat()
  if remainingTime > 0 then
    remainingTime = math.max(0, remainingTime - dt)
    perceptible("scheduledEventRemainingTime"):SetFloat(remainingTime)
    if remainingTime <= 0 then
      if options.onComplete then
        options.onComplete(perceptible)
      end
    elseif options.onUpdate then
      options.onUpdate(perceptible, dt)
    end
  end
end
function ScheduledEvent.Start(perceptible)
  perceptible("scheduledEventRemainingTime"):SetFloat(perceptible("scheduledEventTotalTime"):GetFloat())
end
function ScheduledEvent.Cancel(perceptible)
  perceptible("scheduledEventRemainingTime"):SetFloat(0)
end
return ScheduledEvent
