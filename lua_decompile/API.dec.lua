local __genOrderedIndex = function(t)
  local orderedIndex = {}
  for key in pairs(t) do
    table.insert(orderedIndex, key)
  end
  table.sort(orderedIndex)
  return orderedIndex
end
local function orderedNext(t, state)
  local key
  if state == nil then
    t.__orderedIndex = __genOrderedIndex(t)
    key = t.__orderedIndex[1]
  else
    for i = 1, #t.__orderedIndex do
      if t.__orderedIndex[i] == state then
        key = t.__orderedIndex[i + 1]
      end
    end
  end
  if key then
    return key, t[key]
  end
  t.__orderedIndex = nil
  return
end
local function orderedPairs(t)
  return orderedNext, t, nil
end
local function printAPI(tableName, table, prefix)
  prefix = prefix or ""
  local functions
  local m = getmetatable(table)
  if m then
    local mi = m[".instance"]
    if mi then
      if mi[".type"] then
        if mi[".bases"] and mi[".bases"][1] then
          print(prefix .. "---@class " .. mi[".type"] .. " : " .. mi[".bases"][1][".type"])
        else
          print(prefix .. "---@class " .. mi[".type"])
        end
      end
      functions = mi[".fn"]
    end
  end
  print(prefix .. tableName .. " = {")
  for k, v in orderedPairs(table) do
    local t = type(v)
    if t ~= "table" and t ~= "function" then
      if t == "string" then
        print(prefix .. "\t" .. k .. "=\"" .. v .. "\",")
      else
        print(prefix .. "\t" .. k .. "=" .. v .. ",")
      end
    end
  end
  print("")
  for k, v in orderedPairs(table) do
    local t = type(v)
    if t == "function" then
      print(prefix .. "\t" .. k .. " = function() end,")
    end
  end
  print("")
  for k, v in orderedPairs(table) do
    local t = type(v)
    if t == "table" then
      printAPI(k, v, prefix .. "\t")
    end
  end
  if functions then
    for k, v in orderedPairs(functions) do
      if type(v) == "function" and k:find("__") ~= 1 then
        print(prefix .. "\t" .. k .. " = function() end,")
      end
    end
  end
  print(prefix .. "},\n")
end
print("swig_equals = function() end")
print("swig_type = function() end")
print("-----------------------------------------------------------------------------")
printAPI("lua_sys", _G.lua_sys)
print("-----------------------------------------------------------------------------")
printAPI("game", _G.game)
print("-----------------------------------------------------------------------------")
