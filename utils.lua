local M = {}
local notify = require("notify").notify
local lastIndex;

function M.tableContains(table, elem)
  for i, v in ipairs(table) do
    if v.Key == elem.Key then
      lastIndex = i
      return true
    end
  end
  return false
end

function M.dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. M.dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end


return M
