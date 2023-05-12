local notify = require("notify").notify
local utils = require("utils")
local buf
local cachedTickets = {}
local ticket
local M = {}

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
function M.openTicket(key)
  -- notify(tostring(cachedTickets[key] ~= nil))
  M.open_win()
  if cachedTickets[key] ~= nil then
    M.setLinesToWin(cachedTickets[key])
  end
  M.goApi(key)
  -- M.open_win()
  -- local parsedTicket = M.toArrayString(ticket)
  -- M.setLinesToWin(parsedTicket)
end

function M.toArrayString(_ticket)
  local array = {}
  table.insert(array, "---Ticket Number------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, _ticket.TicketNumber)
  table.insert(array, "---Title--------------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, _ticket.Title)
  table.insert(array, "---Reporter-----------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, _ticket.Reporter)
  table.insert(array, "---Assignee-----------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, _ticket.Assignee)
  table.insert(array, "---Priority-----------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, _ticket.Priority)
  table.insert(array, "---Status-------------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, _ticket.Status)
  table.insert(array, "---Description--------------------------------------------------------------------------------------------------------------------------------------------------------------")

  local desc = string.gmatch(_ticket.Description, "[^\n]+")
  for i in desc do
    table.insert(array, i)
  end

  table.insert(array, "---Comments-----------------------------------------------------------------------------------------------------------------------------------------------------------------")

  if type(_ticket.Comments) ~= "userdata" then
    for i in ipairs(_ticket.Comments) do
      local comment = string.gsub(_ticket.Comments[i], "\n", "")
      table.insert(array, comment)

      table.insert(array, "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------")

    end
  end
  cachedTickets[_ticket.TicketNumber] = array

  return array
end
function M.goApi(key)
  local command = "jira-client --ticket " .. key
  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function (_, data)
      if not data or next(data) == nil then
        return
      end

      local live_data = vim.fn.json_decode(data)
      if live_data.TicketNumber ~= nil then
        ticket = live_data
        cachedTickets[ticket.TicketNumber] = live_data
      end
    end,
    on_exit = function ()
      local parsedTicket = M.toArrayString(ticket)
      M.setLinesToWin(parsedTicket)
    end
  })
end

function M.open_win(win_h, win_w)
  buf = vim.api.nvim_create_buf(false, false)

  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  local ui = vim.api.nvim_list_uis()[1]
  local height = ui.height
  local width = ui.width

  local win_height = win_h or math.ceil(height * 0.6 - 3)
  local win_width = win_w or math.ceil(width * 0.6)

  local row = math.ceil((height/2 - win_height/2))
  local col = math.ceil((width/2 - win_width/2))

  local opts = {
    relative = "editor",
    style = "minimal",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    focusable = false,
    border = "rounded",
  }
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, "winhighlight", 'Normal:Normal,FloatBorder:FloatBorder')
  vim.api.nvim_buf_set_option(buf, "filetype", "lua")
  vim.keymap.set('n', '<ESC>', '<cmd>q!<CR>', {silent=true, buffer=buf})
end

function M.setLinesToWin(_ticket)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1,true, _ticket)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
end

---Source: https://stackoverflow.com/a/18864453/9714875
function OpenOnBrowser()
  local url = "https://turnoverbnb.atlassian.net/browse/" .. ticket.TicketNumber
  io.popen("xdg-open " .. url):close()
end

return M
