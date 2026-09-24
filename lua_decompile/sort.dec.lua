local sort = {}
sort.max_chunk_size = 32
function sort._insertion_sort_impl(array, first, last, less)
  for i = first + 1, last do
    local k = first
    local v = array[i]
    for j = i, first + 1, -1 do
      if less(v, array[j - 1]) then
        array[j] = array[j - 1]
      else
        k = j
        break
      end
    end
    array[k] = v
  end
end
function sort._merge(array, workspace, low, middle, high, less)
  local i, j, k
  i = 1
  for w = low, middle do
    workspace[i] = array[w]
    i = i + 1
  end
  i = 1
  j = middle + 1
  k = low
  while true do
    if j <= k or high < j then
      break
    end
    if less(array[j], workspace[i]) then
      array[k] = array[j]
      j = j + 1
    else
      array[k] = workspace[i]
      i = i + 1
    end
    k = k + 1
  end
  for w = k, j - 1 do
    array[w] = workspace[i]
    i = i + 1
  end
end
function sort._merge_sort_impl(array, workspace, low, high, less)
  if high - low <= sort.max_chunk_size then
    sort._insertion_sort_impl(array, low, high, less)
  else
    local middle = math.floor((low + high) / 2)
    sort._merge_sort_impl(array, workspace, low, middle, less)
    sort._merge_sort_impl(array, workspace, middle + 1, high, less)
    sort._merge(array, workspace, low, middle, high, less)
  end
end
local _sorted_types = {string = true, number = true}
local function default_less(a, b)
  if not _sorted_types[type(a)] or not _sorted_types[type(b)] then
    return false
  end
  return a < b
end
function sort._sort_setup(array, less)
  less = less or default_less
  local n = #array
  local trivial = n <= 1
  if not trivial and less(array[1], array[1]) then
    error("invalid order function for sorting; less(v, v) should not be true for any v.")
  end
  return trivial, n, less
end
function sort.stable_sort(array, less)
  local trivial, n
  trivial, n, less = sort._sort_setup(array, less)
  if not trivial then
    local workspace = {}
    local middle = math.ceil(n / 2)
    workspace[middle] = array[1]
    sort._merge_sort_impl(array, workspace, 1, n, less)
  end
  return array
end
function sort.insertion_sort(array, less)
  local trivial, n
  trivial, n, less = sort._sort_setup(array, less)
  if not trivial then
    sort._insertion_sort_impl(array, 1, n, less)
  end
  return array
end
sort.unstable_sort = table.sort
return sort
