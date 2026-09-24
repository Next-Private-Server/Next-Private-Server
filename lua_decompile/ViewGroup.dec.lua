local ViewGroup = {}
local ViewGroupProto = {
  add = function(view, target)
    table.insert(view, target)
  end,
  show = function(view)
    for _, v in ipairs(view) do
      v("visible"):SetInt(1)
      v("enabled"):SetInt(1)
      v:DoStoredScript("setVisible")
    end
  end,
  hide = function(view)
    for _, v in ipairs(view) do
      v("visible"):SetInt(0)
      v("enabled"):SetInt(0)
      v:DoStoredScript("setInvisible")
    end
  end,
  setAlpha = function(view, alpha)
    for _, v in ipairs(view) do
      v("alpha"):SetFloat(alpha)
      v:DoStoredScript("updateAlpha")
    end
  end
}
function ViewGroup.new()
  local viewGroup = {}
  setmetatable(viewGroup, {__index = ViewGroupProto})
  return viewGroup
end
return ViewGroup
