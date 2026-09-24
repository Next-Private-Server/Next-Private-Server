local VersionCompare = function(v1, v2)
  local split = function(str, sep)
    local parts = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
      table.insert(parts, part)
    end
    return parts
  end
  print("Comparing versions:", v1, v2)
  local parts1 = split(v1, ".")
  local parts2 = split(v2, ".")
  local maxLength = math.max(#parts1, #parts2)
  for i = 1, maxLength do
    local num1 = tonumber(parts1[i]) or 0
    local num2 = tonumber(parts2[i]) or 0
    if num1 < num2 then
      return -1
    elseif num1 > num2 then
      return 1
    end
  end
  return 0
end
return VersionCompare
