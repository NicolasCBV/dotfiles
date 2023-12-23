---@diagnostic disable: lowercase-global
-- Collected and adapted from: 
-- https://github.com/VonHeikemen/fine-cmdline.nvim/blob/main/lua/fine-cmdline/init.lua
-- Original author: VonHeikemen

local status_ok, nui = pcall(require, 'nui.input')
if not status_ok then
  M.deps.nui = { package = nil, name = 'nui.input' }
end

M.utils.command_bar = { fn = {} }
local fn = {}

local state = {
  query = '',
  history = nil,
  idx_hist = 0,
  hooks = {
    before_mount = function(_) end,
    after_mount = function(_) end,
    set_keymaps = function(_, _) end
  },
  cmdline = {
    enable_keymaps = true,
    smart_history = true,
    prompt = '   '
  },
  user_opts = {},
  prompt_length = 0,
  prompt_content = ''
}

M.utils.command_bar.input = nil

state.prompt_content = state.cmdline.prompt
state.prompt_length = state.cmdline.prompt:len()

local configs = {
  popup = {
    position = {
      row = '10%',
      col = '50%'
    },
    size = {
      width = '60%'
    },
    border = {
      style = 'rounded'
    },
    win_options = {
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    }
  },
  input = {
    prompt = state.cmdline.prompt,
    default_value = '',
    on_change = function() fn.on_change() end,
    on_close = function() end,
    on_submit = function(value)
      local ok, err = pcall(fn.submit, value)
      if not ok then
        pcall(vim.notify, err, vim.log.levels.ERROR)
      end
    end
  }
}

M.utils.command_bar.open = function()
  M.utils.command_bar.input = nui(configs.popup, configs.input)
  M.utils.command_bar.input:mount()

  vim.bo.omnifunc = 'v:lua.autocomp_omnifunc'

  if state.cmdline.enable_keymaps then
    fn.keymaps()
  end

  fn.map('<BS>', function() fn.prompt_backspace(state.prompt_length) end)

  state.hooks.set_keymaps(fn.map, fn.feedkeys)
  state.hooks.after_mount(M.utils.command_bar.input)
end

fn.submit = function(value)
  fn.reset_history()
  vim.fn.histadd('cmd', value)

  local ok, err = pcall(vim.cmd, value)
  if not ok then
    local idx = err:find(':E')
    if type(idx) ~= 'number' then
      return
    end
    local msg = err:sub(idx + 1):gsub('\t', '   ')
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

fn.on_change = function ()
  local prev_hist_idx = 0
  return function (value)
    if prev_hist_idx == state.idx_hist then
      state.query = value
      return
    end

    if value == '' then
      return
    end

    prev_hist_idx = state.idx_hist
  end
end

fn.keymaps = function()
  fn.map('<Esc>', M.utils.command_bar.fn.close)
  fn.map('<C-c>', M.utils.command_bar.fn.close)

  fn.nmap('<Esc>', M.utils.command_bar.fn.close)
  fn.nmap('<C-c>', M.utils.command_bar.fn.close)

  fn.map('<Tab>', M.utils.command_bar.fn.complete_or_next_item)
  fn.map('<S-Tab>', M.utils.command_bar.fn.stop_complete_or_previous_item)

  if state.cmdline.smart_history then
    fn.map('<Up>', M.utils.command_bar.fn.search_history)
    fn.map('<Down>', M.utils.command_bar.fn.down_history)
  else
    fn.map('<Up>', M.utils.command_bar.fn.up_history)
    fn.map('<Down>', M.utils.command_bar.fn.down_history)
  end
end

M.utils.command_bar.fn.close = function ()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-e>')
  end
    fn.feedkeys('<Space>')
    vim.defer_fn(function ()
      local ok = pcall(
        M.utils.command_bar.input.input_props.on_close
      )

      if not ok then
        pcall(
          vim.api.nvim_win_close,
          M.utils.command_bar.input.winid,
          true
        )
        pcall(
          vim.api.nvim_buf_delete,
          M.utils.command_bar.input.bufnr,
          { force = true }
        )
      end
    end, 3)
end

M.utils.command_bar.fn.search_history = function ()
  if vim.fn.pumvisible() == 1 then return end

  local prompt = state.prompt_length
  local line = vim.fn.getline('.')
  local user_input = line:sub(prompt + 1, vim.fn.col('.'))

  if line:len() == prompt then
    M.utils.command_bar.fn.up_history()
    return
  end

  fn.cmd_history()
  local idx = state.idx_hist == 0 and 1 or (state.idx_hist + 1)

  while state.history[idx] do
    local cmd = state.history[idx]

    if vim.startswith(cmd, state.query) then
      state.idx_hist = idx
      fn.replace_line(cmd)
      return
    end

    state.idx_hist = 1
    if user_input ~= state.query then
      fn.replace_line(state.query)
    end
  end
end

M.utils.command_bar.fn.down_search_history = function ()
  if vim.fn.pumvisible() == 1 then return end

  local prompt = state.prompt_length
  local line = vim.fn.getline('.')
  local user_input = line:sub(prompt + 1, vim.fn.col('.'))

  if line:len() == prompt then
    M.utils.command_bar.fn.down_history()
    return
  end

  fn.cmd_history()
  local idx = state.idx_hist == 0 and #state.history or (state.idx_hist - 1)

  while state.history[idx] do
    local cmd = state.history[idx]

    if vim.startswith(cmd, state.query) then
      state.idx_hist = idx
      fn.replace_line(cmd)
      return
    end

    idx = idx - 1
  end

  state.idx_hist = #state.history
  if user_input ~= state.query then
    fn.replace_line(state.query)
  end
end


M.utils.command_bar.fn.up_history = function()
  if vim.fn.pumvisible() == 1 then return end

  fn.cmd_history()
  state.idx_hist = state.idx_hist + 1
  local cmd = state.history[state.idx_hist]

  if not cmd then
    state.idx_hist = 0
    return
  end

  fn.replace_line(cmd)
end

M.utils.command_bar.fn.down_history = function()
  if vim.fn.pumvisible() == 1 then return end

  fn.cmd_history()
  state.idx_hist = state.idx_hist - 1
  local cmd = state.history[state.idx_hist]

  if not cmd then
    state.idx_hist = 0
    return
  end

  fn.replace_line(cmd)
end

M.utils.command_bar.fn.complete_or_next_item = function()
  state.uses_completion = true
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-n>')
  else
    fn.feedkeys('<C-x><C-o>')
  end
end

fn.merge = function(default, override)
  return vim.tbl_deep_extend(
    'force',
    {},
    default,
    override or {}
  )
end

M.utils.command_bar.fn.stop_complete_or_previous_item = function()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-p>')
  else
    fn.feedkeys('<C-x><C-z>')
  end
end

M.utils.command_bar.fn.next_item = function()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-n>')
  end
end

M.utils.command_bar.fn.previous_item = function()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-p>')
  end
end

M.utils.command_bar.omnifunc = function(start, base)
  local prompt_length = state.prompt_length
  local line = vim.fn.getline('.')
  local input = line:sub(prompt_length + 1)

  if start == 1 then
    local split = vim.split(input, ' ')
    local last_word = split[#split]
    local len = #line - #last_word

    for i=#split - 1, 1, -1 do
      local word = split[i]
      if vim.endswith(word, [[\\]]) then
        break
      elseif vim.endswith(word, [[\]]) then
        len = len - #word - 1
      else
        break
      end
    end

    return len
  end

  return vim.api.nvim_buf_call(vim.fn.bufnr('#'), function()
    return vim.fn.getcompletion(input .. base, 'cmdline')
  end)
end

fn.replace_line = function(cmd)
  vim.api.nvim_buf_set_lines(
    M.utils.command_bar.input.bufnr,
    vim.fn.line('.') - 1,
    vim.fn.line('.'),
    true,
    {state.prompt_content ..  cmd}
  )

  vim.api.nvim_win_set_cursor(
    M.utils.command_bar.input.winid,
    {vim.fn.line('$'), vim.fn.getline('.'):len()}
  )
end

fn.cmd_history = function()
  if state.history then return end

  local history_string = vim.fn.execute('history cmd')
  local history_list = vim.split(history_string, '\n')

  local results = {}
  for i = #history_list, 3, -1 do
    local item = history_list[i]
    local _, finish = string.find(item, '%d+ +')
    table.insert(results, string.sub(item, finish + 1))
  end

  state.history = results
end

fn.reset_history = function()
  state.idx_hist = 0
  state.history = nil
  state.query = ''
end

fn.map = function(lhs, rhs)
    if type(rhs) == 'string' then
      vim.api.nvim_buf_set_keymap(M.utils.command_bar.input.bufnr, 'i', lhs, rhs, {noremap = true})
    else
      M.utils.command_bar.input:map('i', lhs, rhs, {noremap = true}, true)
    end
  end

fn.nmap = function(lhs, rhs)
  M.utils.command_bar.input:map('n', lhs, rhs, {noremap = true}, true)
end

fn.feedkeys = function(keys)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, true, true),
    'n',
    true
  )
end

fn.prompt_backspace = function(prompt)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  local col = cursor[2]

  if col ~= prompt then
    local completion = vim.fn.pumvisible() == 1 and state.uses_completion
    if completion then fn.feedkeys('<C-x><C-z>') end

    vim.api.nvim_buf_set_text(0, line - 1, col - 1, line - 1, col, {''})
    vim.api.nvim_win_set_cursor(0, {line, col - 1})

    if completion then fn.feedkeys('<C-x><C-o>') end
  end
end

autocomp_omnifunc = M.utils.command_bar.omnifunc

M.deps.nui = { package = nui, name = 'nui.input' }
