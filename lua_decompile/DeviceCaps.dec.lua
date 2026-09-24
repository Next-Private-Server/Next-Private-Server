local DeviceCaps = {}
function DeviceCaps.supportEffek()
  local blacklistedRenderers = {
    "Adreno (TM) 306"
  }
  for i = 1, #blacklistedRenderers do
    if game.glRenderer() == blacklistedRenderers[i] then
      return false
    end
  end
  return true
end
return DeviceCaps
