local ElementTools = {}
local findInList = function(haystack, needle)
  for i, v in ipairs(haystack) do
    if swig_equals(v, needle) then
      return i
    end
  end
  return nil
end
function ElementTools.FindAllComponents(element, predicate, registerOnDestroy, onDestroy)
  local components = {}
  local elementsToCheck = {element}
  while #elementsToCheck ~= 0 do
    local checkElement = elementsToCheck[#elementsToCheck]
    table.remove(elementsToCheck, #elementsToCheck)
    local childElements = checkElement:elements()
    local numChildElements = childElements:size()
    for i = 0, numChildElements - 1 do
      elementsToCheck[#elementsToCheck + 1] = childElements[i]
    end
    local childComponents = checkElement:components()
    local numChildComponents = childComponents:size()
    for i = 0, numChildComponents - 1 do
      local component = childComponents[i]:Unslice()
      if predicate == nil or predicate(component) then
        components[#components + 1] = component
        if registerOnDestroy then
          do
            local oldOnDestroy = component.onDestroy
            function component.onDestroy(component, element)
              local index = findInList(components, component)
              if index ~= nil then
                if onDestroy ~= nil then
                  onDestroy(component, element)
                end
                table.remove(components, index)
              end
              if oldOnDestroy then
                oldOnDestroy(component, element)
              end
            end
          end
        end
      end
    end
  end
  return components
end
return ElementTools
