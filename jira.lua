local notify = require("notify").notify
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local ticket = require("ticket")

local M = {}
M.cachedSearch = nil

--The ticket has this structure
-- type Ticket struct {
--     TicketNumber string
--     Title string
--     Reporter string
--     Assignee string
--     Priority string
--     Status string
--     Description string
--     Comments []string
-- }
function M.GoApi()
  if M.cachedSearch ~= nil then
    return M.cachedSearch
  end
  -- local ticket = io.popen("./jira-client --ticket 'TBB-4965'"):read("*all")
  local data = io.popen("./jira-client --query 'project=TBB and status=Screening'"):read("*all")
  -- local ticket = io.popen("./jira-client --query 'project=TBB'"):read("*all")
  M.cachedSearch = vim.json.decode(data)
  return vim.fn.json_decode(data)
end

function SetToTelescope()
  local opts = {}
  local objs = {}

  local data = M.GoApi()
  for _, entry in ipairs(data) do
    table.insert(objs, entry)
  end
  opts.bufnr = vim.api.nvim_get_current_buf()
  opts.winnr = vim.api.nvim_get_current_win()
  pickers
    .new(opts, {
      prompt_title = "Test",
      finder = finders.new_table {
        results = objs,
        entry_maker = function(entry)
          return make_entry.set_default_entry_mt({
            value = entry.Key,
            text = entry,
            ordinal = entry.Title,
            display = entry.Key .." - " .. entry.Priority .. " - " .. entry.Title,
          }, opts)
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(function(n)
          local line = action_state.get_selected_entry()
          notify(type(line.value))
          actions.close(n)
          ticket.openTicket(line.value)
        end)
        map("i", "<CR>", actions.select_default)

        return true
      end
    })
    :find()
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

-- M.GoApi()
SetToTelescope()

return M
