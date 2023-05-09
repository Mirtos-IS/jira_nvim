local notify = require("notify").notify
local utils = require("utils")
local buf
local cachedTickets = {}
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
  if cachedTickets[key] ~= nil then
    M.open_win()
    M.setLinesToWin(cachedTickets[key])
  end
  local ticket = M.goApi(key)
  M.open_win()
  local parsedTicket = M.toArrayString(ticket)
  M.setLinesToWin(parsedTicket)
end

function M.toArrayString(ticket)
  local array = {}
  table.insert(array, "---Ticket Number------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, ticket.TicketNumber)
  table.insert(array, "---Title--------------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, ticket.Title)
  table.insert(array, "---Reporter-----------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, ticket.Reporter)
  table.insert(array, "---Assignee-----------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, ticket.Assignee)
  table.insert(array, "---Priority-----------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, ticket.Priority)
  table.insert(array, "---Status-------------------------------------------------------------------------------------------------------------------------------------------------------------------")
  table.insert(array, ticket.Status)
  table.insert(array, "---Description--------------------------------------------------------------------------------------------------------------------------------------------------------------")

  local desc = string.gmatch(ticket.Description, "[^\n]+")
  for i in desc do
    table.insert(array, i)
  end

  table.insert(array, "---Comments-----------------------------------------------------------------------------------------------------------------------------------------------------------------")

  if type(ticket.Comments) ~= "userdata" then
    for i in ipairs(ticket.Comments) do
      local comment = string.gsub(ticket.Comments[i], "\n", "")
      table.insert(array, comment)

      table.insert(array, "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------")

    end
  end
  cachedTickets[ticket.TicketNumber] = array

  return array
end
function M.goApi(key)
  local ticket = io.popen("jira-client --ticket " .. key):read("*all")
  return vim.json.decode(ticket)
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

function M.setLinesToWin(ticket)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  vim.api.nvim_buf_set_lines(buf, 0, -1,false, ticket)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
end

return M
