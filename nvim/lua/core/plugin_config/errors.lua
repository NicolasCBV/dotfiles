local opts = { silent = true }
M.keys.add({
  {
    shortcut = '<Esc>',
    cmd = ':cclose<CR>',
    opts = opts,
    desc = 'Close errors window'
  },
  {
    shortcut = '<C-e>',
    cmd = ':lua vim.diagnostic.setqflist()<CR>',
    opts = opts,
    desc = 'Open errors'
  }
})

local fn = vim.fn

local signMap = {
  E = "  ",
  W = "  ",
  I = "  ",
  H = "H  ",
  N = "󰅍  ",
}

function _G.qftf(info)
  local items
  local ret = {}
  local cols = vim.o.columns

  if info.quickfix == 1 then
    items = fn.getqflist({id = info.id, items = 0}).items
  else
    items = fn.getloclist(info.winid, {id = info.id, items = 0}).items
    cols = vim.api.nvim_win_get_width(0)
  end

  local max_len = 0
  local fnames = {}

  for i = info.start_idx, info.end_idx do
    local e = items[i]
    local fname = ''

    if e.valid == 1 then

      if e.bufnr > 0 then
        fname = fn.bufname(e.bufnr)

        if fname == '' then
          fname = '[Empty name]'
        else
          fname = fname:gsub('^' .. vim.env.HOME, '~')
        end

        if #fname > max_len then
          max_len = #fname
        end

        fnames[i] = fname

      end

    end

  end

  local limit = math.min(math.max(20, math.floor(cols * 0.25)), max_len)

  local fnameFmt1, fnameFmt2 = '%-' .. limit .. 's', '…%.' .. (limit - 1) .. 's'
  local validFmt = '%s │%4d │%s%s'

  for i = info.start_idx, info.end_idx do
    local e = items[i]
    local str
    local fname = fnames[i]

    if fname then
      if #fname <= limit then
        fname = fnameFmt1:format(fname)
      else
        fname = fnameFmt2:format(fname:sub(1 - limit))
      end
      local lnum = e.lnum > 9999 and -1 or e.lnum
      local qtype = e.type == '' and '' or ' ' .. signMap[e.type:sub(1, 1):upper()]
      str = validFmt:format(fname, lnum, qtype, e.text)
    else
      str = e.text
    end
    table.insert(ret, str)
  end
  return ret
end

vim.o.qftf = '{info -> v:lua._G.qftf(info)}'
