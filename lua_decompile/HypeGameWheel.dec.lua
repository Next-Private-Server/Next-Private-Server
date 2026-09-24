local HypeGameWheel = {
  Wheel = {
    Base = {},
    Label = {},
    Numbers = {}
  }
}
local IDLE_VELOCITY = 25
local VELOCITY = 1200
local VELOCITY_WIGGLE_ROOM = 0.2
local ACCELERATION = 400
local MAX_TIME_DELTA = 0.25
local RESULT_WIGGLE_ROOM = 15
local POINTER_OFFSET = -5
local NUMBERS_ANGLE_OFFSET = 22.5
function debugPrint(text)
end
function HypeGameWheel:onInit()
  self.Wheel:calculatePosition()
  self.Wheel:setPositionBroadcast(true)
  for i = 1, 8 do
    local number = menu:addTemplateElement("template_hype_game_wheel_number", "Number" .. i, self.Wheel)
    number:relativeTo(self.Wheel)
    number:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    number:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.VCENTER))
    number:init()
    table.insert(self.Wheel.Numbers, number)
  end
  self.currentRotationDeg = 0
  self.currentVelocity = IDLE_VELOCITY
  self.targetVelocity = IDLE_VELOCITY
  self.endAngle = 0
end
function HypeGameWheel:onTick(dt)
  if self.currentVelocity ~= self.targetVelocity then
    local accelerating = self.currentVelocity < self.targetVelocity
    local delta = ACCELERATION * dt
    if accelerating then
      self.currentVelocity = self.currentVelocity + delta
      if self.currentVelocity > self.targetVelocity then
        self.currentVelocity = self.targetVelocity
      end
    else
      self.currentVelocity = self.currentVelocity - delta
      if self.currentVelocity < self.targetVelocity then
        self.currentVelocity = self.targetVelocity
      end
    end
  end
  if self.currentVelocity ~= 0 then
    self.currentRotationDeg = self.currentRotationDeg + dt * self.currentVelocity
    if self.currentRotationDeg >= 360 then
      self.currentRotationDeg = self.currentRotationDeg - 360
    end
    self:setRotation(self.currentRotationDeg)
  end
end
function HypeGameWheel:resetIdleDiscSpeed()
  self.targetVelocity = IDLE_VELOCITY
  debugPrint("Velocity: " .. self.targetVelocity)
end
function HypeGameWheel:resetDiscSpeed()
  self.targetVelocity = VELOCITY
  debugPrint("Velocity: " .. self.targetVelocity)
end
function HypeGameWheel:stopDiscs()
  if self.currentVelocity ~= 0 or self.targetVelocity ~= 0 then
    self.targetVelocity = 0
    self.currentVelocity = 0
    debugPrint("Velocity: " .. self.targetVelocity)
    local diff = self.currentRotationDeg - self.endAngle
    debugPrint("currentRotationDeg: " .. self.currentRotationDeg)
    debugPrint("endAngle: " .. self.endAngle)
    debugPrint("--------------------------------------------------------------- diff: " .. diff)
    if math.abs(diff) > RESULT_WIGGLE_ROOM * 0.5 then
      debugPrint("--------------------------------------------------------------- FIXING DISC")
      HypeGameWheel.setRotation(self, self.endAngle)
    end
  end
end
function HypeGameWheel:isStopped()
  return self.currentVelocity == 0 and self.targetVelocity == 0
end
function HypeGameWheel:speedToIdleRatio()
  return self.currentVelocity / IDLE_VELOCITY
end
function HypeGameWheel:findBestIndex(indexes, targetTime)
  debugPrint("-----------------------------------")
  debugPrint("setTargetValue")
  local targetPosition = (targetTime * VELOCITY + self.currentRotationDeg) % 360
  debugPrint("targetPosition: " .. targetPosition)
  local bestIndex = 0
  local bestIndexDistance = 999999999
  for _, index in ipairs(indexes) do
    debugPrint("----")
    debugPrint("Checking " .. index)
    local endPos = 360 - (index - 1) * 45 - NUMBERS_ANGLE_OFFSET + POINTER_OFFSET
    debugPrint("endPos " .. endPos)
    local distance = math.abs(endPos - targetPosition)
    if distance > 180 then
      distance = math.abs(distance - 360)
    end
    debugPrint("distance " .. distance)
    if bestIndexDistance > distance then
      debugPrint("New better index")
      bestIndex = index
      bestIndexDistance = distance
    end
  end
  debugPrint("Best Index Found: " .. bestIndex)
  return bestIndex
end
function HypeGameWheel:setTargetIndex(index, time)
  debugPrint("time: " .. time)
  self.endAngle = 360 - (index - 1) * 45 - NUMBERS_ANGLE_OFFSET + POINTER_OFFSET
  local targetDistance = self.endAngle - self.currentRotationDeg
  local worstCaseMaxVelocityTime = time - VELOCITY / ACCELERATION
  local worstCaseDistanceTraveled = worstCaseMaxVelocityTime * VELOCITY
  local worstCaseFullRotations = math.floor(worstCaseDistanceTraveled / 360)
  targetDistance = targetDistance + worstCaseFullRotations * 360
  local originalTargetDistance = targetDistance
  local bestVelocity = VELOCITY
  local bestVelocityDelta = 999999999
  local timeDelta = 0
  for t = 0, 10 do
    for i = 1, 10 do
      local velocity = targetDistance / (time + timeDelta)
      for j = 1, 10 do
        local at = math.abs((velocity - self.currentVelocity) / ACCELERATION)
        local d1 = self.currentVelocity * at + 0.5 * ACCELERATION * at * at
        local d2 = velocity * (time + timeDelta - at)
        local deltaDist = targetDistance - (d1 + d2)
        debugPrint("DD" .. j .. ": " .. deltaDist .. " - " .. targetDistance .. " - " .. velocity)
        if 1 > math.abs(deltaDist) then
          break
        end
        velocity = velocity + velocity * (deltaDist / targetDistance)
      end
      debugPrint("V" .. i .. ": " .. velocity)
      local targetVelocityDelta = math.abs(velocity - VELOCITY)
      if bestVelocityDelta < targetVelocityDelta then
        break
      end
      bestVelocity = velocity
      bestVelocityDelta = targetVelocityDelta
      targetDistance = targetDistance + 360
    end
    if bestVelocityDelta < VELOCITY * VELOCITY_WIGGLE_ROOM then
      break
    end
    if t < 10 then
      if bestVelocity < VELOCITY then
        timeDelta = timeDelta - MAX_TIME_DELTA * 0.1
      else
        timeDelta = timeDelta + MAX_TIME_DELTA * 0.1
      end
      debugPrint("Trying New Time Delta: " .. timeDelta)
      targetDistance = originalTargetDistance
      bestVelocity = VELOCITY
      bestVelocityDelta = 999999999
    end
  end
  self.targetVelocity = bestVelocity
  debugPrint("--------------------------------------------------------------- Velocity: " .. self.targetVelocity)
  debugPrint("--------------------------------------------------------------- timeDelta: " .. timeDelta)
  return time + timeDelta
end
function HypeGameWheel:setDisc(discSpritePath)
  self.Wheel.Base("spriteName"):SetString(discSpritePath)
end
function HypeGameWheel:setDiscLabel(discSpritePath)
  self.Wheel.Label("spriteName"):SetString(discSpritePath)
end
function HypeGameWheel:setDiscNumberValues(values)
  local scale = self("scale"):GetFloat()
  for i = 1, #self.Wheel.Numbers do
    local text = self.Wheel.Numbers[i]:E("Number"):C("Text")
    local rotation = text("rotation"):GetFloat()
    text("rotation"):SetFloat(0)
    text("text"):SetString(values[i])
    text("size"):SetFloat(0.8 * scale)
    text:setSize(Vector2(text:absW(), text:absH()))
    text("rotation"):SetFloat(rotation)
  end
end
function HypeGameWheel:setRotation(rotationInDeg)
  self.currentRotationDeg = rotationInDeg
  self.Wheel.Base("rotation"):SetFloat(self.currentRotationDeg)
  self.Wheel.Label("rotation"):SetFloat(self.currentRotationDeg)
  local textRadius = 120 * self("scale"):GetFloat()
  local degreeOffset = rotationInDeg - NUMBERS_ANGLE_OFFSET
  for i = 1, #self.Wheel.Numbers do
    degreeOffset = degreeOffset + 45
    local radians = math.rad(degreeOffset)
    self.Wheel.Numbers[i]:E("Number"):C("Text")("rotation"):SetFloat(radians)
    self.Wheel.Numbers[i]("xOffset"):SetFloat(textRadius * math.cos(radians))
    self.Wheel.Numbers[i]("yOffset"):SetFloat(textRadius * math.sin(radians))
  end
end
function HypeGameWheel:setWheelScale(scale)
  self("scale"):SetFloat(scale)
  local scaleVector = Vector2(scale, scale)
  self.Wheel.Base:setScale(scaleVector)
  self.Wheel.Label:setScale(scaleVector)
  for i = 1, #self.Wheel.Numbers do
    local text = self.Wheel.Numbers[i]:E("Number"):C("Text")
    text("size"):SetFloat(0.8 * scale)
    text:setSize(Vector2(text:absW(), text:absH()))
  end
end
return HypeGameWheel
