local notify = require("notify").notify
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local ticket = require("ticket")

local utils = require("utils")
local flatten = vim.tbl_flatten
local jira_client = "/home/mirtos/GitRepos/telescope-jira/jira-client"

local objs = {}
local current_picker

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

local M = {}
M.entry_maker = function(entry)
          return make_entry.set_default_entry_mt({
            value = entry.Key,
            text = entry,
            ordinal = entry.Key .." - " .. entry.Status .. " - " .. entry.Priority .. " - " .. entry.Title,
            display = entry.Key .." - " .. entry.Status .. " - " .. entry.Priority .. " - " .. entry.Title,
          }, {})
      end

function M.GoApi()
  local command = "jira-client --query 'project=TBB and status=Screening'"
  vim.fn.jobstart(command, {
    stdout_buffered = false,
    on_stdout = function (_, data)
      if not data then
        return
      end
      for i, v in ipairs(data) do
        if v == "" then
          table.remove(data, i)
        end
      end
      if next(data) == nil then
        return
      end
      local live_data = vim.fn.json_decode(data)
      for _, v in ipairs(live_data) do
        if utils.tableContains(objs, v) then
          objs[utils.lastIndex] = v
        else
          table.insert(objs, v)
        end
      end
    end,
    on_exit = function ()
      current_picker:refresh(
        finders.new_table{
          results = objs,
          entry_maker = M.entry_maker
  }, {reset_prompt = false})
    end
  })
end


function SetToTelescope()
  M.GoApi()
  pickers
    .new({}, {
      prompt_title = "Test",
      finder = finders.new_table{
        results = objs,
        entry_maker = M.entry_maker
      },
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function(n)
          local line = action_state.get_selected_entry()
          actions.close(n)
          ticket.openTicket(line.value)
        end)
        current_picker = action_state.get_current_picker(prompt_bufnr)
        map("i", "<CR>", actions.select_default)

        return true
      end
    })
    :find()
end
-- M.GoApi()
SetToTelescope()

vim.keymap.set('n', '<localleader>ts', ':lua SetToTelescope()<CR>', {silent=true})
return M
