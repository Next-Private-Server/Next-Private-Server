local NumberCounter = {}
NumberCounter.MAX_TIME = 2
NumberCounter.DEFAULT_INCREMENT_TIME = 0.05
function NumberCounter:new(currentNum)
  currentNum = currentNum or 0
  local instance = {
    timeToComplete = 0,
    timeSince = 0,
    curNum = currentNum,
    finalNum = currentNum,
    delta = 0,
    startNum = currentNum
  }
  setmetatable(instance, self)
  self.__index = self
  return instance
end
function NumberCounter:setNumber(num)
  self.startNum = self.curNum
  self.finalNum = num
  self.timeSince = 0
  self.delta = self.finalNum - self.curNum
  local time = math.abs(self.delta) * self.DEFAULT_INCREMENT_TIME
  self.timeToComplete = time < self.MAX_TIME and time or self.MAX_TIME
end
function NumberCounter:tick(time)
  if self.curNum ~= self.finalNum then
    self.timeSince = self.timeSince + time
    if self.timeSince > self.timeToComplete then
      self.timeSince = self.timeToComplete
    end
    self.curNum = self.startNum + math.floor(self.delta * (self.timeSince / self.timeToComplete))
    if self.delta > 0 then
      if self.curNum > self.finalNum then
        self.curNum = self.finalNum
      end
    elseif self.curNum < self.finalNum then
      self.curNum = self.finalNum
    end
    return true
  end
  return false
end
return NumberCounter
