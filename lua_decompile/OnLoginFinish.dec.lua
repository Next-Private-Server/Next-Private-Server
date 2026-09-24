print(">>> On Login Finished")
clearCachedLua()
math.randomseed(os.clock() * 10000)
local shader = game.getShader("ShaderCostumeABE3Rare")
if shader ~= nil then
  shader:getUniform("u_isOrange"):setInt(math.random() > 0.5 and 1 or 0)
end
SESSION_HAS_TRIGGERED_QUEST_PULSE = false
print("<<< On Login Finished")
local _breedingMenuScaleX
function BreedingMenuScaleX()
  if not _breedingMenuScaleX then
    _breedingMenuScaleX = lua_sys.screenWidth() / 680
    if _breedingMenuScaleX * 420 > lua_sys.screenHeight() then
      _breedingMenuScaleX = lua_sys.screenHeight() / 420
    end
  end
  return _breedingMenuScaleX
end
function BreedingMenuScaleY()
  return BreedingMenuScaleX()
end
